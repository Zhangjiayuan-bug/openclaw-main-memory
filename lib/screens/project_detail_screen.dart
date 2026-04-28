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
  bool _isGeneratingFolder = false;

  // 真实聊天数据
  List<ChatMessage> _chatMessages = [];
  bool _isLoadingChat = false;

  // 真实文件数据
  List<FileNode> _fileNodes = [];
  bool _isLoadingFiles = false;

  // 展开的文件夹路径集合
  final Set<String> _expandedPaths = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAgentStatus();
      _loadChatMessages();
      _loadProjectFiles();
    });
  }

  Future<void> _fetchAgentStatus() async {
    final provider = context.read<ProjectProvider>();
    await provider.fetchAgentStatus();
  }

  Future<void> _loadChatMessages() async {
    if (!mounted) return;
    setState(() => _isLoadingChat = true);
    try {
      final provider = context.read<ProjectProvider>();
      final messages = await provider.getChatMessages(widget.project.id);
      if (mounted) {
        setState(() {
          _chatMessages = messages;
          _isLoadingChat = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingChat = false);
      }
    }
  }

  Future<void> _loadProjectFiles() async {
    if (!mounted) return;
    setState(() => _isLoadingFiles = true);
    try {
      final provider = context.read<ProjectProvider>();
      final files = await provider.scanProjectFiles(widget.project.id);
      if (mounted) {
        setState(() {
          _fileNodes = files;
          _isLoadingFiles = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingFiles = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: () {
              _refreshProject(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: TechTheme.silverGray),
            onPressed: () => _showProjectSettings(context),
          ),
        ],
      ),
      body: Consumer<ProjectProvider>(
        builder: (context, provider, _) {
          final latestProject = _getLatestProject(provider, currentProject);
          final agentStatus = provider.agentOnlineStatus;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusPanel(
                  project: latestProject,
                  agentOnlineStatus: agentStatus.isNotEmpty ? agentStatus : null,
                  onStartWorkflow: _isStartingWorkflow
                      ? null
                      : () => _handleStartWorkflow(context, provider, latestProject),
                  onPauseWorkflow: () => _handleStopWorkflow(context, provider, latestProject),
                  onShowDetails: () => _showProjectDetails(context, latestProject),
                ),
                const SizedBox(height: 16),
                _buildChatSection(context, provider, latestProject),
                const SizedBox(height: 16),
                _buildFilesSection(context, provider, latestProject),
              ],
            ),
          );
        },
      ),
    );
  }

  Project _getLatestProject(ProjectProvider provider, Project fallback) {
    if (provider.projects.isEmpty) return fallback;
    final latestFromProvider = provider.projects.where((p) => p.id == fallback.id).firstOrNull;
    if (latestFromProvider == null) return fallback;
    return latestFromProvider.updatedAt.isAfter(fallback.updatedAt)
        ? latestFromProvider
        : fallback;
  }

  Future<void> _refreshProject(BuildContext context) async {
    final provider = context.read<ProjectProvider>();
    await provider.loadProjects();
    await provider.fetchAgentStatus();
    _loadChatMessages();
    _loadProjectFiles();
  }

  Future<void> _handleStartWorkflow(
    BuildContext context,
    ProjectProvider provider,
    Project project,
  ) async {
    setState(() => _isStartingWorkflow = true);
    try {
      final success = await provider.startWorkflow(project.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: TechTheme.matrixGreen, size: 20),
                  const SizedBox(width: 8),
                  Text('🚀 ${project.name} 已启动'),
                ],
              ),
              backgroundColor: TechTheme.darkNightBlue,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: TechTheme.warningRed, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(provider.error ?? '启动失败')),
                ],
              ),
              backgroundColor: TechTheme.darkNightBlue,
              duration: const Duration(seconds: 3),
            ),
          );
          provider.clearError();
        }
      }
    } finally {
      if (mounted) setState(() => _isStartingWorkflow = false);
    }
  }

  Future<void> _handleStopWorkflow(
    BuildContext context,
    ProjectProvider provider,
    Project project,
  ) async {
    try {
      final success = await provider.stopWorkflow(project.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: TechTheme.matrixGreen, size: 20),
                  const SizedBox(width: 8),
                  Text('⏹ ${project.name} 已停止'),
                ],
              ),
              backgroundColor: TechTheme.darkNightBlue,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: TechTheme.warningRed, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(provider.error ?? '停止失败')),
                ],
              ),
              backgroundColor: TechTheme.darkNightBlue,
              duration: const Duration(seconds: 3),
            ),
          );
          provider.clearError();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: TechTheme.warningRed, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('停止失败: $e')),
              ],
            ),
            backgroundColor: TechTheme.darkNightBlue,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleGenerateFolder(
    BuildContext context,
    ProjectProvider provider,
    Project project,
  ) async {
    setState(() => _isGeneratingFolder = true);
    try {
      final folderPath = await provider.generateProjectFolder(project.id);
      if (mounted) {
        if (folderPath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.folder_open, color: TechTheme.matrixGreen, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text('📁 文件夹已生成: $folderPath')),
                ],
              ),
              backgroundColor: TechTheme.darkNightBlue,
              duration: const Duration(seconds: 4),
            ),
          );
          // 刷新文件列表
          _loadProjectFiles();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: TechTheme.warningRed, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(provider.error ?? '生成文件夹失败')),
                ],
              ),
              backgroundColor: TechTheme.darkNightBlue,
              duration: const Duration(seconds: 3),
            ),
          );
          provider.clearError();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: TechTheme.warningRed, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('生成文件夹失败: $e')),
              ],
            ),
            backgroundColor: TechTheme.darkNightBlue,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingFolder = false);
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
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (_isLoadingChat)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: TechTheme.electricCyan),
                )
              else
                TechIconButton(
                  icon: Icons.refresh,
                  size: 18,
                  onPressed: _loadChatMessages,
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: TechTheme.starGrayBlue, height: 1),
          const SizedBox(height: 12),
          if (_isLoadingChat)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('加载中...', style: TextStyle(color: TechTheme.silverGray)),
              ),
            )
          else if (_chatMessages.isEmpty)
            _buildEmptyChat(project)
          else
            ..._chatMessages.map((msg) => _buildChatMessage(msg)),
        ],
      ),
    );
  }

  Widget _buildEmptyChat(Project project) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TechTheme.deepSpaceBlue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Text(
            '💬 暂无对话记录',
            style: TextStyle(color: TechTheme.silverGray, fontSize: 14),
          ),
          const SizedBox(height: 8),
          if (project.status == ProjectStatus.inProgress)
            const Text(
              '工作流进行中，对话记录将实时更新',
              style: TextStyle(color: TechTheme.starGrayBlue, fontSize: 12),
            )
          else
            Text(
              '启动工作流后开始记录',
              style: TextStyle(color: TechTheme.starGrayBlue, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildChatMessage(ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(msg.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      msg.role,
                      style: const TextStyle(color: TechTheme.silverGray, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(msg.timestamp),
                      style: const TextStyle(color: TechTheme.starGrayBlue, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: TechTheme.deepSpaceBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    msg.content,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilesSection(BuildContext context, ProjectProvider provider, Project project) {
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
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (_isLoadingFiles)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: TechTheme.electricCyan),
                )
              else
                TechIconButton(
                  icon: Icons.refresh,
                  size: 18,
                  onPressed: _loadProjectFiles,
                ),
              const SizedBox(width: 4),
              _buildFileCountBadge(project),
            ],
          ),
          const SizedBox(height: 12),
          _buildFileTreeView(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TechButton(
              label: _isGeneratingFolder ? '生成中...' : '📁 生成文件夹',
              style: TechButtonStyle.secondary,
              onPressed: _isGeneratingFolder
                  ? null
                  : () => _handleGenerateFolder(context, provider, project),
            ),
          ),
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
      child: Text(
        '${project.progress}%',
        style: const TextStyle(color: TechTheme.electricCyan, fontSize: 12),
      ),
    );
  }

  Widget _buildFileTreeView() {
    if (_isLoadingFiles) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TechTheme.deepSpaceBlue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text('扫描文件中...', style: TextStyle(color: TechTheme.silverGray, fontSize: 14)),
        ),
      );
    }

    if (_fileNodes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TechTheme.deepSpaceBlue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            children: [
              Text('📂 暂无文件', style: TextStyle(color: TechTheme.silverGray, fontSize: 14)),
              SizedBox(height: 4),
              Text('点击"生成文件夹"创建项目结构', style: TextStyle(color: TechTheme.starGrayBlue, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: TechTheme.deepSpaceBlue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: _fileNodes.map((node) => _buildFileNodeRow(node, 0)).toList(),
      ),
    );
  }

  Widget _buildFileNodeRow(FileNode node, int depth) {
    final isExpanded = _expandedPaths.contains(node.path);
    final isRoot = node.path.split(RegExp(r'[/\\]')).length <= 3;

    return Column(
      children: [
        GestureDetector(
          onTap: node.isDirectory
              ? () {
                  setState(() {
                    if (isExpanded) {
                      _expandedPaths.remove(node.path);
                    } else {
                      _expandedPaths.add(node.path);
                    }
                  });
                }
              : null,
          child: Container(
            padding: EdgeInsets.only(left: 8.0 + depth * 16, right: 8, top: 6, bottom: 6),
            child: Row(
              children: [
                if (node.isDirectory)
                  Icon(
                    isExpanded ? Icons.expand_more : Icons.chevron_right,
                    color: TechTheme.silverGray,
                    size: 18,
                  )
                else
                  const SizedBox(width: 18),
                const SizedBox(width: 4),
                Text(
                  node.isDirectory ? '📁' : _getFileEmoji(node.name),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    node.name,
                    style: TextStyle(
                      color: isRoot ? Colors.white : TechTheme.silverGray,
                      fontSize: isRoot ? 14 : 13,
                      fontWeight: isRoot ? FontWeight.w500 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (node.isDirectory && node.children.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: TechTheme.starGrayBlue.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${node.children.length}',
                      style: const TextStyle(color: TechTheme.silverGray, fontSize: 10),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // 子节点（递归展开）
        if (node.isDirectory && isExpanded)
          ...node.children.map((child) => _buildFileNodeRow(child, depth + 1)),
        const Divider(color: TechTheme.starGrayBlue, height: 1, indent: 8),
      ],
    );
  }

  String _getFileEmoji(String filename) {
    final ext = filename.contains('.') ? filename.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'dart':
        return '🔵';
      case 'md':
        return '📝';
      case 'json':
        return '📋';
      case 'yaml':
      case 'yml':
        return '⚙️';
      case 'txt':
        return '📄';
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'svg':
        return '🖼️';
      case 'pdf':
        return '📕';
      case 'zip':
      case 'tar':
      case 'gz':
        return '📦';
      default:
        return '📄';
    }
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
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
              child: TechButton(label: '关闭', onPressed: () => Navigator.pop(context)),
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
            child: Text(label, style: const TextStyle(color: TechTheme.silverGray, fontSize: 14)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: TechTheme.warningRed),
              title: const Text('删除项目', style: TextStyle(color: TechTheme.warningRed)),
              onTap: () => Navigator.pop(context),
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
