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
import '../../features/delivery/presentation/pages/delivery_route_map_page.dart';
import '../../features/delivery/presentation/pages/delivery_stats_page.dart';
import '../../features/delivery/presentation/pages/my_deliveries_page.dart';
import '../../features/delivery/presentation/pages/order_details_page.dart';
import '../../features/home/presentation/pages/main_shell_page.dart';
import '../../features/notifications/presentation/pages/notification_thread_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
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

        // Main shell with bottom navigation (Protected)
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              MainShellPage(navigationShell: navigationShell),
          branches: [
            // Work: My deliveries (default tab at '/')
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: Routes.home,
                  name: 'tab-work',
                  builder: (context, state) => BlocProvider(
                    create: (_) => sl<DeliveryBloc>(),
                    child: const MyDeliveriesPage(),
                  ),
                ),
              ],
            ),
            // Orders: Available groups (accept orders)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: Routes.deliveryAvailable,
                  name: 'tab-orders',
                  builder: (context, state) => BlocProvider(
                    create: (_) => sl<DeliveryBloc>(),
                    child: const AvailableGroupsPage(),
                  ),
                ),
              ],
            ),
            // History
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: Routes.deliveryHistory,
                  name: 'tab-history',
                  builder: (context, state) => BlocProvider(
                    create: (_) => sl<DeliveryBloc>(),
                    child: const DeliveryHistoryPage(),
                  ),
                ),
              ],
            ),
            // Profile
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: Routes.profile,
                  name: 'tab-profile',
                  builder: (context, state) => const ProfilePage(),
                ),
              ],
            ),
          ],
        ),

        // ============== DELIVERY ROUTES ==============

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
            final groupId = state.uri.queryParameters['groupId'];
            final routeOrderRaw = state.uri.queryParameters['routeOrder'];
            List<String>? routeOrderedOrderIds;
            if (routeOrderRaw != null && routeOrderRaw.trim().isNotEmpty) {
              routeOrderedOrderIds = routeOrderRaw
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList(growable: false);
            }
            return BlocProvider(
              create: (_) => sl<DeliveryBloc>(),
              child: OrderDetailsPage(
                orderId: orderId,
                groupId: groupId,
                routeOrderedOrderIds: routeOrderedOrderIds,
              ),
            );
          },
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

        // Delivery Route Map (placeholder)
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: Routes.deliveryMap,
          name: 'delivery-map',
          pageBuilder: (context, state) {
            final groupId = state.uri.queryParameters['groupId'];
            return MaterialPage<void>(
              fullscreenDialog: true,
              child: BlocProvider(
                create: (_) => sl<DeliveryBloc>(),
                child: DeliveryRouteMapPage(groupId: groupId),
              ),
            );
          },
        ),

        // Notifications inbox
        GoRoute(
          path: Routes.notifications,
          name: 'notifications',
          builder: (context, state) => const NotificationsPage(),
        ),

        // Notification thread for specific order
        GoRoute(
          path: '${Routes.notificationsThread}/:orderId',
          name: 'notification-thread',
          builder: (context, state) {
            final orderId = state.pathParameters['orderId']!;
            final orderCode = state.extra as String?;
            return NotificationThreadPage(
              orderId: orderId,
              orderCode: orderCode,
            );
          },
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
  static const String profile = '/profile';

  // Delivery routes
  static const String deliveryAvailable = '/delivery/available';
  static const String deliveryGroup = '/delivery/group';
  static const String deliveryOrder = '/delivery/order';
  static const String deliveryHistory = '/delivery/history';
  static const String deliveryStats = '/delivery/stats';
  static const String deliveryMap = '/delivery/map';
  static const String notifications = '/notifications';
  static const String notificationsThread = '/notifications/thread';

  // Helper methods for parameterized routes
  static String deliveryGroupDetails(String groupId) =>
      '/delivery/group/$groupId';
  static String deliveryOrderDetails(
    String orderId, {
    String? groupId,
    List<String>? routeOrderedOrderIds,
  }) {
    final base = '/delivery/order/$orderId';
    final qp = <String>[];
    if (groupId != null && groupId.trim().isNotEmpty) {
      qp.add('groupId=${Uri.encodeComponent(groupId.trim())}');
    }
    if (routeOrderedOrderIds != null && routeOrderedOrderIds.isNotEmpty) {
      qp.add(
        'routeOrder=${Uri.encodeComponent(routeOrderedOrderIds.join(','))}',
      );
    }
    if (qp.isEmpty) return base;
    return '$base?${qp.join('&')}';
  }

  static String notificationThread(String orderId) =>
      '/notifications/thread/$orderId';
}

/// Refresh notifier for GoRouter to listen to AuthBloc changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> stream) {
    stream.listen((_) {
      notifyListeners();
    });
  }
}
