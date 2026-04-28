import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:workflow_app/models/project.dart';

/// 存储服务
/// 负责项目历史数据的本地存储
class StorageService {
  static const String _baseFolder = 'workflow_app';
  static const String _projectsFolder = 'projects';

  // Singleton
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  String? _basePath;

  /// 初始化存储服务
  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    _basePath = '${directory.path}/$_baseFolder';
    await Directory('$_basePath/$_projectsFolder').create(recursive: true);
  }

  /// 获取项目文件夹路径
  String get _projectsPath => '$_basePath/$_projectsFolder';

  /// 获取项目文件夹路径
  Future<String?> getProjectFolderPath(String projectId) async {
    if (_basePath == null) return null;
    return '$_projectsPath/$projectId';
  }

  /// 生成/重新生成项目文件夹结构
  /// 返回生成的文件夹路径
  Future<String> generateProjectFolder(String projectId) async {
    if (_basePath == null) {
      throw Exception('存储服务未初始化');
    }

    final projectPath = '$_projectsPath/$projectId';

    // 验证路径是否合法
    if (!_isValidPath(projectPath)) {
      throw Exception('无效的路径: $projectPath');
    }

    // 创建项目根文件夹
    await Directory(projectPath).create(recursive: true);
    // 创建子文件夹
    await Directory('$projectPath/code').create(recursive: true);
    await Directory('$projectPath/review').create(recursive: true);
    await Directory('$projectPath/chat').create(recursive: true);
    await Directory('$projectPath/design').create(recursive: true);

    return projectPath;
  }

  /// 验证路径是否合法
  bool _isValidPath(String path) {
    if (path.isEmpty) return false;

    // 检查是否包含非法字符
    final invalidChars = RegExp(r'[<>"|?*\x00-\x1f]');
    if (invalidChars.hasMatch(path)) {
      return false;
    }

    // 检查路径长度是否合理
    if (path.length > 260) {
      return false;
    }

    return true;
  }

  /// 创建项目
  Future<Project> createProject(Project project) async {
    final projectPath = '$_projectsPath/${project.id}';
    await Directory(projectPath).create(recursive: true);
    await Directory('$projectPath/code').create(recursive: true);
    await Directory('$projectPath/review').create(recursive: true);
    await Directory('$projectPath/chat').create(recursive: true);
    await Directory('$projectPath/design').create(recursive: true);

    await saveProject(project);
    return project;
  }

  /// 保存项目信息
  Future<void> saveProject(Project project) async {
    final file = File('$_projectsPath/${project.id}/project.json');
    await file.writeAsString(jsonEncode(project.toJson()));
  }

  /// 加载项目
  Future<Project?> loadProject(String projectId) async {
    try {
      final file = File('$_projectsPath/$projectId/project.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        return Project.fromJson(jsonDecode(content) as Map<String, dynamic>);
      }
    } catch (e) {
      // 加载失败，记录错误以便调试
      print('[StorageService] loadProject failed for $projectId: $e');
    }
    return null;
  }

  /// 加载所有项目
  Future<List<Project>> loadAllProjects() async {
    final projects = <Project>[];
    try {
      final directory = Directory(_projectsPath);
      if (await directory.exists()) {
        await for (final entity in directory.list()) {
          if (entity is Directory) {
            final projectId = entity.path.split(Platform.pathSeparator).last;
            final project = await loadProject(projectId);
            if (project != null) {
              projects.add(project);
            }
          }
        }
      }
    } catch (e) {
      // 加载失败，记录错误以便调试
      print('[StorageService] loadAllProjects failed: $e');
    }
    // 按更新时间倒序
    projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return projects;
  }

  /// 删除项目
  Future<void> deleteProject(String projectId) async {
    try {
      final directory = Directory('$_projectsPath/$projectId');
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    } catch (e) {
      print('[StorageService] deleteProject failed for $projectId: $e');
      rethrow;
    }
  }

  /// 保存代码产出
  Future<void> saveCodeOutput({
    required String projectId,
    required String filename,
    required String content,
  }) async {
    try {
      final file = File('$_projectsPath/$projectId/code/$filename');
      await file.parent.create(recursive: true);
      await file.writeAsString(content);
    } catch (e) {
      print('[StorageService] saveCodeOutput failed: $e');
      rethrow;
    }
  }

  /// 加载代码产出列表
  Future<List<String>> loadCodeOutputs(String projectId) async {
    try {
      final codePath = '$_projectsPath/$projectId/code';
      final directory = Directory(codePath);
      if (await directory.exists()) {
        final files = await directory.list().where((e) => e is File).toList();
        return files.map((f) => f.path.split(Platform.pathSeparator).last).toList();
      }
    } catch (e) {
      print('[StorageService] loadCodeOutputs failed for $projectId: $e');
    }
    return [];
  }

  /// 加载代码文件内容
  Future<String?> loadCodeFile(String projectId, String filename) async {
    try {
      final file = File('$_projectsPath/$projectId/code/$filename');
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      print('[StorageService] loadCodeFile failed: $e');
    }
    return null;
  }

  /// 保存审核结果
  Future<void> saveReviewResult({
    required String projectId,
    required String report,
    List<Map<String, dynamic>>? issues,
  }) async {
    try {
      final reportFile = File('$_projectsPath/$projectId/review/report.md');
      await reportFile.parent.create(recursive: true);
      await reportFile.writeAsString(report);

      if (issues != null) {
        final issuesFile = File('$_projectsPath/$projectId/review/issues.json');
        await issuesFile.writeAsString(jsonEncode(issues));
      }
    } catch (e) {
      print('[StorageService] saveReviewResult failed: $e');
      rethrow;
    }
  }

  /// 加载审核报告
  Future<String?> loadReviewReport(String projectId) async {
    try {
      final file = File('$_projectsPath/$projectId/review/report.md');
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      print('[StorageService] loadReviewReport failed for $projectId: $e');
    }
    return null;
  }

  /// 保存聊天记录
  Future<void> saveChatRecord({
    required String projectId,
    required String role,
    required String message,
  }) async {
    try {
      final file = File('$_projectsPath/$projectId/chat/full_conversation.md');
      await file.parent.create(recursive: true);
      final timestamp = DateTime.now().toIso8601String();
      final entry = '[$timestamp] $role: $message\n';
      await file.writeAsString(entry, mode: FileMode.append);
    } catch (e) {
      print('[StorageService] saveChatRecord failed: $e');
      rethrow;
    }
  }

  /// 加载完整聊天记录
  Future<String?> loadChatRecord(String projectId) async {
    try {
      final file = File('$_projectsPath/$projectId/chat/full_conversation.md');
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      print('[StorageService] loadChatRecord failed for $projectId: $e');
    }
    return null;
  }

  /// 保存 sakura 介入记录
  Future<void> saveSakuraIntervention({
    required String projectId,
    required String action,
    required String reason,
  }) async {
    try {
      final file = File('$_projectsPath/$projectId/chat/sakura_interventions.md');
      await file.parent.create(recursive: true);
      final timestamp = DateTime.now().toIso8601String();
      final entry = '[$timestamp] ACTION: $action\nREASON: $reason\n\n';
      await file.writeAsString(entry, mode: FileMode.append);
    } catch (e) {
      print('[StorageService] saveSakuraIntervention failed: $e');
      rethrow;
    }
  }

  /// 保存项目上下文
  Future<void> saveContext({
    required String projectId,
    required Map<String, dynamic> context,
  }) async {
    try {
      final file = File('$_projectsPath/$projectId/context.json');
      await file.writeAsString(jsonEncode(context));
    } catch (e) {
      print('[StorageService] saveContext failed: $e');
      rethrow;
    }
  }

  /// 加载项目上下文
  Future<Map<String, dynamic>?> loadContext(String projectId) async {
    try {
      final file = File('$_projectsPath/$projectId/context.json');
      if (await file.exists()) {
        return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      }
    } catch (e) {
      print('[StorageService] loadContext failed for $projectId: $e');
    }
    return null;
  }
}
