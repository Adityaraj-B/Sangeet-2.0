import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth/auth.dart';
import 'home/bloc/home_bloc.dart';
import 'main_layout/bloc/main_layout_bloc.dart';
import 'main_layout/screens/main_layout_screen.dart';
import 'player/bloc/player_bloc.dart';
import 'profile/bloc/profile_bloc.dart';
import 'repositories/music_repository.dart';
import 'repositories/playlist_repository.dart';
import 'repositories/favorites_repository.dart';
import 'repositories/history_repository.dart';
import 'repositories/download_repository.dart';
import 'services/audio_handler.dart';
import 'services/connectivity_service.dart';
import 'services/firebase_service.dart';
import 'insights/services/insight_service.dart';
import 'theme/theme.dart';

// Global reference kept so widgets can reach the handler if needed.
late final SangeetAudioHandler audioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase and Google Sign-In
  await FirebaseService.initialize();

  // Initialize real-time network connectivity monitor
  ConnectivityService.instance;

  // Prefetch trending music & albums in parallel during boot
  unawaited(MusicRepository.instance.getTrending());
  unawaited(MusicRepository.instance.getTrendingAlbums(limit: 10));
  // Warm up playlist disk cache and listener
  PlaylistRepository.instance;
  // Warm up favorites disk cache and listener
  FavoritesRepository.instance;
  // Warm up listening playback history disk persistence & cloud sync
  HistoryRepository.instance;
  // Warm up offline download vault registry
  DownloadRepository.instance;
  // Initialize listening insights telemetry
  await ListeningInsightsService.instance.initialize();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Create PlayerBloc first so the audio handler can subscribe to it.
  final playerBloc = PlayerBloc();

  // Boot the audio_service foreground service (shows media notification).
  audioHandler = await initAudioService(playerBloc);

  runApp(AuraApp(playerBloc: playerBloc));
}

class AuraApp extends StatefulWidget {
  const AuraApp({super.key, required this.playerBloc});

  final PlayerBloc playerBloc;

  @override
  State<AuraApp> createState() => _AuraAppState();
}

class _AuraAppState extends State<AuraApp> {
  @override
  void dispose() {
    // Clean up audio handler subscription on app teardown.
    audioHandler.dispose();
    widget.playerBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Provide the already-created PlayerBloc (started before runApp).
        BlocProvider<PlayerBloc>.value(value: widget.playerBloc),
        BlocProvider<AuthBloc>(create: (_) => AuthBloc()),
        BlocProvider<HomeBloc>(create: (_) => HomeBloc()),
        BlocProvider<MainLayoutBloc>(create: (_) => MainLayoutBloc()),
        BlocProvider<ProfileBloc>(create: (_) => ProfileBloc()),
      ],
      child: MaterialApp(
        title: 'Sangeet',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AuthGate(),
      ),
    );
  }
}

/// Gatekeeper widget that checks authentication persistence:
/// - If authenticated, opens [MainLayoutScreen].
/// - If not authenticated, directs listener to [LoginScreen] first.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          (previous.user == null) != (current.user == null),
      builder: (context, state) {
        final isAuthenticated =
            state.status == AuthStatus.authenticated && state.user != null;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: isAuthenticated
              ? const MainLayoutScreen(key: ValueKey('main_layout'))
              : const LoginScreen(key: ValueKey('login_screen'), canPop: false),
        );
      },
    );
  }
}
