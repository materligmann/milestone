import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';
import 'projects_repository.dart';

final projectsListProvider = AsyncNotifierProvider<ProjectsListNotifier, List<ProjectSummary>>(ProjectsListNotifier.new);

class ProjectsListNotifier extends AsyncNotifier<List<ProjectSummary>> {
  @override
  Future<List<ProjectSummary>> build() => ref.watch(projectsRepositoryProvider).list();

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => ref.read(projectsRepositoryProvider).list());
  }

  Future<Project> create({required String name, required String clientName, String description = ''}) async {
    final project = await ref.read(projectsRepositoryProvider).create(name: name, clientName: clientName, description: description);
    await refresh();
    return project;
  }

  Future<void> delete(String id) async {
    await ref.read(projectsRepositoryProvider).delete(id);
    await refresh();
  }
}

final projectDetailProvider = AsyncNotifierProvider.family<ProjectDetailNotifier, Project, String>(ProjectDetailNotifier.new);

class ProjectDetailNotifier extends AsyncNotifier<Project> {
  ProjectDetailNotifier(this.projectId);
  final String projectId;

  @override
  Future<Project> build() => ref.watch(projectsRepositoryProvider).get(projectId);

  Future<void> _apply(Future<Project> Function(ProjectsRepository repo) change) async {
    final previous = state;
    try {
      final updated = await change(ref.read(projectsRepositoryProvider));
      state = AsyncData(updated);
      ref.invalidate(projectsListProvider);
    } catch (e, st) {
      state = previous;
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> setTaskDone(String taskId, bool done) {
    // Optimistic flip so the checkbox answers immediately.
    final current = state.value;
    if (current != null) {
      state = AsyncData(
        Project(
          id: current.id,
          name: current.name,
          clientName: current.clientName,
          description: current.description,
          status: current.status,
          comments: current.comments,
          phases: [
            for (final phase in current.phases)
              Phase(
                id: phase.id,
                key: phase.key,
                title: phase.title,
                status: phase.status,
                tasks: [
                  for (final task in phase.tasks)
                    task.id == taskId ? Task(id: task.id, title: task.title, done: done) : task,
                ],
              ),
          ],
        ),
      );
    }
    return _apply((repo) => repo.setTaskDone(projectId, taskId, done));
  }

  Future<void> addTask(String phaseId, String title) => _apply((repo) => repo.addTask(projectId, phaseId, title));

  Future<void> removeTask(String taskId) => _apply((repo) => repo.removeTask(projectId, taskId));

  Future<void> addComment(String body) async {
    await ref.read(projectsRepositoryProvider).addComment(projectId, body);
    await _apply((repo) => repo.get(projectId));
  }
}
