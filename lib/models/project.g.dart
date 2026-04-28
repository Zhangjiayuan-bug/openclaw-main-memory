// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Project _$ProjectFromJson(Map<String, dynamic> json) => Project(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      status: $enumDecodeNullable(_$ProjectStatusEnumMap, json['status']) ??
          ProjectStatus.pending,
      currentStep: $enumDecodeNullable(_$WorkflowStepEnumMap, json['currentStep']) ??
          WorkflowStep.design,
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      context: json['context'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ProjectToJson(Project instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'status': _$ProjectStatusEnumMap[instance.status]!,
      'currentStep': _$WorkflowStepEnumMap[instance.currentStep]!,
      'progress': instance.progress,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'context': instance.context,
    };

const _$ProjectStatusEnumMap = {
  ProjectStatus.pending: 'pending',
  ProjectStatus.inProgress: 'in_progress',
  ProjectStatus.completed: 'completed',
  ProjectStatus.failed: 'failed',
};

const _$WorkflowStepEnumMap = {
  WorkflowStep.design: 'design',
  WorkflowStep.code: 'code',
  WorkflowStep.review: 'review',
};

T? $enumDecodeNullable<T extends Enum>(
  Map<T, String> enumValues,
  Object? source, {
  T? unknownValue,
}) {
  if (source == null) {
    return null;
  }
  for (final entry in enumValues.entries) {
    if (entry.value == source) {
      return entry.key;
    }
  }
  if (unknownValue == null) {
    throw ArgumentError(
      '`$source` is not one of the supported values: '
      '${enumValues.values.join(', ')}',
    );
  }
  return unknownValue;
}
