import 'package:flutter/material.dart';
import 'package:workflow_app/config/theme.dart';
import 'package:workflow_app/models/project.dart';

/// 项目卡片组件
class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ProjectCard({
    super.key,
    required this.project,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: TechTheme.darkNightBlue,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getBorderColor(),
            width: _isActive() ? 1.5 : 0.5,
          ),
          boxShadow: _isActive()
              ? [
                  BoxShadow(
                    color: _getBorderColor().withOpacity(0.2),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildProgress(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  bool _isActive() {
    return project.status == ProjectStatus.inProgress ||
        project.status == ProjectStatus.pending;
  }

  Color _getBorderColor() {
    switch (project.status) {
      case ProjectStatus.inProgress:
        return TechTheme.electricCyan;
      case ProjectStatus.completed:
        return TechTheme.matrixGreen;
      case ProjectStatus.failed:
        return TechTheme.warningRed;
      case ProjectStatus.pending:
        return TechTheme.energyYellow;
    }
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: TechTheme.electricCyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                project.currentStepEmoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (project.description != null && project.description!.isNotEmpty)
                  Text(
                    project.description!,
                    style: const TextStyle(
                      color: TechTheme.silverGray,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          _buildStatusBadge(),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;
    IconData icon;

    switch (project.status) {
      case ProjectStatus.pending:
        color = TechTheme.energyYellow;
        text = '等待';
        icon = Icons.schedule;
        break;
      case ProjectStatus.inProgress:
        color = TechTheme.electricCyan;
        text = '进行中';
        icon = Icons.sync;
        break;
      case ProjectStatus.completed:
        color = TechTheme.matrixGreen;
        text = '完成';
        icon = Icons.check_circle;
        break;
      case ProjectStatus.failed:
        color = TechTheme.warningRed;
        text = '失败';
        icon = Icons.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStepChip('🎨', project.currentStep.index >= 0),
              _buildStepLine(project.currentStep.index >= 1),
              _buildStepChip('💻', project.currentStep.index >= 1),
              _buildStepLine(project.currentStep.index >= 2),
              _buildStepChip('🔍', project.currentStep.index >= 2),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: project.progress / 100,
              backgroundColor: TechTheme.starGrayBlue,
              valueColor: AlwaysStoppedAnimation<Color>(_getBorderColor()),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepChip(String emoji, bool isCompleted) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isCompleted
            ? TechTheme.matrixGreen.withOpacity(0.2)
            : TechTheme.starGrayBlue.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isCompleted ? TechTheme.matrixGreen : TechTheme.starGrayBlue,
          width: 1,
        ),
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 14)),
      ),
    );
  }

  Widget _buildStepLine(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: isCompleted ? TechTheme.matrixGreen : TechTheme.starGrayBlue,
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(
            Icons.access_time,
            color: TechTheme.starGrayBlue,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            _formatTime(project.updatedAt),
            style: const TextStyle(
              color: TechTheme.starGrayBlue,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Text(
            '${project.progress}%',
            style: const TextStyle(
              color: TechTheme.electricCyan,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(
                Icons.delete_outline,
                color: TechTheme.warningRed,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${time.month}/${time.day}';
    }
  }
}
