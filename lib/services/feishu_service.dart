import 'dart:convert';
import 'package:http/http.dart' as http;

/// 飞书服务
/// 负责与飞书开放平台 API 交互
class FeishuService {
  // 飞书开放平台 API 地址
  static const String baseUrl = 'https://open.feishu.cn/open-apis';

  // 需要配置的 App ID 和 Secret（用户需要填入）
  String? _appId;
  String? _appSecret;
  String? _tenantAccessToken;

  // 重试配置
  static const int maxRetries = 3;
  static const Duration baseRetryDelay = Duration(seconds: 1);

  // Singleton
  static final FeishuService _instance = FeishuService._internal();
  factory FeishuService() => _instance;
  FeishuService._internal();

  /// 是否已配置
  bool get isConfigured => _appId != null && _appSecret != null;

  /// 配置飞书应用
  void configure({required String appId, required String appSecret}) {
    _appId = appId;
    _appSecret = appSecret;
  }

  /// 带重试的 HTTP 请求
  /// [requestFn] 请求函数
  /// [retries] 重试次数，默认 3
  /// [delay] 基础延迟时间，默认 1 秒（指数退避）
  Future<http.Response?> _requestWithRetry(
    Future<http.Response> Function() requestFn, {
    int retries = maxRetries,
    Duration delay = baseRetryDelay,
  }) async {
    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        final response = await requestFn().timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception('请求超时'),
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }

        // 4xx 客户端错误，不重试
        if (response.statusCode >= 400 && response.statusCode < 500) {
          return response;
        }

        // 5xx 服务器错误，重试
        if (response.statusCode >= 500 && response.statusCode < 600) {
          if (attempt < retries) {
            // 指数退避：delay * 2^attempt
            await Future.delayed(delay * (1 << attempt));
            continue;
          }
        }

        return response;
      } catch (e) {
        // 网络错误或超时，重试
        if (attempt < retries) {
          await Future.delayed(delay * (1 << attempt));
        } else {
          // 达到最大重试次数
          return null;
        }
      }
    }
    return null;
  }

  /// 获取 Tenant Access Token
  Future<String?> getTenantAccessToken() async {
    if (!isConfigured) {
      return null;
    }

    final result = await getTenantAccessTokenWithError();
    return result?.$1;
  }

  /// 获取 Tenant Access Token（带详细错误信息）
  /// 返回 (token, errorMsg)，null 表示网络完全不可达，token=null 表示 API 返回错误
  Future<(String?, String?)?> getTenantAccessTokenWithError() async {
    if (!isConfigured) {
      return (null, 'App ID 或 App Secret 为空');
    }

    try {
      final response = await _requestWithRetry(() async {
        return http.post(
          Uri.parse('$baseUrl/auth/v3/tenant_access_token/internal'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'app_id': _appId,
            'app_secret': _appSecret,
          }),
        );
      });

      if (response == null) {
        // 网络错误（超时或无法连接）
        return (null, '网络连接失败，请检查网络或服务器地址');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final code = data['code'] as int?;

      if (code == 0) {
        _tenantAccessToken = data['tenant_access_token'] as String;
        return (_tenantAccessToken, null);
      }

      // API 返回错误，解析错误信息
      final msg = data['msg'] as String? ?? '未知错误';
      if (code == 99991663 || code == 99991664) {
        return (null, 'App ID 或 App Secret 错误');
      }
      if (code == 99991660) {
        return (null, '应用权限不足');
      }
      return (null, msg);
    } catch (e) {
      return (null, '网络异常: $e');
    }
  }

  /// 发送消息给用户
  Future<bool> sendMessage({
    required String receiveId,
    required String msgType,
    required String content,
    required String receiveIdType,
  }) async {
    final token = _tenantAccessToken ?? await getTenantAccessToken();
    if (token == null) {
      return false;
    }

    final response = await _requestWithRetry(() async {
      return http.post(
        Uri.parse('$baseUrl/im/v1/messages?receive_id_type=$receiveIdType'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'receive_id': receiveId,
          'msg_type': msgType,
          'content': content,
        }),
      );
    });

    if (response != null && response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['code'] == 0;
    }
    return false;
  }

  /// 发送文本消息
  Future<bool> sendTextMessage({
    required String receiveId,
    required String text,
    required String receiveIdType,
  }) async {
    return sendMessage(
      receiveId: receiveId,
      msgType: 'text',
      content: jsonEncode({'text': text}),
      receiveIdType: receiveIdType,
    );
  }

  /// 发送富文本消息（post 消息）
  Future<bool> sendPostMessage({
    required String receiveId,
    required List<Map<String, dynamic>> content,
    required String receiveIdType,
  }) async {
    return sendMessage(
      receiveId: receiveId,
      msgType: 'post',
      content: jsonEncode({'zh_cn': {'title': '', 'content': content}}),
      receiveIdType: receiveIdType,
    );
  }

  /// 发送卡片消息
  Future<bool> sendCardMessage({
    required String receiveId,
    required Map<String, dynamic> cardContent,
    required String receiveIdType,
  }) async {
    return sendMessage(
      receiveId: receiveId,
      msgType: 'interactive',
      content: jsonEncode(cardContent),
      receiveIdType: receiveIdType,
    );
  }

  /// 向 code-designer 发送设计任务
  Future<bool> sendDesignTask({
    required String agentOpenId,
    required String projectName,
    required String requirements,
  }) async {
    final message = '''
🎨 设计任务通知

项目：$projectName
需求：$requirements

请开始设计工作。
''';

    return sendTextMessage(
      receiveId: agentOpenId,
      text: message,
      receiveIdType: 'open_id',
    );
  }

  /// 向 code-writer 发送编码任务
  Future<bool> sendCodeTask({
    required String agentOpenId,
    required String projectName,
    required String designSpec,
  }) async {
    final message = '''
💻 编码任务通知

项目：$projectName
设计规格：$designSpec

请开始编码工作。
''';

    return sendTextMessage(
      receiveId: agentOpenId,
      text: message,
      receiveIdType: 'open_id',
    );
  }

  /// 向 code-reviewer 发送审核任务
  Future<bool> sendReviewTask({
    required String agentOpenId,
    required String projectName,
    required String codeLocation,
  }) async {
    final message = '''
🔍 审核任务通知

项目：$projectName
代码位置：$codeLocation

请开始审核工作。
''';

    return sendTextMessage(
      receiveId: agentOpenId,
      text: message,
      receiveIdType: 'open_id',
    );
  }

  /// 向 sakura 汇报任务状态
  Future<bool> reportToSakura({
    required String sakuraOpenId,
    required String projectName,
    required String status,
    required String details,
  }) async {
    final emoji = status == 'success' ? '✅' : '❌';
    final message = '''
$emoji 任务状态汇报

项目：$projectName
状态：$status
详情：$details
时间：${DateTime.now().toString().substring(0, 19)}
''';

    return sendTextMessage(
      receiveId: sakuraOpenId,
      text: message,
      receiveIdType: 'open_id',
    );
  }
}
