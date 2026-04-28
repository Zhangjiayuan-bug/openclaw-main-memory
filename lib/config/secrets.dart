/// 敏感配置 - 请勿提交到版本控制
/// 请复制此文件为 secrets.local.dart 并填写实际值

class Secrets {
  // OpenClaw Gateway
  static const String defaultGatewayUrl = 'ws://192.168.x.x:18789';
  static const String defaultGatewayToken = 'YOUR_GATEWAY_TOKEN_HERE';

  // 飞书 Agent 配置
  // 请从飞书开放平台获取实际值
  static const Map<String, Map<String, String>> feishuAgents = {
    'sakura': {
      'name': '🌸 Sakura',
      'appId': 'YOUR_APP_ID_FOR_SAKURA',
      'appSecret': 'YOUR_APP_SECRET_FOR_SAKURA',
    },
    'conductor': {
      'name': '🎭 Conductor',
      'appId': 'YOUR_APP_ID_FOR_CONDUCTOR',
      'appSecret': 'YOUR_APP_SECRET_FOR_CONDUCTOR',
    },
    'code-designer': {
      'name': '🎨 Code Designer',
      'appId': 'YOUR_APP_ID_FOR_CODE_DESIGNER',
      'appSecret': 'YOUR_APP_SECRET_FOR_CODE_DESIGNER',
    },
    'code-writer': {
      'name': '💻 Code Writer',
      'appId': 'YOUR_APP_ID_FOR_CODE_WRITER',
      'appSecret': 'YOUR_APP_SECRET_FOR_CODE_WRITER',
    },
    'code-reviewer': {
      'name': '🔍 Code Reviewer',
      'appId': 'YOUR_APP_ID_FOR_CODE_REVIEWER',
      'appSecret': 'YOUR_APP_SECRET_FOR_CODE_REVIEWER',
    },
  };
}
