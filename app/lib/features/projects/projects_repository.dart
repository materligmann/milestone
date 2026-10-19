import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import 'models.dart';

final projectsRepositoryProvider = Provider<ProjectsRepository>((ref) => ProjectsRepository(ref.watch(dioProvider)));

class ProjectsRepository {
  ProjectsRepository(this._dio);
  final Dio _dio;

  Future<List<ProjectSummary>> list() async {
    final res = await _dio.get<List<dynamic>>('/projects');
    return res.data!.cast<Map<String, dynamic>>().map(ProjectSummary.fromJson).toList();
  }

  Future<Project> get(String id) async {
    final res = await _dio.get<Map<String, dynamic>>('/projects/$id');
    return Project.fromJson(res.data!);
  }

  Future<Project> create({required String name, required String clientName, String description = ''}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/projects',
      data: {'name': name, 'clientName': clientName, if (description.isNotEmpty) 'description': description},
    );
    return Project.fromJson(res.data!);
  }

  Future<void> delete(String id) => _dio.delete<void>('/projects/$id');

  Future<Project> setTaskDone(String projectId, String taskId, bool done) async {
    final res = await _dio.patch<Map<String, dynamic>>('/projects/$projectId/tasks/$taskId', data: {'done': done});
    return Project.fromJson(res.data!);
  }

  Future<Project> addTask(String projectId, String phaseId, String title) async {
    final res = await _dio.post<Map<String, dynamic>>('/projects/$projectId/phases/$phaseId/tasks', data: {'title': title});
    return Project.fromJson(res.data!);
  }

  Future<Project> removeTask(String projectId, String taskId) async {
    final res = await _dio.delete<Map<String, dynamic>>('/projects/$projectId/tasks/$taskId');
    return Project.fromJson(res.data!);
  }

  Future<Comment> addComment(String projectId, String body) async {
    final res = await _dio.post<Map<String, dynamic>>('/projects/$projectId/comments', data: {'body': body});
    return Comment.fromJson(res.data!);
  }
}
