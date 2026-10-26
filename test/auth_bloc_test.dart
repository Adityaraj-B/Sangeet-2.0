import 'package:flutter_test/flutter_test.dart';
import 'package:sangeet/auth/auth.dart';

void main() {
  group('AuthBloc Unit Tests', () {
    late AuthBloc authBloc;

    setUp(() {
      authBloc = AuthBloc();
    });

    tearDown(() {
      authBloc.close();
    });

    test('initial state has default unauthenticated values', () {
      expect(authBloc.state.status, equals(AuthStatus.unauthenticated));
      expect(authBloc.state.email, isEmpty);
      expect(authBloc.state.password, isEmpty);
      expect(authBloc.state.isPasswordObscured, isTrue);
      expect(authBloc.state.user, isNull);
    });

    test('AuthEmailChanged updates email and clears errors', () {
      authBloc.add(const AuthEmailChanged('client@aura.audio'));
      expectLater(
        authBloc.stream,
        emits(predicate<AuthState>((s) => s.email == 'client@aura.audio')),
      );
    });

    test('AuthPasswordChanged updates password', () {
      authBloc.add(const AuthPasswordChanged('secret123'));
      expectLater(
        authBloc.stream,
        emits(predicate<AuthState>((s) => s.password == 'secret123')),
      );
    });

    test('AuthTogglePasswordVisibility toggles obscure flag', () {
      expect(authBloc.state.isPasswordObscured, isTrue);
      authBloc.add(const AuthTogglePasswordVisibility());
      expectLater(
        authBloc.stream,
        emits(predicate<AuthState>((s) => s.isPasswordObscured == false)),
      );
    });

    test('AuthLoginWithEmailSubmitted rejects invalid email', () async {
      authBloc.add(const AuthEmailChanged('not-an-email'));
      authBloc.add(const AuthPasswordChanged('pass'));
      authBloc.add(const AuthLoginWithEmailSubmitted());

      await expectLater(
        authBloc.stream,
        emitsThrough(
          predicate<AuthState>((s) => s.status == AuthStatus.failure),
        ),
      );
    });

    test('AuthLoginWithGoogleSubmitted authenticates user session', () async {
      authBloc.add(const AuthLoginWithGoogleSubmitted());

      await expectLater(
        authBloc.stream,
        emitsInOrder([
          predicate<AuthState>(
            (s) =>
                s.status == AuthStatus.submitting &&
                s.toastMessage == 'Directing to secure authentication...',
          ),
          predicate<AuthState>(
            (s) => s.status == AuthStatus.authenticated && s.user != null,
          ),
        ]),
      );
    });

    test('AuthSignOutRequested resets to unauthenticated state', () {
      authBloc.add(const AuthSignOutRequested());
      expectLater(
        authBloc.stream,
        emits(
          predicate<AuthState>((s) => s.status == AuthStatus.unauthenticated),
        ),
      );
    });

    test('AuthNameChanged and AuthTermsToggled update state properly', () {
      authBloc.add(const AuthNameChanged('Julian Vance'));
      authBloc.add(const AuthTermsToggled(false));

      expectLater(
        authBloc.stream,
        emitsThrough(
          predicate<AuthState>(
            (s) => s.name == 'Julian Vance' && s.isTermsAccepted == false,
          ),
        ),
      );
    });

    test('password strength calculates stage and label correctly', () {
      authBloc.add(const AuthPasswordChanged('short'));
      expect(authBloc.state.passwordStrengthStage, equals(1));
      expect(
        authBloc.state.passwordStrengthLabel,
        equals('Acoustic Key Strength'),
      );

      authBloc.add(const AuthPasswordChanged('balancedPass1'));
      expectLater(
        authBloc.stream,
        emitsThrough(
          predicate<AuthState>(
            (s) =>
                s.passwordStrengthStage == 3 &&
                s.passwordStrengthLabel == 'Acoustic Key: Pristine',
          ),
        ),
      );
    });

    test(
      'AuthSignUpWithEmailSubmitted authenticates successfully when valid',
      () async {
        authBloc.add(const AuthNameChanged('Julian Vance'));
        authBloc.add(const AuthEmailChanged('julian@aura.audio'));
        authBloc.add(const AuthPasswordChanged('secureAcousticKey123'));
        authBloc.add(const AuthSignUpWithEmailSubmitted());

        await expectLater(
          authBloc.stream,
          emitsThrough(
            predicate<AuthState>(
              (s) =>
                  s.status == AuthStatus.authenticated &&
                  s.user?.displayName == 'Julian Vance',
            ),
          ),
        );
      },
    );
  });
}
