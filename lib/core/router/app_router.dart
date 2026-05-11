import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:learnlock/features/auth/providers/auth_provider.dart';
import 'package:learnlock/features/auth/screens/login_screen.dart';
import 'package:learnlock/features/child/screens/child_home_screen.dart';
import 'package:learnlock/features/child/screens/learning_session_screen.dart';
import 'package:learnlock/features/child/screens/reward_screen.dart';
import 'package:learnlock/features/parent/screens/parent_dashboard_screen.dart';
import 'package:learnlock/features/parent/screens/child_setup_screen.dart';
import 'package:learnlock/features/parent/screens/settings_screen.dart';
import 'package:learnlock/features/parent/screens/permissions_screen.dart';
import 'package:learnlock/models/child_profile.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isLoading = authState.isLoading;
      final onLoginPage = state.matchedLocation == '/login';

      if (isLoading) return null;
      if (!isLoggedIn && !onLoginPage) return '/login';
      if (isLoggedIn && onLoginPage) return '/parent';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/parent',
        builder: (_, __) => const ParentDashboardScreen(),
        routes: [
          GoRoute(
            path: 'setup',
            builder: (_, state) {
              final child = state.extra as ChildProfile?;
              return ChildSetupScreen(existing: child);
            },
          ),
          GoRoute(
            path: 'settings',
            builder: (_, __) => const SettingsScreen(),
          ),
          GoRoute(
            path: 'permissions',
            builder: (_, __) => const PermissionsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/child',
        builder: (_, __) => const ChildHomeScreen(),
        routes: [
          GoRoute(
            path: 'learn/:subject',
            builder: (_, state) {
              final subject = SubjectType.values.byName(state.pathParameters['subject']!);
              return LearningSessionScreen(subject: subject);
            },
          ),
          GoRoute(
            path: 'reward',
            builder: (_, __) => const RewardScreen(),
          ),
        ],
      ),
    ],
  );
});
