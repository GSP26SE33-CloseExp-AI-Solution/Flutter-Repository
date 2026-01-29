import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'core/router/app_router.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'injection_container.dart';

/// Main entry point for CloseExp Delivery Staff App
///
/// Architecture: Clean Architecture with BLoC Pattern
///
/// Resources to learn more:
/// - Clean Architecture: https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html
/// - Flutter Clean Architecture: https://resocoder.com/flutter-clean-architecture-tdd/
/// - BLoC Pattern: https://bloclibrary.dev/
/// - GetIt (DI): https://pub.dev/packages/get_it
///
/// Project Structure:
/// lib/
/// ├── core/                    # Core utilities (network, error handling, constants)
/// │   ├── constants/           # API and app constants
/// │   ├── error/               # Failures and exceptions
/// │   ├── network/             # Dio client and network info
/// │   ├── router/              # App routing configuration
/// │   └── usecases/            # Base use case class
/// │
/// ├── features/                # Feature modules
/// │   ├── auth/                # Authentication feature
/// │   │   ├── data/            # Data layer (models, data sources, repositories impl)
/// │   │   ├── domain/          # Domain layer (entities, repositories, use cases)
/// │   │   └── presentation/    # Presentation layer (BLoC, pages, widgets)
/// │   │
/// │   └── home/                # Home feature (placeholder for delivery features)
/// │       └── presentation/
/// │
/// ├── injection_container.dart # Dependency injection setup
/// └── main.dart                # App entry point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
        routerConfig: router,
      ),
    );
  }
}
