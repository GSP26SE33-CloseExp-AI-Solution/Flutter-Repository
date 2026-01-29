import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/home/presentation/pages/home_page.dart';

/// App Router Configuration
///
/// Uses GoRouter for declarative routing with authentication-based redirects.
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  /// Create the router with AuthBloc for redirect logic
  static GoRouter createRouter(AuthBloc authBloc) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: Routes.splash,
      debugLogDiagnostics: true,
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) {
        final authState = authBloc.state;
        final isOnSplash = state.matchedLocation == Routes.splash;
        final isOnLogin = state.matchedLocation == Routes.login;

        // Still loading - stay on splash
        if (authState is AuthInitial || authState is AuthLoading) {
          return isOnSplash ? null : Routes.splash;
        }

        // Authenticated - redirect to home if on splash/login
        if (authState is AuthAuthenticated) {
          if (isOnSplash || isOnLogin) {
            return Routes.home;
          }
          return null;
        }

        // Not authenticated - redirect to login
        if (authState is AuthUnauthenticated || authState is AuthError) {
          if (!isOnLogin) {
            return Routes.login;
          }
          return null;
        }

        // LoginLoading - stay on login page
        if (authState is LoginLoading) {
          return null;
        }

        return null;
      },
      routes: [
        // Splash Screen
        GoRoute(
          path: Routes.splash,
          name: 'splash',
          builder: (context, state) => const SplashPage(),
        ),

        // Login Screen
        GoRoute(
          path: Routes.login,
          name: 'login',
          builder: (context, state) => const LoginPage(),
        ),

        // Home Screen (Protected)
        GoRoute(
          path: Routes.home,
          name: 'home',
          builder: (context, state) => const HomePage(),
        ),
      ],
    );
  }
}

/// Route paths
class Routes {
  Routes._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String home = '/';
}

/// Refresh notifier for GoRouter to listen to AuthBloc changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> stream) {
    stream.listen((_) {
      notifyListeners();
    });
  }
}
