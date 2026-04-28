import 'package:json_annotation/json_annotation.dart';

part 'project.g.dart';

/// 项目状态
enum ProjectStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
}

/// 工作流阶段
enum WorkflowStep {
  @JsonValue('design')
  design,
  @JsonValue('code')
  code,
  @JsonValue('review')
  review,
}

/// 项目模型
@JsonSerializable()
class Project {
  final String id;
  final String name;
  final String? description;
  final ProjectStatus status;
  final WorkflowStep currentStep;
  final int progress;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? context;

  Project({
    required this.id,
    required this.name,
    this.description,
    this.status = ProjectStatus.pending,
    this.currentStep = WorkflowStep.design,
    this.progress = 0,
    required this.createdAt,
    required this.updatedAt,
    this.context,
  });

  factory Project.fromJson(Map<String, dynamic> json) => _$ProjectFromJson(json);
  Map<String, dynamic> toJson() => _$ProjectToJson(this);

  Project copyWith({
    String? id,
    String? name,
    String? description,
    ProjectStatus? status,
    WorkflowStep? currentStep,
    int? progress,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? context,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      currentStep: currentStep ?? this.currentStep,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      context: context ?? this.context,
    );
  }

  String get statusText {
    switch (status) {
      case ProjectStatus.pending:
        return '等待中';
      case ProjectStatus.inProgress:
        return '进行中';
      case ProjectStatus.completed:
        return '已完成';
      case ProjectStatus.failed:
        return '失败';
    }
  }

  String get currentStepText {
    switch (currentStep) {
      case WorkflowStep.design:
        return '设计';
      case WorkflowStep.code:
        return '编码';
      case WorkflowStep.review:
        return '审核';
    }
  }

  String get currentStepEmoji {
    switch (currentStep) {
      case WorkflowStep.design:
        return '🎨';
      case WorkflowStep.code:
        return '💻';
      case WorkflowStep.review:
        return '🔍';
    }
  }
}
