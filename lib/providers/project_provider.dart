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

  // Workflow 操作进行中标志
  final Set<String> _workflowOperationsInProgress = {};

  // Getters
  List<Project> get projects => _projects;
  Project? get currentProject => _currentProject;
  bool get isLoading => _isLoading;
  String? get error => _error;

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
  Future<void> startWorkflow(String projectId) async {
    if (_workflowOperationsInProgress.contains(projectId)) {
      return;
    }

    _workflowOperationsInProgress.add(projectId);
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
        await _openclaw.sendTaskToAgent(
          agentId: 'code-designer',
          task: 'start_design',
          context: {
            'projectId': project.id,
            'projectName': project.name,
            'requirements': project.description ?? '',
          },
        );
      }
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
    notifyListeners();
    return result;
  }

  /// 断开 OpenClaw 连接
  void disconnectFromOpenClaw() {
    _openclaw.disconnect();
    notifyListeners();
  }

  /// 配置飞书
  void configureFeishu({required String appId, required String appSecret}) {
    _feishu.configure(appId: appId, appSecret: appSecret);
    notifyListeners();
  }

  /// 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
