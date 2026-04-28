// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Agent _$AgentFromJson(Map<String, dynamic> json) => Agent(
      id: json['id'] as String,
      name: json['name'] as String,
      type: $enumDecode(_$AgentTypeEnumMap, json['type']),
      onlineStatus: $enumDecodeNullable(_$AgentOnlineStatusEnumMap, json['onlineStatus']) ??
          AgentOnlineStatus.offline,
      avatar: json['avatar'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$AgentToJson(Agent instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$AgentTypeEnumMap[instance.type]!,
      'onlineStatus': _$AgentOnlineStatusEnumMap[instance.onlineStatus]!,
      'avatar': instance.avatar,
      'description': instance.description,
    };

const _$AgentTypeEnumMap = {
  AgentType.sakura: 'sakura',
  AgentType.conductor: 'conductor',
  AgentType.codeDesigner: 'code_designer',
  AgentType.codeWriter: 'code_writer',
  AgentType.codeReviewer: 'code_reviewer',
};

const _$AgentOnlineStatusEnumMap = {
  AgentOnlineStatus.online: 'online',
  AgentOnlineStatus.offline: 'offline',
  AgentOnlineStatus.busy: 'busy',
};

T $enumDecode<T extends Enum>(
  Map<T, String> enumValues,
  Object? source, {
  T? unknownValue,
}) {
  if (source == null) {
    throw ArgumentError(
      'A value must be provided. Supported values: '
      '${enumValues.values.join(', ')}',
    );
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
