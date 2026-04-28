import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

/// OpenClaw 服务
/// 负责与 OpenClaw 网关 WebSocket 连接
class OpenClawService {
  static const String defaultUrl = 'ws://127.0.0.1:18789';
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const int _maxReconnectAttempts = 5;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _isConnected = false;
  bool _isReconnecting = false;
  String? _gatewayUrl;
  String? _authToken;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  // 消息处理
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  // 连接状态
  final _statusController = StreamController<bool>.broadcast();
  Stream<bool> get statusStream => _statusController.stream;

  bool get isConnected => _isConnected;
  String? get gatewayUrl => _gatewayUrl;

  /// 连接到 OpenClaw 网关
  Future<bool> connect([String? url, String? token]) async {
    try {
      _gatewayUrl = url ?? defaultUrl;
      _authToken = token;

      _channel = WebSocketChannel.connect(Uri.parse(_gatewayUrl!));

      final completer = Completer<bool>();

      _subscription = _channel!.stream.listen(
        (data) {
          try {
            final message = jsonDecode(data as String) as Map<String, dynamic>;
            _messageController.add(message);

            // 检查连接确认
            if (message['type'] == 'connected' || message['type'] == 'auth_success' || message['type'] == 'pong') {
              if (!_isConnected) {
                _isConnected = true;
                _reconnectAttempts = 0;
                _statusController.add(true);
                _startPingTimer();
              }
              if (!completer.isCompleted) {
                completer.complete(true);
              }
            }
          } catch (e) {
            // 解析失败，忽略
          }
        },
        onError: (error) {
          _isConnected = false;
          _statusController.add(false);
          _stopPingTimer();
          if (!completer.isCompleted) {
            completer.complete(false);
          }
          _scheduleReconnect();
        },
        onDone: () {
          _isConnected = false;
          _statusController.add(false);
          _stopPingTimer();
          if (!completer.isCompleted) {
            completer.complete(false);
          }
          _scheduleReconnect();
        },
      );

      // 发送连接请求（带认证信息）
      _channel!.sink.add(jsonEncode({
        'type': 'connect',
        'token': _authToken,
      }));

      // 超时处理
      await Future.delayed(const Duration(seconds: 5));

      if (!completer.isCompleted) {
        completer.complete(_isConnected);
      }

      return completer.future;
    } catch (e) {
      _scheduleReconnect();
      return false;
    }
  }

  /// 计划重连
  void _scheduleReconnect() {
    if (_isReconnecting) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      return;
    }

    _isReconnecting = true;
    _reconnectAttempts++;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      _isReconnecting = false;
      if (!_isConnected) {
        connect(_gatewayUrl, _authToken);
      }
    });
  }

  /// 启动心跳定时器
  void _startPingTimer() {
    _stopPingTimer();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isConnected) {
        sendMessage({'type': 'ping'});
      }
    });
  }

  /// 停止心跳定时器
  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  /// 断开连接
  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _stopPingTimer();
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _reconnectAttempts = _maxReconnectAttempts; // 防止自动重连
    _statusController.add(false);
  }

  /// 发送消息
  Future<bool> sendMessage(Map<String, dynamic> message) async {
    if (!_isConnected || _channel == null) {
      return false;
    }

    try {
      _channel!.sink.add(jsonEncode(message));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 发送任务给指定 Agent
  Future<bool> sendTaskToAgent({
    required String agentId,
    required String task,
    Map<String, dynamic>? context,
  }) async {
    return sendMessage({
      'type': 'task',
      'agentId': agentId,
      'task': task,
      'context': context ?? {},
    });
  }

  /// 获取 Agent 列表
  /// [fix] 修复内存泄漏：确保 StreamSubscription 总是被正确取消
  Future<List<Map<String, dynamic>>?> getAgents() async {
    if (!_isConnected) {
      return null;
    }

    StreamSubscription? subscription = null;
    Timer? timeout;

    try {
      final completer = Completer<List<Map<String, dynamic>>?>();

      timeout = Timer(const Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });

      subscription = messageStream.listen((message) {
        if (message['type'] == 'agents_list') {
          if (!completer.isCompleted) {
            completer.complete(List<Map<String, dynamic>>.from(message['agents'] ?? []));
          }
        }
      });

      // 先发送请求，如果失败则直接返回
      final sent = await sendMessage({'type': 'get_agents'});
      if (!sent) {
        timeout?.cancel();
        subscription?.cancel();  // 使用安全调用 ?. 与 finally 块保持一致
        return null;
      }

      final result = await completer.future;
      return result;
    } catch (e) {
      // 发生异常，返回 null
      return null;
    } finally {
      // 确保清理资源
      timeout?.cancel();
      subscription?.cancel();
    }
  }

  /// 检查网关状态
  Future<bool> checkStatus() async {
    if (!_isConnected) {
      return false;
    }

    return sendMessage({'type': 'ping'});
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _statusController.close();
  }
}
