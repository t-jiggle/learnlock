import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:learnlock/features/auth/providers/auth_provider.dart';
import 'package:learnlock/features/auth/providers/user_role_provider.dart';
import 'package:learnlock/features/auth/screens/login_screen.dart';
import 'package:learnlock/features/auth/screens/child_link_screen.dart';
import 'package:learnlock/features/parent/screens/child_qr_screen.dart';
import 'package:learnlock/features/child/screens/child_home_screen.dart';
import 'package:learnlock/features/child/screens/learning_session_screen.dart';
import 'package:learnlock/features/child/screens/reward_screen.dart';
import 'package:learnlock/features/parent/screens/parent_dashboard_screen.dart';
import 'package:learnlock/features/parent/screens/child_setup_screen.dart';
import 'package:learnlock/features/parent/screens/settings_screen.dart';
import 'package:learnlock/features/parent/screens/permissions_screen.dart';
import 'package:learnlock/models/child_profile.dart';
import 'package:learnlock/models/user_role.dart';

// ---------------------------------------------------------------------------
// RouterNotifier — bridges Riverpod state to GoRouter's refreshListenable.
// The GoRouter is created ONCE; this notifier tells it to re-run redirect
// when auth or role changes, without ever recreating the router object.
// ---------------------------------------------------------------------------

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    _ref.listen<AsyncValue>(authStateProvider, (_, __) => notifyListeners());
    _ref.listen<AsyncValue>(userRoleProvider, (_, __) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authStateProvider);
    final userRole = _ref.read(userRoleProvider);

    final isLoggedIn = authState.valueOrNull != null;
    final isLoading = authState.isLoading || userRole.isLoading;
    final onLoginPage = state.matchedLocation == '/login';
    final onChildLinkPage = state.matchedLocation == '/child-link';

    if (isLoading) return null;

    if (!isLoggedIn && !onLoginPage && !onChildLinkPage) return '/login';

    if (isLoggedIn && (onLoginPage || onChildLinkPage)) {
      final role = userRole.valueOrNull;
      if (role == UserRole.child) return '/child';
      if (role == UserRole.parent && onLoginPage) return '/parent';
      return null;
    }

    if (isLoggedIn && !onLoginPage) {
      final role = userRole.valueOrNull;
      if (role == UserRole.child &&
          state.matchedLocation.startsWith('/parent')) {
        return '/child';
      } else if (role == UserRole.parent &&
          (state.matchedLocation == '/child' ||
              state.matchedLocation.startsWith('/child/'))) {
        return '/parent';
      }
    }

    return null;
  }
}

final _routerNotifierProvider = Provider<_RouterNotifier>((ref) {
  return _RouterNotifier(ref);
});

// The router is created exactly once — never recreated on Firestore updates.
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.read(_routerNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/child-link',
        builder: (_, __) => const ChildLinkScreen(),
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
            path: 'child-qr',
            builder: (_, state) {
              final profile = state.extra as ChildProfile;
              return ChildQrScreen(child: profile);
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
              final subject = SubjectType.values
                  .byName(state.pathParameters['subject']!);
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
