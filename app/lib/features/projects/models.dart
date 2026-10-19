enum PhaseStatus { pending, active, done }

PhaseStatus _phaseStatus(String raw) => PhaseStatus.values.firstWhere((s) => s.name == raw, orElse: () => PhaseStatus.pending);

class ProjectSummary {
  const ProjectSummary({
    required this.id,
    required this.name,
    required this.clientName,
    required this.description,
    required this.status,
    required this.progress,
    required this.doneTasks,
    required this.totalTasks,
    required this.currentPhaseTitle,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String clientName;
  final String description;
  final String status;
  final double progress;
  final int doneTasks;
  final int totalTasks;
  final String? currentPhaseTitle;
  final DateTime updatedAt;

  factory ProjectSummary.fromJson(Map<String, dynamic> json) => ProjectSummary(
        id: json['id'] as String,
        name: json['name'] as String,
        clientName: json['clientName'] as String,
        description: (json['description'] as String?) ?? '',
        status: json['status'] as String,
        progress: (json['progress'] as num).toDouble(),
        doneTasks: json['doneTasks'] as int,
        totalTasks: json['totalTasks'] as int,
        currentPhaseTitle: (json['currentPhase'] as Map<String, dynamic>?)?['title'] as String?,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

class Task {
  const Task({required this.id, required this.title, required this.done});
  final String id;
  final String title;
  final bool done;

  factory Task.fromJson(Map<String, dynamic> json) =>
      Task(id: json['id'] as String, title: json['title'] as String, done: json['done'] as bool);
}

class Phase {
  const Phase({required this.id, required this.key, required this.title, required this.status, required this.tasks});
  final String id;
  final String key;
  final String title;
  final PhaseStatus status;
  final List<Task> tasks;

  int get doneCount => tasks.where((t) => t.done).length;

  factory Phase.fromJson(Map<String, dynamic> json) => Phase(
        id: json['id'] as String,
        key: json['key'] as String,
        title: json['title'] as String,
        status: _phaseStatus(json['status'] as String),
        tasks: (json['tasks'] as List).cast<Map<String, dynamic>>().map(Task.fromJson).toList(),
      );
}

class Comment {
  const Comment({required this.id, required this.authorName, required this.body, required this.createdAt});
  final String id;
  final String authorName;
  final String body;
  final DateTime createdAt;

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
        id: json['id'] as String,
        authorName: json['authorName'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class Project {
  const Project({
    required this.id,
    required this.name,
    required this.clientName,
    required this.description,
    required this.status,
    required this.phases,
    required this.comments,
  });

  final String id;
  final String name;
  final String clientName;
  final String description;
  final String status;
  final List<Phase> phases;
  final List<Comment> comments;

  int get totalTasks => phases.fold(0, (n, p) => n + p.tasks.length);
  int get doneTasks => phases.fold(0, (n, p) => n + p.doneCount);
  double get progress => totalTasks == 0 ? 0 : doneTasks / totalTasks;
  Phase? get currentPhase => phases.where((p) => p.status == PhaseStatus.active).firstOrNull;

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String,
        name: json['name'] as String,
        clientName: json['clientName'] as String,
        description: (json['description'] as String?) ?? '',
        status: json['status'] as String,
        phases: (json['phases'] as List).cast<Map<String, dynamic>>().map(Phase.fromJson).toList(),
        comments: (json['comments'] as List? ?? const []).cast<Map<String, dynamic>>().map(Comment.fromJson).toList(),
      );
}
