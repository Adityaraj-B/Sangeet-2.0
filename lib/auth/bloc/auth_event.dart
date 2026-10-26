import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthEmailChanged extends AuthEvent {
  final String email;
  const AuthEmailChanged(this.email);

  @override
  List<Object?> get props => [email];
}

class AuthPasswordChanged extends AuthEvent {
  final String password;
  const AuthPasswordChanged(this.password);

  @override
  List<Object?> get props => [password];
}

class AuthTogglePasswordVisibility extends AuthEvent {
  const AuthTogglePasswordVisibility();
}

class AuthLoginWithEmailSubmitted extends AuthEvent {
  const AuthLoginWithEmailSubmitted();
}

class AuthLoginWithGoogleSubmitted extends AuthEvent {
  const AuthLoginWithGoogleSubmitted();
}

class AuthForgotPasswordRequested extends AuthEvent {
  const AuthForgotPasswordRequested();
}

class AuthSignUpRequested extends AuthEvent {
  const AuthSignUpRequested();
}

class AuthNameChanged extends AuthEvent {
  final String name;
  const AuthNameChanged(this.name);

  @override
  List<Object?> get props => [name];
}

class AuthTermsToggled extends AuthEvent {
  final bool isAccepted;
  const AuthTermsToggled(this.isAccepted);

  @override
  List<Object?> get props => [isAccepted];
}

class AuthSignUpWithEmailSubmitted extends AuthEvent {
  const AuthSignUpWithEmailSubmitted();
}

class AuthClearToast extends AuthEvent {
  const AuthClearToast();
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

class AuthFirebaseUserChanged extends AuthEvent {
  final dynamic user;
  const AuthFirebaseUserChanged(this.user);

  @override
  List<Object?> get props => [user];
}
