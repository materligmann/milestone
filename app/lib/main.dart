import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'features/auth/auth_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MilestoneApp()));
}

class MilestoneApp extends ConsumerStatefulWidget {
  const MilestoneApp({super.key});

  @override
  ConsumerState<MilestoneApp> createState() => _MilestoneAppState();
}

class _MilestoneAppState extends ConsumerState<MilestoneApp> {
  @override
  void initState() {
    super.initState();
    // Restore a previous session before the first frame renders a route.
    Future.microtask(() => ref.read(authControllerProvider.notifier).restore());
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Milestone',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      routerConfig: router,
    );
  }
}
