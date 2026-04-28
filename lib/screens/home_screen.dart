import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workflow_app/config/theme.dart';
import 'package:workflow_app/providers/project_provider.dart';
import 'package:workflow_app/widgets/project_card.dart';
import 'package:workflow_app/widgets/tech_button.dart';
import 'package:workflow_app/screens/project_detail_screen.dart';

/// 首页 - 项目列表
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TechTheme.deepSpaceBlue,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildProjectList(),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.rocket_launch,
                color: TechTheme.electricCyan,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '工作流助手',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Consumer<ProjectProvider>(
                builder: (context, provider, _) {
                  return Row(
                    children: [
                      _buildConnectionIndicator(
                        '🌐',
                        provider.isOpenClawConnected,
                      ),
                      const SizedBox(width: 8),
                      _buildConnectionIndicator(
                        '📱',
                        provider.isFeishuConfigured,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildConnectionIndicator(String emoji, bool isConnected) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isConnected
            ? TechTheme.matrixGreen.withOpacity(0.2)
            : TechTheme.starGrayBlue.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 16)),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: TechTheme.darkNightBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TechTheme.starGrayBlue, width: 0.5),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: '搜索项目...',
          hintStyle: const TextStyle(color: TechTheme.starGrayBlue),
          prefixIcon: const Icon(Icons.search, color: TechTheme.starGrayBlue),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: const Icon(Icons.clear, color: TechTheme.starGrayBlue),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildProjectList() {
    return Consumer<ProjectProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: TechTheme.electricCyan,
            ),
          );
        }

        var projects = provider.projects;

        // 过滤
        if (_searchQuery.isNotEmpty) {
          projects = projects.where((p) {
            return p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (p.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
          }).toList();
        }

        if (projects.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final project = projects[index];
            return ProjectCard(
              project: project,
              onTap: () {
                provider.selectProject(project);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProjectDetailScreen(project: project),
                  ),
                );
              },
              onDelete: () => _showDeleteDialog(context, provider, project.id, project.name),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.folder_open,
            size: 64,
            color: TechTheme.starGrayBlue,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? '暂无项目' : '未找到匹配项目',
            style: const TextStyle(
              color: TechTheme.silverGray,
              fontSize: 18,
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              '点击下方按钮创建新项目',
              style: TextStyle(
                color: TechTheme.starGrayBlue,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: TechTheme.electricCyan.withOpacity(0.4),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: TechButton(
        label: '新建项目',
        icon: Icons.add,
        onPressed: () => _showCreateProjectDialog(context),
      ),
    );
  }

  /// 验证项目名称
  /// 返回 null 表示验证通过，否则返回错误信息
  String? _validateProjectName(String name) {
    if (name.isEmpty) {
      return '项目名称不能为空';
    }
    if (name.length > 100) {
      return '项目名称不能超过100个字符';
    }
    // 只允许中文、英文、数字、空格和部分符号
    final validPattern = RegExp(r'^[\u4e00-\u9fa5a-zA-Z0-9\s\-_.,;:!?（）()\[\]【】]+$');
    if (!validPattern.hasMatch(name)) {
      return '项目名称包含非法字符';
    }
    return null;
  }

  void _showCreateProjectDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? nameError;
    bool isCreating = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: TechTheme.darkNightBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: TechTheme.starGrayBlue),
          ),
          title: const Text(
            '创建新项目',
            style: TextStyle(color: Colors.white),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: '项目名称',
                    labelStyle: const TextStyle(color: TechTheme.silverGray),
                    errorText: nameError,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: TechTheme.starGrayBlue),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: TechTheme.electricCyan),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: TechTheme.warningRed),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: TechTheme.warningRed),
                    ),
                  ),
                  validator: (value) {
                    final error = _validateProjectName(value ?? '');
                    if (error != null) {
                      return error;
                    }
                    return null;
                  },
                  onChanged: (value) {
                    if (nameError != null) {
                      setDialogState(() => nameError = null);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: '项目描述（可选）',
                    labelStyle: const TextStyle(color: TechTheme.silverGray),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: TechTheme.starGrayBlue),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: TechTheme.electricCyan),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isCreating ? null : () => Navigator.pop(context),
              child: Text(
                '取消',
                style: TextStyle(
                  color: isCreating ? TechTheme.starGrayBlue : TechTheme.silverGray,
                ),
              ),
            ),
            TechButton(
              label: isCreating ? '创建中...' : '创建',
              icon: isCreating ? null : Icons.add,
              onPressed: isCreating
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      final nameValidationError = _validateProjectName(name);
                      if (nameValidationError != null) {
                        setDialogState(() => nameError = nameValidationError);
                        return;
                      }

                      setDialogState(() {
                        isCreating = true;
                        nameError = null;
                      });

                      final provider = context.read<ProjectProvider>();
                      final project = await provider.createProject(
                        name: name,
                        description: descController.text.trim(),
                      );

                      if (context.mounted) {
                        Navigator.pop(context);
                        if (project != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProjectDetailScreen(project: project),
                            ),
                          );
                        }
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    ProjectProvider provider,
    String projectId,
    String projectName,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TechTheme.darkNightBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: TechTheme.warningRed),
        ),
        title: const Text(
          '删除项目',
          style: TextStyle(color: TechTheme.warningRed),
        ),
        content: Text(
          '确定要删除项目 "$projectName" 吗？\n此操作不可恢复。',
          style: const TextStyle(color: TechTheme.silverGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TechButton(
            label: '删除',
            style: TechButtonStyle.danger,
            onPressed: () {
              provider.deleteProject(projectId);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
