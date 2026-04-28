import 'package:json_annotation/json_annotation.dart';

part 'agent.g.dart';

/// Agent 类型
enum AgentType {
  @JsonValue('sakura')
  sakura,
  @JsonValue('conductor')
  conductor,
  @JsonValue('code_designer')
  codeDesigner,
  @JsonValue('code_writer')
  codeWriter,
  @JsonValue('code_reviewer')
  codeReviewer,
}

/// Agent 在线状态
enum AgentOnlineStatus {
  @JsonValue('online')
  online,
  @JsonValue('offline')
  offline,
  @JsonValue('busy')
  busy,
}

/// Agent 模型
@JsonSerializable()
class Agent {
  final String id;
  final String name;
  final AgentType type;
  final AgentOnlineStatus onlineStatus;
  final String? avatar;
  final String? description;

  Agent({
    required this.id,
    required this.name,
    required this.type,
    this.onlineStatus = AgentOnlineStatus.offline,
    this.avatar,
    this.description,
  });

  factory Agent.fromJson(Map<String, dynamic> json) => _$AgentFromJson(json);
  Map<String, dynamic> toJson() => _$AgentToJson(this);

  String get emoji {
    switch (type) {
      case AgentType.sakura:
        return '🌸';
      case AgentType.conductor:
        return '🎭';
      case AgentType.codeDesigner:
        return '🎨';
      case AgentType.codeWriter:
        return '💻';
      case AgentType.codeReviewer:
        return '🔍';
    }
  }

  String get typeText {
    switch (type) {
      case AgentType.sakura:
        return 'sakura';
      case AgentType.conductor:
        return 'conductor';
      case AgentType.codeDesigner:
        return 'code-designer';
      case AgentType.codeWriter:
        return 'code-writer';
      case AgentType.codeReviewer:
        return 'code-reviewer';
    }
  }

  String get onlineStatusText {
    switch (onlineStatus) {
      case AgentOnlineStatus.online:
        return '在线';
      case AgentOnlineStatus.offline:
        return '离线';
      case AgentOnlineStatus.busy:
        return '忙碌';
    }
  }

  bool get isOnline => onlineStatus == AgentOnlineStatus.online;
}
