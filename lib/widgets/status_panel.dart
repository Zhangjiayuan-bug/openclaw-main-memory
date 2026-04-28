import 'package:flutter/material.dart';
import 'package:workflow_app/config/theme.dart';
import 'package:workflow_app/models/project.dart';

/// 状态面板组件
class StatusPanel extends StatelessWidget {
  final Project? project;
  final Map<String, bool>? agentOnlineStatus;
  final VoidCallback? onStartWorkflow;
  final VoidCallback? onPauseWorkflow;
  final VoidCallback? onShowDetails;

  const StatusPanel({
    super.key,
    this.project,
    this.agentOnlineStatus,
    this.onStartWorkflow,
    this.onPauseWorkflow,
    this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    if (project == null) {
      return _buildEmptyState();
    }

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
          _buildHeader(),
          const SizedBox(height: 16),
          _buildAgentStatus(),
          const SizedBox(height: 16),
          _buildProgressSection(),
          const SizedBox(height: 16),
          _buildCurrentFile(),
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: TechTheme.darkNightBlue,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TechTheme.starGrayBlue, width: 0.5),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(
              Icons.folder_open,
              size: 48,
              color: TechTheme.starGrayBlue,
            ),
            SizedBox(height: 16),
            Text(
              '选择一个项目查看状态',
              style: TextStyle(
                color: TechTheme.silverGray,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(
          Icons.info_outline,
          color: TechTheme.electricCyan,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            project!.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;

    switch (project!.status) {
      case ProjectStatus.pending:
        color = TechTheme.energyYellow;
        text = '等待中';
        break;
      case ProjectStatus.inProgress:
        color = TechTheme.electricCyan;
        text = '进行中';
        break;
      case ProjectStatus.completed:
        color = TechTheme.matrixGreen;
        text = '已完成';
        break;
      case ProjectStatus.failed:
        color = TechTheme.warningRed;
        text = '失败';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAgentStatus() {
    // Agent 名称和图标映射（可以从 provider 动态获取，这里列出所有可能的 agent）
    final agentMappings = [
      {'key': 'sakura', 'emoji': '🌸', 'label': 'sakura'},
      {'key': 'conductor', 'emoji': '🎭', 'label': 'conductor'},
      {'key': 'design', 'emoji': '🎨', 'label': 'design'},
      {'key': 'code', 'emoji': '💻', 'label': 'code'},
      {'key': 'review', 'emoji': '🔍', 'label': 'review'},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: agentMappings.map((agent) {
        // 从 agentOnlineStatus 中获取状态，如果不存在则默认离线
        final isOnline = agentOnlineStatus?[agent['key'] as String] ?? false;
        return _buildAgentItem(
          agent['emoji'] as String,
          agent['label'] as String,
          isOnline,
        );
      }).toList(),
    );
  }

  Widget _buildAgentItem(String emoji, String name, bool isOnline) {
    return Column(
      children: [
        Stack(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isOnline ? TechTheme.matrixGreen : TechTheme.starGrayBlue,
                  shape: BoxShape.circle,
                  border: Border.all(color: TechTheme.darkNightBlue, width: 1),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: const TextStyle(
            color: TechTheme.silverGray,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildStepItem('🎨', '设计', WorkflowStep.design),
            _buildStepConnector(project!.currentStep.index >= WorkflowStep.code.index),
            _buildStepItem('💻', '编码', WorkflowStep.code),
            _buildStepConnector(project!.currentStep.index >= WorkflowStep.review.index),
            _buildStepItem('🔍', '审核', WorkflowStep.review),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: project!.progress / 100,
            backgroundColor: TechTheme.starGrayBlue,
            valueColor: const AlwaysStoppedAnimation<Color>(TechTheme.electricCyan),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '当前阶段: ${project!.currentStepEmoji} ${project!.currentStepText}',
              style: const TextStyle(
                color: TechTheme.silverGray,
                fontSize: 12,
              ),
            ),
            Text(
              '${project!.progress}%',
              style: const TextStyle(
                color: TechTheme.electricCyan,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepItem(String emoji, String label, WorkflowStep step) {
    final isActive = project!.currentStep.index >= step.index;
    final isCurrent = project!.currentStep == step;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCurrent
                ? TechTheme.electricCyan.withOpacity(0.2)
                : isActive
                    ? TechTheme.matrixGreen.withOpacity(0.2)
                    : TechTheme.starGrayBlue.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCurrent
                  ? TechTheme.electricCyan
                  : isActive
                      ? TechTheme.matrixGreen
                      : TechTheme.starGrayBlue,
              width: isCurrent ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : TechTheme.starGrayBlue,
            fontSize: 12,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: isActive ? TechTheme.matrixGreen : TechTheme.starGrayBlue,
      ),
    );
  }

  Widget _buildCurrentFile() {
    if (project!.status == ProjectStatus.completed || project!.status == ProjectStatus.pending) {
      return const SizedBox.shrink();
    }

    // 根据当前阶段显示当前正在处理的文件名
    // 文件名应该从项目数据中获取，这里使用 project 的 context 或其他字段
    // 如果没有，则显示默认文件名
    String currentFileName = project!.currentStepFileName;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TechTheme.deepSpaceBlue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.insert_drive_file,
            color: TechTheme.electricCyan,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              currentFileName,
              style: const TextStyle(
                color: TechTheme.silverGray,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            '${project!.progress}%',
            style: const TextStyle(
              color: TechTheme.electricCyan,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.play_arrow,
            label: '一键启动',
            color: TechTheme.matrixGreen,
            onTap: onStartWorkflow,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionButton(
            icon: Icons.pause,
            label: '暂停',
            color: TechTheme.energyYellow,
            onTap: onPauseWorkflow,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionButton(
            icon: Icons.list,
            label: '详情',
            color: TechTheme.electricCyan,
            onTap: onShowDetails,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
