import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/auth_models.dart';
import '../features/auth/login_screen.dart';
import '../features/projects/project_detail_screen.dart';
import '../features/projects/projects_list_screen.dart';
import '../features/auth/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/projects',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final atLogin = state.matchedLocation == '/login';
      final atSplash = state.matchedLocation == '/splash';
      return switch (auth) {
        AuthUnknown() => atSplash ? null : '/splash',
        AuthSignedOut() => atLogin ? null : '/login',
        AuthSignedIn() => (atLogin || atSplash) ? '/projects' : null,
      };
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/projects',
        builder: (_, _) => const ProjectsListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) => ProjectDetailScreen(projectId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
});
