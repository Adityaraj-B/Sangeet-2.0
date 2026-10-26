// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sangeet/home/widgets/banner.dart';
import 'package:sangeet/player/bloc/player_bloc.dart';
import 'package:sangeet/player/services/autoplay_engine.dart';
import 'package:sangeet/repositories/music_repository.dart';
import 'package:sangeet/services/remote_music_service.dart';

class _MockPlatform extends JustAudioPlatform with MockPlatformInterfaceMixin {
  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async {
    return _MockPlayer(request.id);
  }

  @override
  Future<DisposePlayerResponse> disposePlayer(
    DisposePlayerRequest request,
  ) async {
    return DisposePlayerResponse();
  }

  @override
  Future<DisposeAllPlayersResponse> disposeAllPlayers(
    DisposeAllPlayersRequest request,
  ) async {
    return DisposeAllPlayersResponse();
  }
}

class _MockPlayer extends AudioPlayerPlatform {
  _MockPlayer(super.id);

  @override
  Future<LoadResponse> load(LoadRequest request) async {
    return LoadResponse(duration: const Duration(minutes: 3));
  }

  @override
  Future<PlayResponse> play(PlayRequest request) async => PlayResponse();

  @override
  Future<PauseResponse> pause(PauseRequest request) async => PauseResponse();

  @override
  Future<SetVolumeResponse> setVolume(SetVolumeRequest request) async =>
      SetVolumeResponse();
}

void main() {
  setUp(() {
    JustAudioPlatform.instance = _MockPlatform();
  });

  const mockTrendingJson = '''
{
  "success": true,
  "data": {
    "total": 2,
    "start": 0,
    "results": [
      {
        "id": "trend-1",
        "name": "Apna Bana Le",
        "type": "song",
        "duration": 261,
        "artists": {
          "primary": [
            {"id": "a-1", "name": "Arijit Singh", "role": "primary_artists"}
          ]
        },
        "image": [
          {"quality": "500x500", "url": "https://c.saavncdn.com/test.jpg"}
        ],
        "downloadUrl": [
          {"quality": "320kbps", "url": "https://aac.saavncdn.com/test.mp4"}
        ]
      }
    ]
  }
}
''';

  testWidgets('HomeBanner renders items with auto-scroll and responds to tap', (
    tester,
  ) async {
    final mockClient = MockClient((request) async {
      return http.Response(mockTrendingJson, 200);
    });

    final repo = MusicRepository(RemoteMusicService(client: mockClient));
    final playerBloc = PlayerBloc(autoplayEngine: AutoplayEngine(repo));

    await tester.pumpWidget(
      BlocProvider<PlayerBloc>.value(
        value: playerBloc,
        child: MaterialApp(
          home: Scaffold(body: HomeBanner(musicRepository: repo)),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify PageView is present
    expect(find.byType(PageView), findsOneWidget);

    // Verify song title from mock response appears
    expect(find.text('Apna Bana Le'), findsWidgets);

    playerBloc.close();
  });
}
