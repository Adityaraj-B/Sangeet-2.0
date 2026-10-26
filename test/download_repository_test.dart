import 'package:flutter_test/flutter_test.dart';
import 'package:sangeet/models/models.dart';
import 'package:sangeet/repositories/download_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testTrack1 = Track(
    id: 'dl-test-01',
    title: 'Avril 14th',
    artist: 'Aphex Twin',
    duration: '02:05',
    formatBadge: 'FLAC 24-BIT',
    streamUrl: 'https://example.com/audio1.mp3',
    albumArt: 'https://example.com/art1.jpg',
  );

  setUp(() async {
    await DownloadRepository.instance.clearAllDownloads();
  });

  tearDown(() async {
    await DownloadRepository.instance.clearAllDownloads();
  });

  group('DownloadRepository - Basic State & Initialization', () {
    test('Initial vault is empty after clearAllDownloads', () {
      expect(DownloadRepository.instance.downloadedTracks, isEmpty);
      expect(DownloadRepository.instance.downloadedTrackIds, isEmpty);
      expect(DownloadRepository.instance.downloadedCount, equals(0));
      expect(DownloadRepository.instance.isDownloaded('dl-test-01'), isFalse);
      expect(DownloadRepository.instance.isDownloading('dl-test-01'), isFalse);
      expect(DownloadRepository.instance.totalStorageBytes, equals(0));
      expect(DownloadRepository.instance.totalStorageFormatted, equals('0 MB'));
    });

    test('DownloadedItem serializes and deserializes correctly', () {
      final now = DateTime.now();
      final item = DownloadedItem(
        trackId: testTrack1.id,
        localAudioPath: '/tmp/files/track_dl-test-01.aura',
        localArtPath: '/tmp/files/art_dl-test-01.png',
        fileSizeBytes: 10485760, // 10 MB
        downloadedAt: now,
        track: testTrack1,
      );

      final map = item.toMap();
      final deserialized = DownloadedItem.fromMap(map);

      expect(deserialized.trackId, equals(testTrack1.id));
      expect(deserialized.localAudioPath, equals(item.localAudioPath));
      expect(deserialized.localArtPath, equals(item.localArtPath));
      expect(deserialized.fileSizeBytes, equals(10485760));
      expect(deserialized.track.title, equals('Avril 14th'));
    });

    test(
      'totalStorageFormatted formats bytes properly into KB, MB, and GB',
      () {
        // 0 bytes
        DownloadRepository.instance.totalStorageBytesNotifier.value = 0;
        expect(
          DownloadRepository.instance.totalStorageFormatted,
          equals('0 MB'),
        );

        // 512 KB
        DownloadRepository.instance.totalStorageBytesNotifier.value =
            512 * 1024;
        expect(
          DownloadRepository.instance.totalStorageFormatted,
          equals('512.0 KB'),
        );

        // 15.5 MB
        DownloadRepository.instance.totalStorageBytesNotifier.value =
            (15.5 * 1024 * 1024).round();
        expect(
          DownloadRepository.instance.totalStorageFormatted,
          equals('15.5 MB'),
        );

        // 2.5 GB
        DownloadRepository.instance.totalStorageBytesNotifier.value =
            (2.5 * 1024 * 1024 * 1024).round();
        expect(
          DownloadRepository.instance.totalStorageFormatted,
          equals('2.50 GB'),
        );

        // Reset
        DownloadRepository.instance.totalStorageBytesNotifier.value = 0;
      },
    );

    test('deleteDownload on non-existent track returns false safely', () async {
      final result = await DownloadRepository.instance.deleteDownload(
        'non-existent-id',
      );
      expect(result, isFalse);
    });

    test('getLocalAudioPath returns null for undownloaded track', () {
      final path = DownloadRepository.instance.getLocalAudioPath('unknown-id');
      expect(path, isNull);
    });

    test('getLocalArtPath returns null for undownloaded track', () {
      final path = DownloadRepository.instance.getLocalArtPath('unknown-id');
      expect(path, isNull);
    });
  });
}
