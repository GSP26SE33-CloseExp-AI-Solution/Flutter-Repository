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
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'injection_container.dart';

/// DevicePreview wraps the app in ClipRRect / animated layout that breaks Mapbox
/// AndroidView compositing (white map). Skip on Android and iOS; keep on web;
/// on desktop use `--dart-define=ENABLE_DEVICE_PREVIEW=true` if needed.
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
  late final GoRouter router;

  @override
  void initState() {
    super.initState();
    _authBloc = sl<AuthBloc>();
    router = AppRouter.createRouter(_authBloc);
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider<AuthBloc>.value(value: _authBloc)],
      child: MaterialApp.router(
        // [DevicePreview.appBuilder] + locale can break Mapbox [MapWidget] surface on
        // Android/iOS (white/blank frame) even when outer [DevicePreview] is skipped.
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
    );
  }
}
