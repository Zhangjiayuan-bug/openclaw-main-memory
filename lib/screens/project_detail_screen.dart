import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workflow_app/config/theme.dart';
import 'package:workflow_app/models/project.dart';
import 'package:workflow_app/providers/project_provider.dart';
import 'package:workflow_app/widgets/status_panel.dart';
import 'package:workflow_app/widgets/tech_button.dart';

/// 项目详情页面
class ProjectDetailScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  bool _isStartingWorkflow = false;

  @override
  Widget build(BuildContext context) {
    // 直接使用传入的 project，避免 provider 数据未加载导致的过期数据问题
    // 如果需要刷新，应该在打开此页面之前更新 provider
    final currentProject = widget.project;

    return Scaffold(
      backgroundColor: TechTheme.deepSpaceBlue,
      appBar: AppBar(
        backgroundColor: TechTheme.deepSpaceBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: TechTheme.electricCyan),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          currentProject.name,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: TechTheme.silverGray),
            onPressed: () => _refreshProject(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: TechTheme.silverGray),
            onPressed: () => _showProjectSettings(context),
          ),
        ],
      ),
      body: Consumer<ProjectProvider>(
        builder: (context, provider, _) {
          // 尝试从 provider 获取最新数据，如果 provider 中没有则使用传入的数据
          final latestProject = _getLatestProject(provider, currentProject);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusPanel(
                  project: latestProject,
                  agentOnlineStatus: const {
                    'sakura': true,
                    'conductor': true,
                    'design': true,
                    'code': false,
                    'review': false,
                  },
                  onStartWorkflow: _isStartingWorkflow
                      ? null
                      : () => _handleStartWorkflow(context, provider, latestProject),
                  onPauseWorkflow: () {
                    // TODO: 实现暂停
                  },
                  onShowDetails: () {
                    _showProjectDetails(context, latestProject);
                  },
                ),
                const SizedBox(height: 16),
                _buildChatSection(context, provider, latestProject),
                const SizedBox(height: 16),
                _buildFilesSection(context, latestProject),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 从 provider 获取最新项目数据，如果 provider 未加载则使用传入的数据
  Project _getLatestProject(ProjectProvider provider, Project fallback) {
    if (provider.projects.isEmpty) {
      return fallback;
    }

    final latestFromProvider = provider.projects.where((p) => p.id == fallback.id).firstOrNull;
    if (latestFromProvider == null) {
      return fallback;
    }

    // 比较更新时间，使用最新的
    return latestFromProvider.updatedAt.isAfter(fallback.updatedAt)
        ? latestFromProvider
        : fallback;
  }

  Future<void> _refreshProject(BuildContext context) async {
    final provider = context.read<ProjectProvider>();
    await provider.loadProjects();
  }

  Future<void> _handleStartWorkflow(
    BuildContext context,
    ProjectProvider provider,
    Project project,
  ) async {
    setState(() => _isStartingWorkflow = true);
    try {
      await provider.startWorkflow(project.id);
    } finally {
      if (mounted) {
        setState(() => _isStartingWorkflow = false);
      }
    }
  }

  Widget _buildChatSection(BuildContext context, ProjectProvider provider, Project project) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TechTheme.darkNightBlue,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TechTheme.starGrayBlue, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline, color: TechTheme.electricCyan, size: 20),
              const SizedBox(width: 8),
              const Text(
                '对话区',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TechIconButton(
                icon: Icons.refresh,
                size: 18,
                onPressed: () {
                  // TODO: 刷新聊天
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: TechTheme.starGrayBlue, height: 1),
          const SizedBox(height: 12),
          _buildChatMessage('🎭', 'conductor', '开始接收任务...', false),
          _buildChatMessage('🎨', 'code-designer', '收到设计任务，准备开始工作', false),
          _buildChatMessage('💻', 'code-writer', '等待中...', true),
        ],
      ),
    );
  }

  Widget _buildChatMessage(String emoji, String agent, String message, bool isWaiting) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agent,
                  style: const TextStyle(
                    color: TechTheme.silverGray,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isWaiting
                        ? TechTheme.starGrayBlue.withOpacity(0.3)
                        : TechTheme.deepSpaceBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: isWaiting ? TechTheme.starGrayBlue : Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilesSection(BuildContext context, Project project) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TechTheme.darkNightBlue,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TechTheme.starGrayBlue, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder, color: TechTheme.electricCyan, size: 20),
              const SizedBox(width: 8),
              const Text(
                '文件',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _buildFileCountBadge(project),
            ],
          ),
          const SizedBox(height: 12),
          _buildFileTree(),
        ],
      ),
    );
  }

  Widget _buildFileCountBadge(Project project) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: TechTheme.electricCyan.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        '3 个文件',
        style: TextStyle(
          color: TechTheme.electricCyan,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildFileTree() {
    return Column(
      children: [
        _buildFileItem('📄', 'design_spec.md', '100%', TechTheme.matrixGreen),
        _buildFileItem('📄', 'main.dart', '60%', TechTheme.electricCyan),
        _buildFileItem('📄', 'auth_service.dart', '100%', TechTheme.matrixGreen),
        _buildFileItem('📄', 'token_handler.dart', '100%', TechTheme.matrixGreen),
      ],
    );
  }

  Widget _buildFileItem(String emoji, String name, String progress, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: TechTheme.silverGray,
                fontSize: 14,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              progress,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProjectDetails(BuildContext context, Project project) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TechTheme.darkNightBlue,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '项目详情',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('项目名称', project.name),
            _buildDetailRow('状态', project.statusText),
            _buildDetailRow('当前阶段', project.currentStepText),
            _buildDetailRow('进度', '${project.progress}%'),
            _buildDetailRow('创建时间', _formatDateTime(project.createdAt)),
            _buildDetailRow('更新时间', _formatDateTime(project.updatedAt)),
            if (project.description != null && project.description!.isNotEmpty)
              _buildDetailRow('描述', project.description!),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: TechButton(
                label: '关闭',
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: TechTheme.silverGray,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showProjectSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TechTheme.darkNightBlue,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: TechTheme.electricCyan),
              title: const Text('编辑项目', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // TODO: 编辑项目
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: TechTheme.warningRed),
              title: const Text('删除项目', style: TextStyle(color: TechTheme.warningRed)),
              onTap: () {
                Navigator.pop(context);
                // TODO: 删除项目
              },
            ),
            ListTile(
              leading: const Icon(Icons.close, color: TechTheme.silverGray),
              title: const Text('关闭', style: TextStyle(color: TechTheme.silverGray)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
