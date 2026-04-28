import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workflow_app/config/theme.dart';
import 'package:workflow_app/config/secrets.dart';
import 'package:workflow_app/providers/project_provider.dart';
import 'package:workflow_app/widgets/tech_button.dart';

/// 设置页面
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _gatewayUrlController = TextEditingController(text: Secrets.defaultGatewayUrl);
  final _gatewayTokenController = TextEditingController(text: Secrets.defaultGatewayToken);
  final _feishuAppIdController = TextEditingController();
  final _feishuAppSecretController = TextEditingController();
  bool _showToken = false;

  // 飞书 Agent 配置（从 Secrets 配置获取）
  Map<String, Map<String, String>> get _feishuAgents => Secrets.feishuAgents;

  String _selectedAgent = 'sakura';

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  void _loadConfig() {
    // 预填充选中的 Agent 配置
    final agent = _feishuAgents[_selectedAgent]!;
    _feishuAppIdController.text = agent['appId']!;
    _feishuAppSecretController.text = agent['appSecret']!;
  }

  @override
  void dispose() {
    _gatewayUrlController.dispose();
    _gatewayTokenController.dispose();
    _feishuAppIdController.dispose();
    _feishuAppSecretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TechTheme.deepSpaceBlue,
      appBar: AppBar(
        backgroundColor: TechTheme.deepSpaceBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: TechTheme.electricCyan),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('设置', style: TextStyle(color: Colors.white)),
      ),
      body: Consumer<ProjectProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  '📡 OpenClaw 网关连接（手机必填）',
                  [
                    _buildInfoText('手机需要填写电脑的局域网 IP 地址'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _gatewayUrlController,
                      label: '网关地址',
                      hint: 'ws://192.168.1.100:18789',
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _gatewayTokenController,
                      label: '认证令牌',
                      hint: '输入网关令牌',
                      obscureText: !_showToken,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showToken ? Icons.visibility_off : Icons.visibility,
                          color: TechTheme.silverGray,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _showToken = !_showToken),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildConnectionStatus(
                            '连接状态',
                            provider.isOpenClawConnected ? '已连接' : '未连接',
                            provider.isOpenClawConnected,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 100,
                          child: TechButton(
                            label: provider.isOpenClawConnected ? '断开' : '连接',
                            style: provider.isOpenClawConnected
                                ? TechButtonStyle.danger
                                : TechButtonStyle.primary,
                            onPressed: () {
                              if (provider.isOpenClawConnected) {
                                provider.disconnectFromOpenClaw();
                              } else {
                                provider.connectToOpenClaw(
                                  _gatewayUrlController.text,
                                  _gatewayTokenController.text,
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSection(
                  '📱 飞书 Agent 选择',
                  [
                    _buildAgentSelector(),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSection(
                  '🔑 飞书应用凭证（已从配置导入）',
                  [
                    _buildTextField(
                      controller: _feishuAppIdController,
                      label: 'App ID',
                      hint: 'cli_xxxxxxxxxxxx',
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _feishuAppSecretController,
                      label: 'App Secret',
                      hint: 'xxxxxxxxxxxxxxxx',
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildConnectionStatus(
                            '配置状态',
                            provider.isFeishuConfigured ? '已配置' : '未配置',
                            provider.isFeishuConfigured,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 100,
                          child: TechButton(
                            label: '保存',
                            onPressed: () {
                              provider.configureFeishu(
                                appId: _feishuAppIdController.text,
                                appSecret: _feishuAppSecretController.text,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('飞书配置已保存')),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSection(
                  '🎨 界面设置',
                  [
                    _buildSwitchItem('深色主题', '使用深色科技风界面', true),
                    _buildSwitchItem('动画效果', '界面动画和过渡效果', true),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSection(
                  'ℹ️ 关于',
                  [
                    _buildInfoItem('版本', '1.0.0'),
                    _buildInfoItem('构建', '2026.04.27'),
                    _buildInfoItem('说明', '手机需要和电脑在同一局域网'),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAgentSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '选择要管理的 Agent',
          style: TextStyle(
            color: TechTheme.silverGray,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: TechTheme.deepSpaceBlue,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: TechTheme.starGrayBlue),
          ),
          child: DropdownButton<String>(
            value: _selectedAgent,
            isExpanded: true,
            dropdownColor: TechTheme.darkNightBlue,
            style: const TextStyle(color: Colors.white),
            underline: const SizedBox(),
            items: _feishuAgents.entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.key,
                child: Text(entry.value['name']!),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedAgent = value;
                  final agent = _feishuAgents[value]!;
                  _feishuAppIdController.text = agent['appId']!;
                  _feishuAppSecretController.text = agent['appSecret']!;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: TechTheme.electricCyan,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TechTheme.darkNightBlue,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: TechTheme.starGrayBlue, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: TechTheme.silverGray,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: TechTheme.starGrayBlue),
            filled: true,
            fillColor: TechTheme.deepSpaceBlue,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: TechTheme.starGrayBlue),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: TechTheme.starGrayBlue),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: TechTheme.electricCyan),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionStatus(String label, String value, bool isConnected) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isConnected
            ? TechTheme.matrixGreen.withOpacity(0.1)
            : TechTheme.warningRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isConnected ? TechTheme.matrixGreen : TechTheme.warningRed,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: TechTheme.silverGray,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isConnected ? TechTheme.matrixGreen : TechTheme.warningRed,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    color: isConnected ? TechTheme.matrixGreen : TechTheme.warningRed,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoText(String text) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: TechTheme.electricCyan.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TechTheme.electricCyan.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: TechTheme.electricCyan, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: TechTheme.electricCyan,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchItem(String title, String subtitle, bool value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: TechTheme.silverGray,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (v) {},
            activeColor: TechTheme.electricCyan,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: TechTheme.silverGray,
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
