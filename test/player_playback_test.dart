// ignore_for_file: depend_on_referenced_packages

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sangeet/models/models.dart';
import 'package:sangeet/player/bloc/player_bloc.dart';

class MockJustAudioPlatform extends JustAudioPlatform
    with MockPlatformInterfaceMixin {
  final Map<String, MockAudioPlayerPlatform> players = {};

  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async {
    final playerPlatform = MockAudioPlayerPlatform(request.id);
    players[request.id] = playerPlatform;
    return playerPlatform;
  }

  @override
  Future<DisposePlayerResponse> disposePlayer(
    DisposePlayerRequest request,
  ) async {
    players.remove(request.id);
    return DisposePlayerResponse();
  }

  @override
  Future<DisposeAllPlayersResponse> disposeAllPlayers(
    DisposeAllPlayersRequest request,
  ) async {
    players.clear();
    return DisposeAllPlayersResponse();
  }
}

class MockAudioPlayerPlatform extends AudioPlayerPlatform {
  MockAudioPlayerPlatform(super.id);

  bool isPlaying = false;

  @override
  Future<LoadResponse> load(LoadRequest request) async {
    return LoadResponse(duration: const Duration(minutes: 3));
  }

  @override
  Future<PlayResponse> play(PlayRequest request) async {
    isPlaying = true;
    return PlayResponse();
  }

  @override
  Future<PauseResponse> pause(PauseRequest request) async {
    isPlaying = false;
    return PauseResponse();
  }

  @override
  Future<SetVolumeResponse> setVolume(SetVolumeRequest request) async {
    return SetVolumeResponse();
  }

  @override
  Future<SeekResponse> seek(SeekRequest request) async {
    return SeekResponse();
  }

  @override
  Future<SetSpeedResponse> setSpeed(SetSpeedRequest request) async {
    return SetSpeedResponse();
  }

  @override
  Future<SetLoopModeResponse> setLoopMode(SetLoopModeRequest request) async {
    return SetLoopModeResponse();
  }

  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream =>
      const Stream.empty();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayerBloc Playback Flow Tests', () {
    late PlayerBloc playerBloc;

    setUp(() {
      JustAudioPlatform.instance = MockJustAudioPlatform();
      playerBloc = PlayerBloc();
    });

    tearDown(() async {
      await playerBloc.close();
    });

    test('initial state has empty queue and null track', () {
      expect(playerBloc.state.queue.isEmpty, isTrue);
      expect(playerBloc.state.currentTrack, isNull);
      expect(playerBloc.state.isPlaying, isFalse);
    });

    test(
      'playing a new track updates queue and sets isPlaying to true',
      () async {
        const newTrack = Track(
          id: 'online-test-01',
          title: 'Believer',
          artist: 'Imagine Dragons',
          duration: '03:24',
          formatBadge: '320k',
          streamUrl:
              'https://aac.saavncdn.com/248/46944eb7b4b31f5b0abf5eb2e1be2d2a_320.mp4',
        );

        playerBloc.add(const PlayerPlayTrack(newTrack));

        await expectLater(
          playerBloc.stream,
          emitsThrough(
            predicate<PlayerState>(
              (s) =>
                  s.currentTrack?.id == 'online-test-01' &&
                  s.isPlaying == true &&
                  s.queue.contains(newTrack),
            ),
          ),
        );
      },
    );

    test(
      'natural track transition advances to second song seamlessly without stalling',
      () async {
        const track1 = Track(
          id: 'track-01',
          title: 'Kesariya',
          artist: 'Arijit Singh',
          duration: '04:28',
          formatBadge: '320k',
          streamUrl: 'https://aac.saavncdn.com/track1.mp4',
        );
        const track2 = Track(
          id: 'track-02',
          title: 'Apna Bana Le',
          artist: 'Arijit Singh',
          duration: '03:50',
          formatBadge: '320k',
          streamUrl: 'https://aac.saavncdn.com/track2.mp4',
        );

        // Play queue starting with track 1
        playerBloc.add(
          const PlayerPlayQueue([track1, track2], initialIndex: 0),
        );

        await expectLater(
          playerBloc.stream,
          emitsThrough(
            predicate<PlayerState>(
              (s) =>
                  s.currentTrack?.id == 'track-01' &&
                  s.currentIndex == 0 &&
                  s.isPlaying == true,
            ),
          ),
        );

        // When track 1 finishes, PlayerNextTrack is dispatched
        playerBloc.add(const PlayerNextTrack());

        await expectLater(
          playerBloc.stream,
          emitsThrough(
            predicate<PlayerState>(
              (s) =>
                  s.currentTrack?.id == 'track-02' &&
                  s.currentIndex == 1 &&
                  s.isPlaying == true &&
                  s.currentTime == '00:00',
            ),
          ),
        );
      },
    );

    test('seeking updates progress in state', () async {
      playerBloc.add(const PlayerSeek(0.5));

      await expectLater(
        playerBloc.stream,
        emitsThrough(predicate<PlayerState>((s) => s.progress == 0.5)),
      );
    });

    test('changing volume updates volume state', () async {
      playerBloc.add(const PlayerSetVolume(0.85));

      await expectLater(
        playerBloc.stream,
        emitsThrough(predicate<PlayerState>((s) => s.volume == 0.85)),
      );
    });
  });
}
