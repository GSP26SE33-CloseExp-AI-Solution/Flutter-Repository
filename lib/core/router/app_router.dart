import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/delivery/presentation/bloc/delivery_bloc.dart';
import '../../features/delivery/presentation/pages/available_groups_page.dart';
import '../../features/delivery/presentation/pages/delivery_group_details_page.dart';
import '../../features/delivery/presentation/pages/delivery_history_page.dart';
import '../../features/delivery/presentation/pages/delivery_stats_page.dart';
import '../../features/delivery/presentation/pages/my_deliveries_page.dart';
import '../../features/delivery/presentation/pages/order_details_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../injection_container.dart';

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

        // ============== DELIVERY ROUTES ==============

        // Available Groups
        GoRoute(
          path: Routes.deliveryAvailable,
          name: 'available-groups',
          builder: (context, state) => BlocProvider(
            create: (_) => sl<DeliveryBloc>(),
            child: const AvailableGroupsPage(),
          ),
        ),

        // My Deliveries
        GoRoute(
          path: Routes.deliveryMy,
          name: 'my-deliveries',
          builder: (context, state) => BlocProvider(
            create: (_) => sl<DeliveryBloc>(),
            child: const MyDeliveriesPage(),
          ),
        ),

        // Delivery Group Details
        GoRoute(
          path: '${Routes.deliveryGroup}/:groupId',
          name: 'delivery-group-details',
          builder: (context, state) {
            final groupId = state.pathParameters['groupId']!;
            return BlocProvider(
              create: (_) => sl<DeliveryBloc>(),
              child: DeliveryGroupDetailsPage(groupId: groupId),
            );
          },
        ),

        // Order Details
        GoRoute(
          path: '${Routes.deliveryOrder}/:orderId',
          name: 'order-details',
          builder: (context, state) {
            final orderId = state.pathParameters['orderId']!;
            return BlocProvider(
              create: (_) => sl<DeliveryBloc>(),
              child: OrderDetailsPage(orderId: orderId),
            );
          },
        ),

        // Delivery History
        GoRoute(
          path: Routes.deliveryHistory,
          name: 'delivery-history',
          builder: (context, state) => BlocProvider(
            create: (_) => sl<DeliveryBloc>(),
            child: const DeliveryHistoryPage(),
          ),
        ),

        // Delivery Stats
        GoRoute(
          path: Routes.deliveryStats,
          name: 'delivery-stats',
          builder: (context, state) => BlocProvider(
            create: (_) => sl<DeliveryBloc>(),
            child: const DeliveryStatsPage(),
          ),
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

  // Delivery routes
  static const String deliveryAvailable = '/delivery/available';
  static const String deliveryMy = '/delivery/my';
  static const String deliveryGroup = '/delivery/group';
  static const String deliveryOrder = '/delivery/order';
  static const String deliveryHistory = '/delivery/history';
  static const String deliveryStats = '/delivery/stats';

  // Helper methods for parameterized routes
  static String deliveryGroupDetails(String groupId) =>
      '/delivery/group/$groupId';
  static String deliveryOrderDetails(String orderId) =>
      '/delivery/order/$orderId';
}

/// Refresh notifier for GoRouter to listen to AuthBloc changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> stream) {
    stream.listen((_) {
      notifyListeners();
    });
  }
}
