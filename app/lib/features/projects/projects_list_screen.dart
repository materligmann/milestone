import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_models.dart';
import 'models.dart';
import 'new_project_sheet.dart';
import 'projects_providers.dart';

class ProjectsListScreen extends ConsumerWidget {
  const ProjectsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsListProvider);
    final auth = ref.watch(authControllerProvider);
    final userName = auth is AuthSignedIn && auth.user.name.isNotEmpty ? auth.user.name : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          PopupMenuButton<String>(
            icon: CircleAvatar(
              radius: 16,
              child: Text((userName ?? '?').characters.first.toUpperCase(), style: const TextStyle(fontSize: 14)),
            ),
            onSelected: (value) {
              if (value == 'signout') ref.read(authControllerProvider.notifier).signOut();
            },
            itemBuilder: (_) => [
              if (userName != null) PopupMenuItem(enabled: false, child: Text(userName)),
              const PopupMenuItem(value: 'signout', child: Text('Sign out')),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showNewProjectSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New project'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(projectsListProvider.notifier).refresh(),
        child: projects.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _Message(
            icon: Icons.cloud_off,
            title: 'Could not load projects',
            body: describeError(e),
            action: TextButton(onPressed: () => ref.invalidate(projectsListProvider), child: const Text('Try again')),
          ),
          data: (items) => items.isEmpty
              ? const _Message(
                  icon: Icons.flag_outlined,
                  title: 'No projects yet',
                  body: 'Create your first project and walk it from discovery to launch.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _ProjectCard(project: items[i]),
                ),
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project});
  final ProjectSummary project;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final percent = (project.progress * 100).round();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/projects/${project.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(project.name, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(project.clientName, style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  if (project.currentPhaseTitle != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        project.currentPhaseTitle!,
                        style: text.labelMedium?.copyWith(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(value: project.progress, minHeight: 8, backgroundColor: scheme.surfaceContainerHighest),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('$percent%', style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Text('${project.doneTasks} of ${project.totalTasks} tasks', style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, required this.body, this.action});
  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 80),
        Icon(icon, size: 56, color: scheme.onSurfaceVariant),
        const SizedBox(height: 16),
        Text(title, textAlign: TextAlign.center, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(body, textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
        if (action != null) ...[const SizedBox(height: 12), Center(child: action)],
      ],
    );
  }
}
