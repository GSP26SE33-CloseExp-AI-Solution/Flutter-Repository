import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'core/constants/mapbox_config.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (MapboxConfig.isConfigured) {
    MapboxOptions.setAccessToken(MapboxConfig.accessToken);
  }

  // Initialize dependencies
  await initializeDependencies();

  runApp(const CloseExpDeliveryApp());
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
        title: 'CloseExp Delivery',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    );
  }
}
