import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:workflow_app/models/project.dart';
import 'package:workflow_app/services/storage_service.dart';
import 'package:workflow_app/services/openclaw_service.dart';
import 'package:workflow_app/services/feishu_service.dart';

/// 项目 Provider
/// 负责应用状态管理
class ProjectProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final OpenClawService _openclaw = OpenClawService();
  final FeishuService _feishu = FeishuService();
  final Uuid _uuid = const Uuid();

  List<Project> _projects = [];
  Project? _currentProject;
  bool _isLoading = false;
  String? _error;

  // Agent 在线状态（从 OpenClaw Gateway 真实获取）
  Map<String, bool> _agentOnlineStatus = {};

  // Workflow 操作进行中标志
  final Set<String> _workflowOperationsInProgress = {};

  // 文件夹生成结果
  String? _lastGeneratedFolderPath;
  bool? _lastFolderGenerationSuccess;

  // Getters
  List<Project> get projects => _projects;
  Project? get currentProject => _currentProject;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, bool> get agentOnlineStatus => _agentOnlineStatus;
  String? get lastGeneratedFolderPath => _lastGeneratedFolderPath;
  bool? get lastFolderGenerationSuccess => _lastFolderGenerationSuccess;

  /// 检查指定项目的 workflow 操作是否正在进行
  bool isWorkflowOperationInProgress(String projectId) =>
      _workflowOperationsInProgress.contains(projectId);

  bool get isOpenClawConnected => _openclaw.isConnected;
  bool get isFeishuConfigured => _feishu.isConfigured;

  /// 初始化
  Future<void> init() async {
    await _storage.init();
    await loadProjects();
  }

  /// 从 OpenClaw Gateway 获取 Agent 状态
  Future<void> fetchAgentStatus() async {
    if (!_openclaw.isConnected) {
      return;
    }

    try {
      final agents = await _openclaw.getAgents();
      if (agents != null) {
        final newStatus = <String, bool>{};
        for (final agent in agents) {
          final id = agent['id']?.toString() ?? agent['name']?.toString();
          if (id != null) {
            // Agent 状态可能在 'status' 或 'online' 或 'isOnline' 字段
            final status = agent['status'] ?? agent['online'] ?? agent['isOnline'];
            bool isOnline = false;
            if (status is bool) {
              isOnline = status;
            } else if (status is String) {
              isOnline = status.toLowerCase() == 'online' || status.toLowerCase() == 'true';
            }
            newStatus[id] = isOnline;
          }
        }
        _agentOnlineStatus = newStatus;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ProjectProvider] fetchAgentStatus failed: $e');
    }
  }

  /// 加载所有项目
  Future<void> loadProjects() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _projects = await _storage.loadAllProjects();
    } catch (e) {
      _error = '加载项目失败: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 创建新项目
  /// [name] 项目名称，必填，长度1-100字符
  /// [description] 项目描述，可选
  /// [context] 额外上下文数据，可选
  /// 返回创建的项目，失败返回null
  Future<Project?> createProject({
    required String name,
    String? description,
    Map<String, dynamic>? context,
  }) async {
    // 输入验证
    final validationError = _validateProjectName(name);
    if (validationError != null) {
      _error = validationError;
      notifyListeners();
      return null;
    }

    // 描述长度验证
    if (description != null && description.length > 500) {
      _error = '项目描述不能超过500字符';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final project = Project(
        id: _uuid.v4(),
        name: name.trim(),
        description: description?.trim(),
        status: ProjectStatus.pending,
        currentStep: WorkflowStep.design,
        progress: 0,
        createdAt: now,
        updatedAt: now,
        context: context,
      );

      await _storage.createProject(project);
      _projects.insert(0, project);

      _isLoading = false;
      notifyListeners();
      return project;
    } catch (e) {
      _error = '创建项目失败: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// 验证项目名称
  /// [name] 必填参数，非空字符串
  /// 返回 null 表示验证通过，返回错误消息表示验证失败
  String? _validateProjectName(String name) {
    // name 是 required String，非空检查由调用方保证
    // 此处只检查格式和长度

    final trimmed = name.trim();

    // 检查是否为空（trim后为空说明输入全为空白）
    if (trimmed.isEmpty) {
      return '项目名称不能为空';
    }

    if (trimmed.length > 100) {
      return '项目名称不能超过100字符';
    }

    if (trimmed.length < 2) {
      return '项目名称至少2个字符';
    }

    // 检查是否包含非法字符
    final invalidChars = RegExp(r'[<>:"/\\|?*\x00-\x1f]');
    if (invalidChars.hasMatch(trimmed)) {
      return '项目名称包含非法字符';
    }

    return null;
  }

  /// 选择当前项目
  void selectProject(Project? project) {
    _currentProject = project;
    notifyListeners();
  }

  /// 更新项目
  Future<void> updateProject(Project project) async {
    try {
      final updated = project.copyWith(updatedAt: DateTime.now());
      await _storage.saveProject(updated);

      final index = _projects.indexWhere((p) => p.id == project.id);
      if (index >= 0) {
        _projects[index] = updated;
      }

      if (_currentProject?.id == project.id) {
        _currentProject = updated;
      }

      notifyListeners();
    } catch (e) {
      _error = '更新项目失败: $e';
      notifyListeners();
    }
  }

  /// 删除项目
  Future<void> deleteProject(String projectId) async {
    try {
      await _storage.deleteProject(projectId);
      _projects.removeWhere((p) => p.id == projectId);

      if (_currentProject?.id == projectId) {
        _currentProject = null;
      }

      notifyListeners();
    } catch (e) {
      _error = '删除项目失败: $e';
      notifyListeners();
    }
  }

  /// 启动工作流
  /// 返回 true 表示启动成功，false 表示失败
  Future<bool> startWorkflow(String projectId) async {
    if (_workflowOperationsInProgress.contains(projectId)) {
      _error = '工作流操作正在进行中';
      notifyListeners();
      return false;
    }

    _workflowOperationsInProgress.add(projectId);
    _error = null;
    notifyListeners();

    try {
      final project = _projects.firstWhere((p) => p.id == projectId);
      await updateProject(project.copyWith(
        status: ProjectStatus.inProgress,
        currentStep: WorkflowStep.design,
        progress: 0,
      ));

      // 发送设计任务给 code-designer
      // 通过 OpenClaw 网关发送任务
      if (_openclaw.isConnected) {
        final sent = await _openclaw.sendTaskToAgent(
          agentId: 'code-designer',
          task: 'start_design',
          context: {
            'projectId': project.id,
            'projectName': project.name,
            'requirements': project.description ?? '',
          },
        );
        if (!sent) {
          _error = '发送任务失败：网关未连接';
          return false;
        }
      } else {
        _error = '启动失败：OpenClaw 网关未连接';
        return false;
      }

      return true;
    } catch (e) {
      _error = '启动失败: $e';
      return false;
    } finally {
      _workflowOperationsInProgress.remove(projectId);
      notifyListeners();
    }
  }

  /// 停止工作流
  /// 返回 true 表示停止成功，false 表示失败
  Future<bool> stopWorkflow(String projectId) async {
    if (_workflowOperationsInProgress.contains(projectId)) {
      _error = '工作流操作正在进行中';
      notifyListeners();
      return false;
    }

    _workflowOperationsInProgress.add(projectId);
    _error = null;
    notifyListeners();

    try {
      final project = _projects.firstWhere((p) => p.id == projectId);
      await updateProject(project.copyWith(
        status: ProjectStatus.pending,
        progress: 0,
      ));

      // 通知 conductor 停止任务
      if (_openclaw.isConnected) {
        await _openclaw.sendTaskToAgent(
          agentId: 'conductor',
          task: 'stop_workflow',
          context: {
            'projectId': project.id,
          },
        );
      }

      return true;
    } catch (e) {
      _error = '停止失败: $e';
      return false;
    } finally {
      _workflowOperationsInProgress.remove(projectId);
      notifyListeners();
    }
  }

  /// 更新工作流阶段
  Future<void> advanceStep(String projectId) async {
    if (_workflowOperationsInProgress.contains(projectId)) {
      return;
    }

    _workflowOperationsInProgress.add(projectId);
    notifyListeners();

    try {
      final project = _projects.firstWhere((p) => p.id == projectId);

      WorkflowStep nextStep;
      int newProgress;

      switch (project.currentStep) {
        case WorkflowStep.design:
          nextStep = WorkflowStep.code;
          newProgress = 33;
          break;
        case WorkflowStep.code:
          nextStep = WorkflowStep.review;
          newProgress = 66;
          break;
        case WorkflowStep.review:
          nextStep = WorkflowStep.review;
          newProgress = 100;
          await updateProject(project.copyWith(
            status: ProjectStatus.completed,
            progress: 100,
          ));
          return;
      }

      await updateProject(project.copyWith(
        currentStep: nextStep,
        progress: newProgress,
      ));
    } finally {
      _workflowOperationsInProgress.remove(projectId);
      notifyListeners();
    }
  }

  /// 完成任务
  Future<void> completeProject(String projectId) async {
    if (_workflowOperationsInProgress.contains(projectId)) {
      return;
    }

    _workflowOperationsInProgress.add(projectId);
    notifyListeners();

    try {
      final project = _projects.firstWhere((p) => p.id == projectId);
      await updateProject(project.copyWith(
        status: ProjectStatus.completed,
        progress: 100,
      ));

      // 通过 OpenClaw 汇报给 sakura
      if (_openclaw.isConnected) {
        await _openclaw.sendTaskToAgent(
          agentId: 'sakura',
          task: 'workflow_completed',
          context: {
            'projectId': project.id,
            'projectName': project.name,
            'status': 'success',
          },
        );
      }
    } finally {
      _workflowOperationsInProgress.remove(projectId);
      notifyListeners();
    }
  }

  /// 标记任务失败
  Future<void> failProject(String projectId, String reason) async {
    if (_workflowOperationsInProgress.contains(projectId)) {
      return;
    }

    _workflowOperationsInProgress.add(projectId);
    notifyListeners();

    try {
      final project = _projects.firstWhere((p) => p.id == projectId);
      await updateProject(project.copyWith(
        status: ProjectStatus.failed,
      ));

      // 通过 OpenClaw 汇报给 sakura
      if (_openclaw.isConnected) {
        await _openclaw.sendTaskToAgent(
          agentId: 'sakura',
          task: 'workflow_failed',
          context: {
            'projectId': project.id,
            'projectName': project.name,
            'reason': reason,
          },
        );
      }
    } finally {
      _workflowOperationsInProgress.remove(projectId);
      notifyListeners();
    }
  }

  /// 连接到 OpenClaw 网关
  Future<bool> connectToOpenClaw([String? url, String? token]) async {
    final result = await _openclaw.connect(url, token);
    if (result) {
      // 连接成功后获取 agent 状态
      await fetchAgentStatus();
    }
    notifyListeners();
    return result;
  }

  /// 断开 OpenClaw 连接
  void disconnectFromOpenClaw() {
    _openclaw.disconnect();
    _agentOnlineStatus = {};
    notifyListeners();
  }

  /// 配置飞书
  /// 返回验证结果：null 表示验证通过，String 表示错误信息
  Future<String?> configureFeishu({required String appId, required String appSecret}) async {
    // 先配置
    _feishu.configure(appId: appId, appSecret: appSecret);

    // 验证：尝试获取 token
    final token = await _feishu.getTenantAccessToken();
    if (token == null) {
      // 验证失败，清除配置
      _feishu.configure(appId: '', appSecret: '');
      notifyListeners();
      return '飞书配置验证失败：请检查 App ID 和 App Secret 是否正确';
    }

    notifyListeners();
    return null;
  }

  /// 验证飞书配置（不保存）
  /// 返回 null 表示验证通过，String 表示错误信息
  Future<String?> validateFeishu({required String appId, required String appSecret}) async {
    // 临时配置
    final tempService = FeishuService();
    tempService.configure(appId: appId, appSecret: appSecret);

    // 验证：尝试获取 token
    final token = await tempService.getTenantAccessToken();
    if (token == null) {
      return '验证失败：请检查 App ID 和 App Secret 是否正确';
    }

    return null;
  }

  /// 生成项目文件夹
  /// 返回生成的文件夹路径，失败返回 null
  Future<String?> generateProjectFolder(String projectId) async {
    try {
      final folderPath = await _storage.generateProjectFolder(projectId);

      _lastGeneratedFolderPath = folderPath;
      _lastFolderGenerationSuccess = true;
      notifyListeners();
      return folderPath;
    } catch (e) {
      _lastGeneratedFolderPath = null;
      _lastFolderGenerationSuccess = false;
      _error = '生成文件夹失败: $e';
      notifyListeners();
      return null;
    }
  }

  /// 获取项目文件夹路径
  Future<String?> getProjectFolderPath(String projectId) async {
    return await _storage.getProjectFolderPath(projectId);
  }

  /// 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
