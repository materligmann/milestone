import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api_client.dart';
import 'models.dart';
import 'projects_providers.dart';

class ProjectDetailScreen extends ConsumerWidget {
  const ProjectDetailScreen({super.key, required this.projectId});
  final String projectId;

  void _toast(ScaffoldMessengerState messenger, Object e) {
    messenger.showSnackBar(SnackBar(content: Text(describeError(e))));
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Project project) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${project.name}?'),
        content: const Text('All phases, tasks and comments will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton.tonal(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(projectsListProvider.notifier).delete(project.id);
      if (context.mounted) context.go('/projects');
    } catch (e) {
      if (context.mounted) _toast(ScaffoldMessenger.of(context), e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(projectDetailProvider(projectId));
    final notifier = ref.read(projectDetailProvider(projectId).notifier);
    final messenger = ScaffoldMessenger.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/projects')),
        title: Text(detail.value?.name ?? ''),
        actions: [
          if (detail.value != null)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'delete') _confirmDelete(context, ref, detail.value!);
              },
              itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Delete project'))],
            ),
        ],
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(describeError(e), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                TextButton(onPressed: () => ref.invalidate(projectDetailProvider(projectId)), child: const Text('Try again')),
              ],
            ),
          ),
        ),
        data: (project) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            _Header(project: project),
            const SizedBox(height: 20),
            _SectionTitle('Phases'),
            const SizedBox(height: 8),
            for (final phase in project.phases) ...[
              _PhaseCard(
                phase: phase,
                onToggle: (task, done) => notifier.setTaskDone(task.id, done).catchError((Object e) => _toast(messenger, e)),
                onAdd: (title) => notifier.addTask(phase.id, title).catchError((Object e) => _toast(messenger, e)),
                onRemove: (task) => notifier.removeTask(task.id).catchError((Object e) => _toast(messenger, e)),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 12),
            _SectionTitle('Comments'),
            const SizedBox(height: 8),
            _Comments(
              comments: project.comments,
              onSend: (body) => notifier.addComment(body).catchError((Object e) => _toast(messenger, e)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.project});
  final Project project;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final percent = (project.progress * 100).round();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: project.progress,
                    strokeWidth: 7,
                    strokeCap: StrokeCap.round,
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
                  Center(child: Text('$percent%', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(project.clientName, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  if (project.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(project.description, style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    project.currentPhase == null
                        ? 'All phases complete'
                        : 'Now in ${project.currentPhase!.title} · ${project.doneTasks}/${project.totalTasks} tasks',
                    style: text.labelLarge?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhaseCard extends StatefulWidget {
  const _PhaseCard({required this.phase, required this.onToggle, required this.onAdd, required this.onRemove});
  final Phase phase;
  final void Function(Task task, bool done) onToggle;
  final void Function(String title) onAdd;
  final void Function(Task task) onRemove;

  @override
  State<_PhaseCard> createState() => _PhaseCardState();
}

class _PhaseCardState extends State<_PhaseCard> {
  late bool _expanded = widget.phase.status == PhaseStatus.active;
  final _newTask = TextEditingController();

  @override
  void dispose() {
    _newTask.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _newTask.text.trim();
    if (title.isEmpty) return;
    widget.onAdd(title);
    _newTask.clear();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final phase = widget.phase;
    final (icon, color) = switch (phase.status) {
      PhaseStatus.done => (Icons.check_circle_rounded, scheme.primary),
      PhaseStatus.active => (Icons.radio_button_checked_rounded, scheme.primary),
      PhaseStatus.pending => (Icons.radio_button_unchecked_rounded, scheme.outline),
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Row(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      phase.title,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: phase.status == PhaseStatus.pending ? scheme.onSurfaceVariant : scheme.onSurface,
                      ),
                    ),
                  ),
                  Text('${phase.doneCount}/${phase.tasks.length}', style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(width: 4),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: scheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.5)),
            for (final task in phase.tasks)
              Dismissible(
                key: ValueKey(task.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: scheme.errorContainer,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
                ),
                onDismissed: (_) => widget.onRemove(task),
                child: CheckboxListTile(
                  value: task.done,
                  onChanged: (v) => widget.onToggle(task, v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  title: Text(
                    task.title,
                    style: text.bodyMedium?.copyWith(
                      decoration: task.done ? TextDecoration.lineThrough : null,
                      color: task.done ? scheme.onSurfaceVariant : scheme.onSurface,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newTask,
                      onSubmitted: (_) => _submit(),
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        hintText: 'Add a task',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  IconButton(onPressed: _submit, icon: const Icon(Icons.add_circle_outline)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Comments extends StatefulWidget {
  const _Comments({required this.comments, required this.onSend});
  final List<Comment> comments;
  final Future<void> Function(String body) onSend;

  @override
  State<_Comments> createState() => _CommentsState();
}

class _CommentsState extends State<_Comments> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty) return;
    setState(() => _sending = true);
    await widget.onSend(body);
    if (mounted) {
      _controller.clear();
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final dateFormat = DateFormat.MMMd().add_Hm();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.comments.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text('No comments yet. Questions for the studio go here.', style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
              ),
            for (final comment in widget.comments)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(comment.authorName, style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(width: 8),
                        Text(dateFormat.format(comment.createdAt.toLocal()), style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(comment.body, style: text.bodyMedium),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(hintText: 'Write a comment'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
