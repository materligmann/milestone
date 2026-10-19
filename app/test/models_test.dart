import 'package:flutter_test/flutter_test.dart';
import 'package:milestone/features/projects/models.dart';

void main() {
  test('Project computes progress and current phase from its phases', () {
    final project = Project.fromJson({
      'id': 'p',
      'name': 'FitTrack',
      'clientName': 'Herbalife',
      'description': '',
      'status': 'active',
      'comments': [],
      'phases': [
        {
          'id': 'a',
          'key': 'discovery',
          'title': 'Discovery',
          'status': 'done',
          'tasks': [
            {'id': 't1', 'title': 'Kick-off', 'done': true},
          ],
        },
        {
          'id': 'b',
          'key': 'specification',
          'title': 'Specification',
          'status': 'active',
          'tasks': [
            {'id': 't2', 'title': 'Flows', 'done': false},
            {'id': 't3', 'title': 'Spec', 'done': true},
          ],
        },
      ],
    });

    expect(project.totalTasks, 3);
    expect(project.doneTasks, 2);
    expect(project.progress, closeTo(0.667, 0.001));
    expect(project.currentPhase?.title, 'Specification');
  });
}
