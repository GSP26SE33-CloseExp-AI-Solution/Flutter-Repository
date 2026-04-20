import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/check_auth_status_usecase.dart';
import '../../domain/usecases/get_cached_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/refresh_token_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Auth BLoC - Presentation Layer
///
/// Handles authentication state management using the BLoC pattern.
/// Connects UI events to domain use cases.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final RefreshTokenUseCase _refreshTokenUseCase;
  final CheckAuthStatusUseCase _checkAuthStatusUseCase;
  final GetCachedUserUseCase _getCachedUserUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;

  AuthBloc({
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required RefreshTokenUseCase refreshTokenUseCase,
    required CheckAuthStatusUseCase checkAuthStatusUseCase,
    required GetCachedUserUseCase getCachedUserUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
  }) : _loginUseCase = loginUseCase,
       _logoutUseCase = logoutUseCase,
       _refreshTokenUseCase = refreshTokenUseCase,
       _checkAuthStatusUseCase = checkAuthStatusUseCase,
       _getCachedUserUseCase = getCachedUserUseCase,
       _updateProfileUseCase = updateProfileUseCase,
       super(const AuthInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
    on<SessionExpiredEvent>(_onSessionExpired);
    on<UpdateProfileEvent>(_onUpdateProfile);
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
        if (!isLoggedIn) {
          final refreshed = await _refreshTokenUseCase(const NoParams());
          if (refreshed.isLeft()) {
            emit(const AuthUnauthenticated());
            return;
          }
        }

        final userResult = await _getCachedUserUseCase(const NoParams());
        await userResult.fold(
          (failure) async {
            emit(const AuthUnauthenticated());
          },
          (user) async {
            // Enforce role/status and clear stale session if no longer valid.
            if (user.isDeliveryStaff && user.isActive) {
              emit(AuthAuthenticated(user: user));
              return;
            }

            await _logoutUseCase(const NoParams());
            emit(const AuthUnauthenticated());
          },
        );
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

  Future<void> _onSessionExpired(
    SessionExpiredEvent event,
    Emitter<AuthState> emit,
  ) async {
    await _logoutUseCase(const NoParams());
    emit(const AuthUnauthenticated());
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) {
      return;
    }

    emit(ProfileUpdateLoading(user: currentState.user));

    final result = await _updateProfileUseCase(
      UpdateProfileParams(
        fullName: event.fullName.trim(),
        phone: event.phone?.trim(),
      ),
    );

    result.fold(
      (failure) => emit(
        ProfileUpdateFailure(user: currentState.user, message: failure.message),
      ),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }
}
