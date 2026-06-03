import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show
        debugPrint,
        defaultTargetPlatform,
        kDebugMode,
        kIsWeb,
        kReleaseMode,
        TargetPlatform;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:device_preview/device_preview.dart';
import 'core/constants/mapbox_config.dart';
import 'core/network/dio_client.dart';
import 'core/notifications/local_notification_service.dart';
import 'core/notifications/notification_incoming_tracker.dart';
import 'core/realtime/notification_realtime_service.dart';
import 'core/realtime/realtime_notification_payload.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/notifications/presentation/bloc/notifications_bloc.dart';
import 'features/notifications/presentation/bloc/notifications_event.dart';
import 'features/notifications/presentation/bloc/notifications_state.dart';
import 'injection_container.dart';

/// Skip DevicePreview on mobile; breaks Mapbox AndroidView. Web/desktop: enable via dart-define.
bool get _isMobileNative =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

bool get _enableDevicePreviewOnMobile {
  return const bool.fromEnvironment(
    'ENABLE_DEVICE_PREVIEW_ON_MOBILE',
    defaultValue: false,
  );
}

bool get _shouldWrapWithDevicePreview {
  if (kReleaseMode) return false;
  if (_isMobileNative) return _enableDevicePreviewOnMobile;
  if (kIsWeb) return true;
  return const bool.fromEnvironment(
    'ENABLE_DEVICE_PREVIEW',
    defaultValue: false,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MapboxConfig.initialize();
  if (MapboxConfig.isConfigured) {
    MapboxOptions.setAccessToken(MapboxConfig.accessToken);
  }
  if (kDebugMode) {
    // Helps distinguish token placeholder vs MapWidget branch (never log the token).
    debugPrint(
      'Mapbox: configured=${MapboxConfig.isConfigured} '
      'mapWidgetSupported=${MapboxConfig.isMapWidgetSupported}',
    );
  }

  // Initialize dependencies
  await initializeDependencies();
  await sl<LocalNotificationService>().initialize();

  const app = CloseExpDeliveryApp();
  if (_shouldWrapWithDevicePreview) {
    runApp(DevicePreview(enabled: !kReleaseMode, builder: (context) => app));
  } else {
    runApp(app);
  }
}

/// Root widget for CloseExp Delivery Staff App
class CloseExpDeliveryApp extends StatefulWidget {
  const CloseExpDeliveryApp({super.key});

  @override
  State<CloseExpDeliveryApp> createState() => _CloseExpDeliveryAppState();
}

class _CloseExpDeliveryAppState extends State<CloseExpDeliveryApp> {
  late final AuthBloc _authBloc;
  late final NotificationsBloc _notificationsBloc;
  late final NotificationRealtimeService _notificationRealtimeService;
  late final LocalNotificationService _localNotificationService;
  late final NotificationIncomingTracker _notificationIncomingTracker;
  late final GoRouter router;
  int _lastInvalidationTick = 0;
  String? _lastLocalNotificationId;
  DateTime? _lastLocalNotificationAt;
  StreamSubscription<AuthState>? _authStateSubscription;
  Timer? _notificationPollingTimer;

  @override
  void initState() {
    super.initState();
    _authBloc = sl<AuthBloc>();
    _notificationsBloc = sl<NotificationsBloc>();
    _notificationRealtimeService = sl<NotificationRealtimeService>();
    _localNotificationService = sl<LocalNotificationService>();
    _notificationIncomingTracker = sl<NotificationIncomingTracker>();
    router = AppRouter.createRouter(_authBloc);

    _localNotificationService.onNotificationTap = (_) {
      router.go(Routes.notifications);
    };
    _notificationRealtimeService.onNotificationReceived =
        _handleRealtimeNotification;

    DioClient.authSessionInvalidated.addListener(_onSessionInvalidated);

    _authStateSubscription = _authBloc.stream.listen(_handleAuthStateChange);
    _handleAuthStateChange(_authBloc.state);
  }

  void _onSessionInvalidated() {
    final tick = DioClient.authSessionInvalidated.value;
    if (tick == _lastInvalidationTick) {
      return;
    }

    _lastInvalidationTick = tick;
    if (!mounted) {
      return;
    }

    _authBloc.add(const SessionExpiredEvent());
  }

  void _handleRealtimeNotification(RealtimeNotificationPayload? payload) {
    if (mounted) {
      _notificationsBloc.add(const LoadMyNotifications(forceRefresh: true));
    }

    final effectivePayload =
        payload ??
        const RealtimeNotificationPayload(
          notificationId: 'generic',
          title: 'Thông báo mới',
          content: 'Bạn có cập nhật mới',
        );

    final now = DateTime.now();
    if (_lastLocalNotificationId == effectivePayload.notificationId &&
        _lastLocalNotificationAt != null &&
        now.difference(_lastLocalNotificationAt!) <
            const Duration(seconds: 5)) {
      return;
    }

    _lastLocalNotificationId = effectivePayload.notificationId;
    _lastLocalNotificationAt = now;

    unawaited(
      _localNotificationService.showFromRealtime(
        notificationId: effectivePayload.notificationId,
        title: effectivePayload.title,
        body: effectivePayload.content,
      ),
    );
  }

  void _onNotificationsStateChanged(NotificationsState state) {
    if (state is NotificationsSessionExpired) {
      _authBloc.add(const SessionExpiredEvent());
      return;
    }

    if (state is NotificationsListLoaded) {
      unawaited(_notificationIncomingTracker.onListLoaded(state.allItems));
    }
  }

  void _handleAuthStateChange(AuthState state) {
    if (state is AuthAuthenticated) {
      _notificationsBloc.add(const LoadMyNotifications(forceRefresh: true));
      unawaited(_localNotificationService.ensurePermissions());
      _startNotificationPolling();
      unawaited(_notificationRealtimeService.connect());
    } else {
      _stopNotificationPolling();
      _notificationIncomingTracker.reset();
      unawaited(_notificationRealtimeService.disconnect());
    }
  }

  void _startNotificationPolling() {
    _notificationPollingTimer?.cancel();
    _notificationPollingTimer = Timer.periodic(const Duration(seconds: 5), (
      _,
    ) {
      _notificationsBloc.add(const LoadMyNotifications());
    });
  }

  void _stopNotificationPolling() {
    _notificationPollingTimer?.cancel();
    _notificationPollingTimer = null;
  }

  @override
  void dispose() {
    DioClient.authSessionInvalidated.removeListener(_onSessionInvalidated);
    _authStateSubscription?.cancel();
    _stopNotificationPolling();
    unawaited(_notificationRealtimeService.disconnect());
    _notificationsBloc.close();
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<NotificationsBloc>.value(value: _notificationsBloc),
      ],
      child: BlocListener<NotificationsBloc, NotificationsState>(
        listener: (context, state) => _onNotificationsStateChanged(state),
        child: MaterialApp.router(
          // DevicePreview.appBuilder/locale có thể làm MapWidget trắng trên Android/iOS.
          locale: _shouldWrapWithDevicePreview
              ? DevicePreview.locale(context)
              : null,
          builder: (context, child) {
            if (_shouldWrapWithDevicePreview) {
              return DevicePreview.appBuilder(context, child);
            }
            return child ?? const SizedBox.shrink();
          },
          title: 'CloseExp Delivery',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
  }
}
