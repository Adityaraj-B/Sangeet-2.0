import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/firebase_service.dart';
import '../../repositories/favorites_repository.dart';
import '../../repositories/history_repository.dart';
import '../../insights/services/insight_service.dart';
import '../models/auth_user.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseService _firebaseService = FirebaseService.instance;
  late final StreamSubscription<User?> _authSubscription;

  AuthBloc() : super(_initialAuthState()) {
    on<AuthEmailChanged>(_onEmailChanged);
    on<AuthPasswordChanged>(_onPasswordChanged);
    on<AuthNameChanged>(_onNameChanged);
    on<AuthTermsToggled>(_onTermsToggled);
    on<AuthTogglePasswordVisibility>(_onTogglePasswordVisibility);
    on<AuthLoginWithEmailSubmitted>(_onLoginWithEmailSubmitted);
    on<AuthLoginWithGoogleSubmitted>(_onLoginWithGoogleSubmitted);
    on<AuthSignUpWithEmailSubmitted>(_onSignUpWithEmailSubmitted);
    on<AuthForgotPasswordRequested>(_onForgotPasswordRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthClearToast>(_onClearToast);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthFirebaseUserChanged>(_onFirebaseUserChanged);

    _authSubscription = _firebaseService.authStateChanges.listen((user) {
      add(AuthFirebaseUserChanged(user));
    });
  }

  static AuthState _initialAuthState() {
    final currentFirebaseUser = FirebaseAuth.instance.currentUser;
    if (currentFirebaseUser != null) {
      return AuthState(
        status: AuthStatus.authenticated,
        user: AuthUser.fromFirebaseUser(currentFirebaseUser),
        toastMessage: 'Session restored.',
      );
    }
    return const AuthState();
  }

  void _onNameChanged(AuthNameChanged event, Emitter<AuthState> emit) {
    emit(state.copyWith(
      name: event.name,
      clearError: true,
      clearToast: true,
    ));
  }

  void _onTermsToggled(AuthTermsToggled event, Emitter<AuthState> emit) {
    emit(state.copyWith(isTermsAccepted: event.isAccepted));
  }

  void _onEmailChanged(AuthEmailChanged event, Emitter<AuthState> emit) {
    emit(state.copyWith(
      email: event.email,
      clearError: true,
      clearToast: true,
    ));
  }

  void _onPasswordChanged(AuthPasswordChanged event, Emitter<AuthState> emit) {
    emit(state.copyWith(
      password: event.password,
      clearError: true,
      clearToast: true,
    ));
  }

  void _onTogglePasswordVisibility(
    AuthTogglePasswordVisibility event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(isPasswordObscured: !state.isPasswordObscured));
  }

  Future<void> _onLoginWithEmailSubmitted(
    AuthLoginWithEmailSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    if (state.isSubmitting) return;

    final trimmedEmail = state.email.trim();
    if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'Please enter a valid email address',
        toastMessage: 'Invalid credentials format',
      ));
      return;
    }

    if (state.password.isEmpty) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'Password is required',
        toastMessage: 'Password cannot be empty',
      ));
      return;
    }

    emit(state.copyWith(
      status: AuthStatus.submitting,
      toastMessage: 'Verifying credentials with Firebase...',
      clearError: true,
    ));

    try {
      final cred = await _firebaseService.signInWithEmail(
        email: trimmedEmail,
        password: state.password,
      );

      final user = AuthUser.fromFirebaseUser(cred.user!);

      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        toastMessage: 'Welcome to your soundstage, ${user.displayName}.',
      ));
    } on FirebaseAuthException catch (e) {
      final friendlyMsg = _formatAuthError(e);
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: friendlyMsg,
        toastMessage: friendlyMsg,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'Authentication error: ${e.toString()}',
        toastMessage: 'Authentication failed. Please retry.',
      ));
    }
  }

  Future<void> _onLoginWithGoogleSubmitted(
    AuthLoginWithGoogleSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    if (state.isSubmitting) return;

    emit(state.copyWith(
      status: AuthStatus.submitting,
      toastMessage: 'Connecting to Google...',
      clearError: true,
    ));

    try {
      final cred = await _firebaseService.signInWithGoogle();

      if (cred == null || cred.user == null) {
        // User dismissed the account picker
        emit(state.copyWith(
          status: AuthStatus.unauthenticated,
          clearToast: true,
          clearError: true,
        ));
        return;
      }

      final user = AuthUser.fromFirebaseUser(cred.user!);

      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        toastMessage: 'Welcome back, ${user.displayName}.',
      ));
    } on FirebaseAuthException catch (e) {
      final friendlyMsg = _formatAuthError(e);
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: friendlyMsg,
        toastMessage: friendlyMsg,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'Google Sign-In failed',
        toastMessage: 'Google Sign-In was cancelled or failed.',
      ));
    }
  }

  Future<void> _onSignUpWithEmailSubmitted(
    AuthSignUpWithEmailSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    if (state.isSubmitting) return;

    final trimmedName = state.name.trim();
    final trimmedEmail = state.email.trim();
    if (trimmedName.isEmpty) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'Full name is required',
        toastMessage: 'Please provide your full name',
      ));
      return;
    }

    if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'Please enter a valid email address',
        toastMessage: 'Invalid credentials format',
      ));
      return;
    }

    if (state.password.length < 8) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'Password must be at least 8 characters',
        toastMessage: 'Password must be at least 8 characters',
      ));
      return;
    }

    if (!state.isTermsAccepted) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'Please accept the Terms of Service to join',
        toastMessage: 'Please agree to terms to continue',
      ));
      return;
    }

    emit(state.copyWith(
      status: AuthStatus.submitting,
      toastMessage: 'Creating your Firebase Atelier account...',
      clearError: true,
    ));

    try {
      final cred = await _firebaseService.signUpWithEmail(
        email: trimmedEmail,
        password: state.password,
        displayName: trimmedName,
      );

      final user = AuthUser.fromFirebaseUser(cred.user!);

      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        toastMessage: 'Welcome to the Aura Atelier, ${user.displayName}.',
      ));
    } on FirebaseAuthException catch (e) {
      final friendlyMsg = _formatAuthError(e);
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: friendlyMsg,
        toastMessage: friendlyMsg,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'Sign up failed: ${e.toString()}',
        toastMessage: 'Unable to create account. Please retry.',
      ));
    }
  }

  Future<void> _onForgotPasswordRequested(
    AuthForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    final trimmedEmail = state.email.trim();
    if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
      emit(state.copyWith(
        toastMessage: 'Enter your email above to receive a reset link.',
      ));
      return;
    }

    try {
      await _firebaseService.sendPasswordReset(trimmedEmail);
      emit(state.copyWith(
        toastMessage: 'Password reset link sent to $trimmedEmail.',
      ));
    } on FirebaseAuthException catch (e) {
      emit(state.copyWith(
        toastMessage: _formatAuthError(e),
      ));
    } catch (_) {
      emit(state.copyWith(
        toastMessage: 'Could not send reset link. Please check email.',
      ));
    }
  }

  void _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(
      toastMessage: 'Redirecting to Atelier registration...',
    ));
  }

  void _onClearToast(
    AuthClearToast event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(clearToast: true));
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    FavoritesRepository.instance.clearLocalSession();
    HistoryRepository.instance.clearLocalSession();
    ListeningInsightsService.instance.clearLocalSession();
    await _firebaseService.signOut();
    emit(const AuthState(
      status: AuthStatus.unauthenticated,
      toastMessage: 'Soundstage session locked',
    ));
  }

  String _formatAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No listener found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password must be at least 8 characters.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This account has been suspended.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment.';
      case 'network-request-failed':
        return 'Network issue. Check your connection.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }

  void _onFirebaseUserChanged(
    AuthFirebaseUserChanged event,
    Emitter<AuthState> emit,
  ) {
    final user = event.user;
    if (user is User) {
      if (state.status != AuthStatus.authenticated || state.user?.id != user.uid) {
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          user: AuthUser.fromFirebaseUser(user),
          clearError: true,
        ));
      }
    } else if (user == null) {
      if (state.status == AuthStatus.authenticated) {
        emit(const AuthState(
          status: AuthStatus.unauthenticated,
        ));
      }
    }
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}
