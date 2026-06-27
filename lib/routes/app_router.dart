import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_notifier.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/child_link/link_child_screen.dart';
import '../features/home/home_shell.dart';
import '../features/screen_time/screen_time_screen.dart';
import '../features/activity/activity_screen.dart';
import '../features/progress/progress_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/inbox/inbox_screen.dart';
import '../features/supporters/supporters_wall_screen.dart';

abstract final class AppRoutes {
  static const login          = '/login';
  static const register       = '/register';
  static const home           = '/home';
  static const linkChild      = '/home/link-child';
  static const screenTime     = '/home/screen-time';
  static const activity       = '/home/activity';
  static const progress       = '/home/progress';
  static const settings       = '/home/settings';
  static const inbox          = '/home/inbox';
  static const supportersWall = '/home/supporters-wall';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    redirect: (context, state) {
      final isAuth    = authState == AuthStatus.authenticated;
      final isLoading = authState == AuthStatus.loading;
      final loc       = state.uri.path;

      if (isLoading) return null;
      if (!isAuth && loc != AppRoutes.login && loc != AppRoutes.register) {
        return AppRoutes.login;
      }
      if (isAuth && (loc == AppRoutes.login || loc == AppRoutes.register)) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.login,    builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterScreen()),

      // ── Authenticated shell (Children + Rewards tabs) ────────────────
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const HomeShell(),
        routes: [
          GoRoute(path: 'link-child',   builder: (_, __) => const LinkChildScreen()),
          GoRoute(
            path: 'screen-time',
            builder: (_, state) =>
                ScreenTimeScreen(childId: state.extra as String? ?? ''),
          ),
          GoRoute(
            path: 'activity',
            builder: (_, state) =>
                ActivityScreen(childId: state.extra as String? ?? ''),
          ),
          GoRoute(
            path: 'progress',
            builder: (_, state) =>
                ProgressScreen(childId: state.extra as String? ?? ''),
          ),
          GoRoute(path: 'settings',         builder: (_, __) => const SettingsScreen()),
          GoRoute(path: 'inbox',            builder: (_, __) => const InboxScreen()),
          GoRoute(path: 'supporters-wall',  builder: (_, __) => const SupportersWallScreen()),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri.path}')),
    ),
  );
});
