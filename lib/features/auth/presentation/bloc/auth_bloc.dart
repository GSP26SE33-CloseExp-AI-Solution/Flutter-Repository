import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/check_auth_status_usecase.dart';
import '../../domain/usecases/get_cached_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Auth BLoC - Presentation Layer
///
/// Handles authentication state management using the BLoC pattern.
/// Connects UI events to domain use cases.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final CheckAuthStatusUseCase _checkAuthStatusUseCase;
  final GetCachedUserUseCase _getCachedUserUseCase;

  AuthBloc({
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required CheckAuthStatusUseCase checkAuthStatusUseCase,
    required GetCachedUserUseCase getCachedUserUseCase,
  }) : _loginUseCase = loginUseCase,
       _logoutUseCase = logoutUseCase,
       _checkAuthStatusUseCase = checkAuthStatusUseCase,
       _getCachedUserUseCase = getCachedUserUseCase,
       super(const AuthInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final isLoggedInResult = await _checkAuthStatusUseCase(const NoParams());

    await isLoggedInResult.fold(
      (failure) async {
        emit(const AuthUnauthenticated());
      },
      (isLoggedIn) async {
        if (isLoggedIn) {
          // Get cached user data
          final userResult = await _getCachedUserUseCase(const NoParams());
          userResult.fold((failure) => emit(const AuthUnauthenticated()), (
            user,
          ) {
            // Verify user is still a delivery staff
            if (user.isDeliveryStaff && user.isActive) {
              emit(AuthAuthenticated(user: user));
            } else {
              emit(const AuthUnauthenticated());
            }
          });
        } else {
          emit(const AuthUnauthenticated());
        }
      },
    );
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(const LoginLoading());

    final result = await _loginUseCase(
      LoginParams(email: event.email, password: event.password),
    );

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (authResult) => emit(AuthAuthenticated(user: authResult.user)),
    );
  }
  
  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(const LogoutLoading());

    final result = await _logoutUseCase(const NoParams());

    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(const AuthUnauthenticated()),
    );
  }
}
