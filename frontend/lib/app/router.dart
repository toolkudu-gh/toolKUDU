import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/verify_email_screen.dart';
import '../features/auth/screens/magic_link_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/home/screens/toolbox_detail_screen.dart';
import '../features/home/screens/tool_detail_screen.dart';
import '../features/home/screens/add_toolbox_screen.dart';
import '../features/home/screens/add_tool_screen.dart';
import '../features/search/screens/search_screen.dart';
import '../features/search/screens/user_profile_screen.dart';
import '../features/share/screens/share_screen.dart';
import '../features/find_tool/screens/find_tool_screen.dart';
import '../features/find_tool/screens/add_tracker_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/profile/screens/buddies_screen.dart';
import '../features/profile/screens/settings_screen.dart';
import '../core/providers/auth_provider.dart';
import 'shell_screen.dart';

// Navigation keys for shell routes
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

// Auth notifier for router refresh
class AuthChangeNotifier extends ChangeNotifier {
  AuthChangeNotifier(this._ref) {
    _ref.listen(authStateProvider, (previous, next) {
      // Only notify when authentication status changes, not on every state change
      if (previous?.isAuthenticated != next.isAuthenticated) {
        notifyListeners();
      }
    });
  }
  final Ref _ref;

  bool get isAuthenticated => _ref.read(authStateProvider).isAuthenticated;
}

final authChangeNotifierProvider = Provider<AuthChangeNotifier>((ref) {
  return AuthChangeNotifier(ref);
});

// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authChangeNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    debugLogDiagnostics: true,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isLoggedIn = authNotifier.isAuthenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/magic-link' ||
          state.matchedLocation.startsWith('/verify-email');

      // If not logged in and not on auth routes, redirect to login
      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      // If logged in and on auth routes, redirect to home
      if (isLoggedIn && isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      // Auth routes (outside shell)
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        name: 'verify-email',
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return VerifyEmailScreen(email: email);
        },
      ),
      GoRoute(
        path: '/magic-link',
        name: 'magic-link',
        builder: (context, state) => const MagicLinkScreen(),
      ),

      // Main app shell with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          // Home Tab
          GoRoute(
            path: '/home',
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
            routes: [
              GoRoute(
                path: 'toolbox/:id',
                name: 'toolbox-detail',
                builder: (context, state) => ToolboxDetailScreen(
                  toolboxId: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: 'add-tool',
                    name: 'add-tool',
                    builder: (context, state) => AddToolScreen(
                      toolboxId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'tool/:toolId',
                    name: 'tool-detail',
                    builder: (context, state) => ToolDetailScreen(
                      toolId: state.pathParameters['toolId']!,
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'add-toolbox',
                name: 'add-toolbox',
                builder: (context, state) => const AddToolboxScreen(),
              ),
            ],
          ),

          // Search Tab
          GoRoute(
            path: '/search',
            name: 'search',
            pageBuilder: (context, state) {
              final borrowMode = state.uri.queryParameters['mode'] == 'borrow';
              return NoTransitionPage(
                child: SearchScreen(borrowMode: borrowMode),
              );
            },
            routes: [
              GoRoute(
                path: 'user/:id',
                name: 'user-profile',
                builder: (context, state) {
                  final borrowMode = state.uri.queryParameters['mode'] == 'borrow';
                  return UserProfileScreen(
                    userId: state.pathParameters['id']!,
                    borrowMode: borrowMode,
                  );
                },
              ),
            ],
          ),

          // Share Tab
          GoRoute(
            path: '/share',
            name: 'share',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ShareScreen(),
            ),
          ),

          // Find My Tool Tab
          GoRoute(
            path: '/find',
            name: 'find',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FindToolScreen(),
            ),
            routes: [
              GoRoute(
                path: 'add-tracker/:toolId',
                name: 'add-tracker',
                builder: (context, state) => AddTrackerScreen(
                  toolId: state.pathParameters['toolId']!,
                ),
              ),
            ],
          ),

          // Profile Tab
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
            routes: [
              GoRoute(
                path: 'edit',
                name: 'edit-profile',
                builder: (context, state) => const EditProfileScreen(),
              ),
              GoRoute(
                path: 'buddies',
                name: 'buddies',
                builder: (context, state) => const BuddiesScreen(),
              ),
              GoRoute(
                path: 'settings',
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(state.matchedLocation),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
