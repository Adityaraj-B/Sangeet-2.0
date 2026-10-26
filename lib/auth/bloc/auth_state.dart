import 'package:equatable/equatable.dart';
import '../models/auth_user.dart';

enum AuthStatus {
  unauthenticated,
  submitting,
  authenticated,
  failure,
}

class AuthState extends Equatable {
  final String name;
  final String email;
  final String password;
  final bool isPasswordObscured;
  final bool isTermsAccepted;
  final AuthStatus status;
  final AuthUser? user;
  final String? toastMessage;
  final String? errorMessage;

  const AuthState({
    this.name = '',
    this.email = '',
    this.password = '',
    this.isPasswordObscured = true,
    this.isTermsAccepted = true,
    this.status = AuthStatus.unauthenticated,
    this.user,
    this.toastMessage,
    this.errorMessage,
  });

  bool get isLoginFormValid =>
      email.trim().isNotEmpty &&
      email.contains('@') &&
      password.trim().isNotEmpty;

  bool get isSignUpFormValid =>
      name.trim().isNotEmpty &&
      email.trim().isNotEmpty &&
      email.contains('@') &&
      password.length >= 8 &&
      isTermsAccepted;

  bool get isSubmitting => status == AuthStatus.submitting;

  int get passwordStrengthStage {
    if (password.length >= 12) return 3;
    if (password.length >= 8) return 2;
    return 1;
  }

  String get passwordStrengthLabel {
    if (password.length >= 12) return 'Acoustic Key: Pristine';
    if (password.length >= 8) return 'Acoustic Key: Balanced';
    return 'Acoustic Key Strength';
  }

  AuthState copyWith({
    String? name,
    String? email,
    String? password,
    bool? isPasswordObscured,
    bool? isTermsAccepted,
    AuthStatus? status,
    AuthUser? user,
    String? toastMessage,
    String? errorMessage,
    bool clearToast = false,
    bool clearError = false,
  }) {
    return AuthState(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      isPasswordObscured: isPasswordObscured ?? this.isPasswordObscured,
      isTermsAccepted: isTermsAccepted ?? this.isTermsAccepted,
      status: status ?? this.status,
      user: user ?? this.user,
      toastMessage: clearToast ? null : (toastMessage ?? this.toastMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        name,
        email,
        password,
        isPasswordObscured,
        isTermsAccepted,
        status,
        user,
        toastMessage,
        errorMessage,
      ];
}
