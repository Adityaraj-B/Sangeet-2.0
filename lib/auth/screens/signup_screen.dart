import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/acoustic_monogram.dart';
import '../widgets/google_logo.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  final bool canPop;

  const SignupScreen({super.key, this.canPop = true});

  static Route<void> route({bool canPop = true}) {
    return MaterialPageRoute<void>(
      builder: (_) => SignupScreen(canPop: canPop),
    );
  }

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _isNameFocused = false;
  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(() {
      setState(() => _isNameFocused = _nameFocus.hasFocus);
    });
    _emailFocus.addListener(() {
      setState(() => _isEmailFocused = _emailFocus.hasFocus);
    });
    _passwordFocus.addListener(() {
      setState(() => _isPasswordFocused = _passwordFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    HapticFeedback.lightImpact();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(LoginScreen.route(canPop: false));
    }
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
          if (mounted && navigator.canPop()) {
            navigator.popUntil((route) => route.isFirst);
          }
        });
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF101012),
        body: Stack(
          children: [
            // ── Atmospheric Background Glows ─────────────────────────────────
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
                        const Color(0xFFE5C378).withValues(alpha: 0.07),
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
              bottom: 30,
              right: -50,
              child: IgnorePointer(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF612E87).withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Main Scroll Canvas ───────────────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  // Top Navigation Bar
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
                    const SizedBox(height: 12),

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
                              // ── Geometric Acoustic Seal ────────────────────
                              const AcousticMonogram(size: 64),

                              const SizedBox(height: 16),

                              // ── Brand Typography Lockup ────────────────────
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 24,
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
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 10),
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
                                    width: 24,
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

                              const SizedBox(height: 6),

                              // ── Tagline ────────────────────────────────────
                              Text(
                                'QUIET LUXURY FOR THE DISCERNING EAR',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFFD0C5B4)
                                      .withValues(alpha: 0.70),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 2.4,
                                ),
                              ),

                              const SizedBox(height: 20),

                              // ── Title & Subtitle ───────────────────────────
                              const Text(
                                'Join the Atelier',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFFFCFBFA),
                                  fontSize: 32,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 0.4,
                                  height: 1.15,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                'Begin your private listening journey.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFFC6C7C0)
                                      .withValues(alpha: 0.8),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 0.2,
                                ),
                              ),

                              const SizedBox(height: 24),

                              // ── Google One-Tap Social Auth ─────────────────
                              _GoogleSignupButton(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  context
                                      .read<AuthBloc>()
                                      .add(const AuthLoginWithGoogleSubmitted());
                                },
                              ),

                              const SizedBox(height: 18),

                              // ── Hairline Divider ───────────────────────────
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
                                                .withValues(alpha: 0.5),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'OR SIGN UP WITH EMAIL',
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
                                                .withValues(alpha: 0.5),
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

                              const SizedBox(height: 18),

                              // ── Field 1: Full Name ─────────────────────────
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4, bottom: 6),
                                    child: Text(
                                      'FULL NAME',
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
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF18181B)
                                          .withValues(alpha: 0.70),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _isNameFocused
                                            ? const Color(0xFFE5C378)
                                                .withValues(alpha: 0.65)
                                            : Colors.white
                                                .withValues(alpha: 0.08),
                                        width: 1.0,
                                      ),
                                      boxShadow: _isNameFocused
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFFE5C378)
                                                    .withValues(alpha: 0.15),
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
                                          Icons.person_outline_rounded,
                                          color: Color(0xFF999080),
                                          size: 18,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextField(
                                            controller: _nameController,
                                            focusNode: _nameFocus,
                                            textCapitalization:
                                                TextCapitalization.words,
                                            style: const TextStyle(
                                              color: Color(0xFFF5F2EB),
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w400,
                                            ),
                                            onChanged: (val) {
                                              context
                                                  .read<AuthBloc>()
                                                  .add(AuthNameChanged(val));
                                            },
                                            decoration: const InputDecoration(
                                              hintText: 'Julian Vance',
                                              hintStyle: TextStyle(
                                                color: Colors.white24,
                                                fontSize: 13.5,
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

                              const SizedBox(height: 16),

                              // ── Field 2: Email Address ─────────────────────
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
                                    height: 46,
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
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
                                              fontSize: 13.5,
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
                                                fontSize: 13.5,
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

                              const SizedBox(height: 16),

                              // ── Field 3: Password & Strength Meter ─────────
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(
                                          left: 4,
                                          bottom: 6,
                                          right: 2,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'PASSWORD',
                                              style: TextStyle(
                                                color: Color(0xFFC6C7C0),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 1.8,
                                              ),
                                            ),
                                            Text(
                                              'Min. 8 characters',
                                              style: TextStyle(
                                                color: Color(0xCCE5C378),
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w300,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 220),
                                        height: 46,
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
                                                  fontSize: 13.5,
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
                                                    fontSize: 13.5,
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

                                      const SizedBox(height: 6),

                                      // Requirement Dots / Key Strength Meter
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              state.passwordStrengthLabel,
                                              style: TextStyle(
                                                color: const Color(0xFF999080)
                                                    .withValues(alpha: 0.70),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                _StrengthBar(
                                                  isActive: true,
                                                  activeColor: const Color(
                                                      0xFFE5C378),
                                                ),
                                                const SizedBox(width: 6),
                                                _StrengthBar(
                                                  isActive: state
                                                          .passwordStrengthStage >=
                                                      2,
                                                  activeColor: const Color(
                                                      0xFFE5C378),
                                                ),
                                                const SizedBox(width: 6),
                                                _StrengthBar(
                                                  isActive: state
                                                          .passwordStrengthStage >=
                                                      3,
                                                  activeColor: const Color(
                                                      0xFFFFE09D),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),

                              const SizedBox(height: 14),

                              // ── Membership Consent Checkbox ────────────────
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  return GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      context.read<AuthBloc>().add(
                                            AuthTermsToggled(
                                                !state.isTermsAccepted),
                                          );
                                    },
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 180),
                                          width: 17,
                                          height: 17,
                                          margin:
                                              const EdgeInsets.only(top: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF18181B),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: Border.all(
                                              color: state.isTermsAccepted
                                                  ? const Color(0xFFE5C378)
                                                      .withValues(alpha: 0.7)
                                                  : Colors.white
                                                      .withValues(alpha: 0.2),
                                              width: 1.0,
                                            ),
                                          ),
                                          child: state.isTermsAccepted
                                              ? const Icon(
                                                  Icons.check_rounded,
                                                  size: 13,
                                                  color: Color(0xFFE5C378),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text.rich(
                                            TextSpan(
                                              text: 'I agree to the ',
                                              style: TextStyle(
                                                color: const Color(0xFFC6C7C0)
                                                    .withValues(alpha: 0.8),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w300,
                                                height: 1.35,
                                              ),
                                              children: const [
                                                TextSpan(
                                                  text: 'Terms of Service',
                                                  style: TextStyle(
                                                    color: Color(0xFFF0EBE3),
                                                    decoration: TextDecoration
                                                        .underline,
                                                    decorationColor:
                                                        Color(0x66E5C378),
                                                  ),
                                                ),
                                                TextSpan(text: ' and '),
                                                TextSpan(
                                                  text: 'Privacy Policy',
                                                  style: TextStyle(
                                                    color: Color(0xFFF0EBE3),
                                                    decoration: TextDecoration
                                                        .underline,
                                                    decorationColor:
                                                        Color(0x66E5C378),
                                                  ),
                                                ),
                                                TextSpan(text: '.'),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 22),

                              // ── Primary Action Button ──────────────────────
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  return _ArtisanSignupButton(
                                    isSubmitting: state.isSubmitting,
                                    onTap: () {
                                      HapticFeedback.mediumImpact();
                                      context.read<AuthBloc>().add(
                                            const AuthSignUpWithEmailSubmitted(),
                                          );
                                    },
                                  );
                                },
                              ),

                              const SizedBox(height: 16),

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

                              const SizedBox(height: 20),

                              // ── Bottom Link: Already a member? Sign in ─────
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Already a member?',
                                    style: TextStyle(
                                      color: const Color(0xFFC6C7C0)
                                          .withValues(alpha: 0.70),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: _navigateToLogin,
                                    child: const Text(
                                      'Sign in',
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

class _StrengthBar extends StatelessWidget {
  final bool isActive;
  final Color activeColor;

  const _StrengthBar({
    required this.isActive,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 20,
      height: 2.5,
      decoration: BoxDecoration(
        color: isActive
            ? activeColor
            : Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _GoogleSignupButton extends StatefulWidget {
  final VoidCallback onTap;

  const _GoogleSignupButton({required this.onTap});

  @override
  State<_GoogleSignupButton> createState() => _GoogleSignupButtonState();
}

class _GoogleSignupButtonState extends State<_GoogleSignupButton> {
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
          height: 48,
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
              GoogleLogoBadge(size: 20),
              SizedBox(width: 12),
              Text(
                'Continue with Google',
                style: TextStyle(
                  color: Color(0xFFF0EBE3),
                  fontSize: 13,
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

class _ArtisanSignupButton extends StatefulWidget {
  final bool isSubmitting;
  final VoidCallback onTap;

  const _ArtisanSignupButton({
    required this.isSubmitting,
    required this.onTap,
  });

  @override
  State<_ArtisanSignupButton> createState() => _ArtisanSignupButtonState();
}

class _ArtisanSignupButtonState extends State<_ArtisanSignupButton> {
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
                        'CREATE ACCOUNT',
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
