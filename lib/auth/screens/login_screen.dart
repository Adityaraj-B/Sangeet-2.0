import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/acoustic_monogram.dart';
import '../widgets/google_logo.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool canPop;

  const LoginScreen({super.key, this.canPop = true});

  static Route<void> route({bool canPop = true}) {
    return MaterialPageRoute<void>(
      builder: (_) => LoginScreen(canPop: canPop),
    );
  }

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() {
      setState(() => _isEmailFocused = _emailFocus.hasFocus);
    });
    _passwordFocus.addListener(() {
      setState(() => _isPasswordFocused = _passwordFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == AuthStatus.authenticated,
      listener: (context, state) {
        HapticFeedback.mediumImpact();
        final navigator = Navigator.of(context);
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted && widget.canPop && navigator.canPop()) {
            navigator.pop();
          }
        });
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF101012),
        body: Stack(
          children: [
            // ── Atmospheric Background Ambience ──────────────────────────────
            Positioned(
              top: -80,
              left: MediaQuery.of(context).size.width / 2 - 170,
              child: IgnorePointer(
                child: Container(
                  width: 340,
                  height: 340,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFE5C378).withValues(alpha: 0.08),
                        const Color(0xFFE5C378).withValues(alpha: 0.02),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              right: -50,
              child: IgnorePointer(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF612E87).withValues(alpha: 0.07),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Scrollable Form Canvas ───────────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  // Optional Top Bar with subtle back button if canPop
                  if (widget.canPop && Navigator.of(context).canPop())
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white70,
                              size: 22,
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).pop();
                            },
                          ),
                          const Spacer(),
                        ],
                      ),
                    )
                  else
                    const SizedBox(height: 16),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 380),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 10),

                              // ── Geometric Acoustic Seal ────────────────────
                              const AcousticMonogram(size: 64),

                              const SizedBox(height: 18),

                              // ── Brand Typography Lockup ────────────────────
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 26,
                                    height: 1,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          const Color(0xFFE5C378)
                                              .withValues(alpha: 0.4),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 10),
                                    child: Text(
                                      'SANGEET',
                                      style: TextStyle(
                                        color: Color(0xFFF7F2EA),
                                        fontSize: 22,
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: 6.0,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 26,
                                    height: 1,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFFE5C378)
                                              .withValues(alpha: 0.4),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // ── Tagline ────────────────────────────────────
                              Text(
                                'QUIET LUXURY FOR THE DISCERNING EAR',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFFD0C5B4)
                                      .withValues(alpha: 0.70),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 2.2,
                                ),
                              ),

                              const SizedBox(height: 24),

                              // ── Heading & Subtitle ─────────────────────────
                              const Text(
                                'Welcome back',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFFFCFBFA),
                                  fontSize: 32,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 0.4,
                                  height: 1.15,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                'Sign in to resume your private listening room.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFFC6C7C0)
                                      .withValues(alpha: 0.8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 0.2,
                                ),
                              ),

                              const SizedBox(height: 28),

                              // ── Google Authentication Button ───────────────
                              _GoogleLoginButton(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  context
                                      .read<AuthBloc>()
                                      .add(const AuthLoginWithGoogleSubmitted());
                                },
                              ),

                              const SizedBox(height: 22),

                              // ── Hairline Divider with Gold Accent ──────────
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            Colors.white.withValues(alpha: 0.12),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 3.5,
                                          height: 3.5,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE5C378)
                                                .withValues(alpha: 0.6),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'OR CONTINUE WITH EMAIL',
                                          style: TextStyle(
                                            color: const Color(0xFF999080)
                                                .withValues(alpha: 0.8),
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1.8,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 3.5,
                                          height: 3.5,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE5C378)
                                                .withValues(alpha: 0.6),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withValues(alpha: 0.12),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 22),

                              // ── Email Input Field ──────────────────────────
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4, bottom: 6),
                                    child: Text(
                                      'EMAIL ADDRESS',
                                      style: TextStyle(
                                        color: Color(0xFFC6C7C0),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.8,
                                      ),
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF18181B)
                                          .withValues(alpha: 0.70),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _isEmailFocused
                                            ? const Color(0xFFE5C378)
                                                .withValues(alpha: 0.65)
                                            : Colors.white
                                                .withValues(alpha: 0.08),
                                        width: 1.0,
                                      ),
                                      boxShadow: _isEmailFocused
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFFE5C378)
                                                    .withValues(alpha: 0.15),
                                                blurRadius: 18,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 14),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.mail_outline_rounded,
                                          color: Color(0xFF999080),
                                          size: 18,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextField(
                                            controller: _emailController,
                                            focusNode: _emailFocus,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            style: const TextStyle(
                                              color: Color(0xFFF5F2EB),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                            ),
                                            onChanged: (val) {
                                              context
                                                  .read<AuthBloc>()
                                                  .add(AuthEmailChanged(val));
                                            },
                                            decoration: const InputDecoration(
                                              hintText:
                                                  'client@aura-atelier.com',
                                              hintStyle: TextStyle(
                                                color: Colors.white24,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w300,
                                              ),
                                              border: InputBorder.none,
                                              isDense: true,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),

                              // ── Password Input Field ───────────────────────
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 4,
                                          bottom: 6,
                                          right: 2,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'PASSWORD',
                                              style: TextStyle(
                                                color: Color(0xFFC6C7C0),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 1.8,
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                HapticFeedback.selectionClick();
                                                context.read<AuthBloc>().add(
                                                      const AuthForgotPasswordRequested(),
                                                    );
                                              },
                                              child: const Text(
                                                'Forgot password?',
                                                style: TextStyle(
                                                  color: Color(0xFFE5C378),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  decoration:
                                                      TextDecoration.underline,
                                                  decorationColor:
                                                      Color(0x66E5C378),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 220),
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF18181B)
                                              .withValues(alpha: 0.70),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _isPasswordFocused
                                                ? const Color(0xFFE5C378)
                                                    .withValues(alpha: 0.65)
                                                : Colors.white
                                                    .withValues(alpha: 0.08),
                                            width: 1.0,
                                          ),
                                          boxShadow: _isPasswordFocused
                                              ? [
                                                  BoxShadow(
                                                    color: const Color(
                                                            0xFFE5C378)
                                                        .withValues(
                                                            alpha: 0.15),
                                                    blurRadius: 18,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.lock_outline_rounded,
                                              color: Color(0xFF999080),
                                              size: 18,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: TextField(
                                                controller: _passwordController,
                                                focusNode: _passwordFocus,
                                                obscureText:
                                                    state.isPasswordObscured,
                                                style: const TextStyle(
                                                  color: Color(0xFFF5F2EB),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w400,
                                                  letterSpacing: 2.0,
                                                ),
                                                onChanged: (val) {
                                                  context.read<AuthBloc>().add(
                                                        AuthPasswordChanged(
                                                            val),
                                                      );
                                                },
                                                decoration:
                                                    const InputDecoration(
                                                  hintText: '••••••••••••',
                                                  hintStyle: TextStyle(
                                                    color: Colors.white24,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w300,
                                                    letterSpacing: 2.0,
                                                  ),
                                                  border: InputBorder.none,
                                                  isDense: true,
                                                  contentPadding:
                                                      EdgeInsets.zero,
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTap: () {
                                                HapticFeedback.selectionClick();
                                                context.read<AuthBloc>().add(
                                                      const AuthTogglePasswordVisibility(),
                                                    );
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.all(4),
                                                child: Icon(
                                                  state.isPasswordObscured
                                                      ? Icons
                                                          .visibility_off_rounded
                                                      : Icons.visibility_rounded,
                                                  color:
                                                      const Color(0xFF999080),
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),

                              const SizedBox(height: 24),

                              // ── Primary Action: Artisan Gold Button ────────
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  return _ArtisanGoldButton(
                                    isSubmitting: state.isSubmitting,
                                    onTap: () {
                                      HapticFeedback.mediumImpact();
                                      context.read<AuthBloc>().add(
                                            const AuthLoginWithEmailSubmitted(),
                                          );
                                    },
                                  );
                                },
                              ),

                              const SizedBox(height: 18),

                              // ── Acoustic Feedback Toast ───────────────────
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  final msg = state.toastMessage;
                                  return AnimatedOpacity(
                                    duration:
                                        const Duration(milliseconds: 350),
                                    opacity: msg != null ? 1.0 : 0.0,
                                    child: AnimatedSlide(
                                      duration:
                                          const Duration(milliseconds: 350),
                                      offset: msg != null
                                          ? Offset.zero
                                          : const Offset(0, 0.4),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E1E22)
                                              .withValues(alpha: 0.95),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          border: Border.all(
                                            color: const Color(0xFFE5C378)
                                                .withValues(alpha: 0.30),
                                            width: 1.0,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.5),
                                              blurRadius: 16,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.graphic_eq_rounded,
                                              size: 15,
                                              color: Color(0xFFE5C378),
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                msg ?? '',
                                                style: const TextStyle(
                                                  color: Color(0xFFE5E1E4),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w400,
                                                  letterSpacing: 0.2,
                                                ),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 24),

                              // ── Bottom Membership Switch ──────────────────
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account?",
                                    style: TextStyle(
                                      color: const Color(0xFFC6C7C0)
                                          .withValues(alpha: 0.70),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      Navigator.of(context).push(
                                        SignupScreen.route(),
                                      );
                                    },
                                    child: const Text(
                                      'Sign up',
                                      style: TextStyle(
                                        color: Color(0xFFE5C378),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        decoration:
                                            TextDecoration.underline,
                                        decorationColor: Color(0x66E5C378),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 28),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleLoginButton extends StatefulWidget {
  final VoidCallback onTap;

  const _GoogleLoginButton({required this.onTap});

  @override
  State<_GoogleLoginButton> createState() => _GoogleLoginButtonState();
}

class _GoogleLoginButtonState extends State<_GoogleLoginButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 140),
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF18181B).withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE5C378).withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GoogleLogoBadge(size: 22),
              SizedBox(width: 12),
              Text(
                'Continue with Google',
                style: TextStyle(
                  color: Color(0xFFF0EBE3),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArtisanGoldButton extends StatefulWidget {
  final bool isSubmitting;
  final VoidCallback onTap;

  const _ArtisanGoldButton({
    required this.isSubmitting,
    required this.onTap,
  });

  @override
  State<_ArtisanGoldButton> createState() => _ArtisanGoldButtonState();
}

class _ArtisanGoldButtonState extends State<_ArtisanGoldButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.isSubmitting
          ? null
          : (_) => setState(() => _isPressed = true),
      onTapUp: widget.isSubmitting
          ? null
          : (_) {
              setState(() => _isPressed = false);
              widget.onTap();
            },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 140),
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFE4A0),
                Color(0xFFE5C378),
                Color(0xFFD6AF5D),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE5C378).withValues(alpha: 0.32),
                blurRadius: 26,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: const Color(0xFFE5C378).withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: widget.isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF221803)),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'SIGN IN',
                        style: TextStyle(
                          color: Color(0xFF221803),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Color(0xFF221803),
                        size: 17,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
