import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:milestone/main.dart';

/// Drives the real app against the API set by --dart-define=API_URL:
/// demo sign-in, project list, project detail, sign out.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpUntil(WidgetTester tester, Finder finder, {Duration timeout = const Duration(seconds: 30)}) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 250));
      if (finder.evaluate().isNotEmpty) return;
    }
    throw TestFailure('Timed out waiting for $finder');
  }

  testWidgets('demo account walks from login to a project and back out', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MilestoneApp()));

    // A previous run may have left a session; sign out first if we land on the list.
    await pumpUntil(tester, find.byType(Scaffold));
    await tester.pump(const Duration(seconds: 2));
    if (find.text('Projects').evaluate().isNotEmpty) {
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out'));
    }

    await pumpUntil(tester, find.text('Explore the demo account'));
    await tester.tap(find.text('Explore the demo account'));

    await pumpUntil(tester, find.text('FitTrack'));
    expect(find.text('GetKey'), findsOneWidget);
    expect(find.text('Herbalife Israel'), findsOneWidget);

    await tester.tap(find.text('FitTrack'));
    await pumpUntil(tester, find.text('Phases'));
    expect(find.text('Discovery'), findsOneWidget);
    expect(find.text('Launch'), findsOneWidget);
    expect(find.textContaining('Now in'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await pumpUntil(tester, find.text('GetKey'));

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await pumpUntil(tester, find.text('Explore the demo account'));
  });
}
