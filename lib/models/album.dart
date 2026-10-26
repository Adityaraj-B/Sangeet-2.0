import 'package:equatable/equatable.dart';
import 'song.dart';

class Album extends Equatable {
  final String id;
  final String name;
  final String artist;
  final String year;
  final String coverUrl;
  final int songCount;
  final String language;
  final String url;
  final List<Song> songs;

  const Album({
    required this.id,
    required this.name,
    required this.artist,
    this.year = '',
    required this.coverUrl,
    this.songCount = 0,
    this.language = 'Hindi',
    this.url = '',
    this.songs = const [],
  });

  Album copyWith({
    String? id,
    String? name,
    String? artist,
    String? year,
    String? coverUrl,
    int? songCount,
    String? language,
    String? url,
    List<Song>? songs,
  }) {
    return Album(
      id: id ?? this.id,
      name: name ?? this.name,
      artist: artist ?? this.artist,
      year: year ?? this.year,
      coverUrl: coverUrl ?? this.coverUrl,
      songCount: songCount ?? this.songCount,
      language: language ?? this.language,
      url: url ?? this.url,
      songs: songs ?? this.songs,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        artist,
        year,
        coverUrl,
        songCount,
        language,
        url,
        songs,
      ];
}
