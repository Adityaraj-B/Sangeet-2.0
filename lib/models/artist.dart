import 'package:equatable/equatable.dart';
import 'album.dart';
import 'song.dart';

class Artist extends Equatable {
  final String id;
  final String name;
  final String role;
  final String imageUrl;
  final int? followerCount;
  final String? fanCount;
  final bool isVerified;
  final String dominantLanguage;
  final String bio;
  final String url;
  final List<Song> topSongs;
  final List<Album> topAlbums;
  final List<Song> singles;

  const Artist({
    required this.id,
    required this.name,
    this.role = 'Artist',
    this.imageUrl = '',
    this.followerCount,
    this.fanCount,
    this.isVerified = false,
    this.dominantLanguage = 'Hindi',
    this.bio = '',
    this.url = '',
    this.topSongs = const [],
    this.topAlbums = const [],
    this.singles = const [],
  });

  Artist copyWith({
    String? id,
    String? name,
    String? role,
    String? imageUrl,
    int? followerCount,
    String? fanCount,
    bool? isVerified,
    String? dominantLanguage,
    String? bio,
    String? url,
    List<Song>? topSongs,
    List<Album>? topAlbums,
    List<Song>? singles,
  }) {
    return Artist(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      imageUrl: imageUrl ?? this.imageUrl,
      followerCount: followerCount ?? this.followerCount,
      fanCount: fanCount ?? this.fanCount,
      isVerified: isVerified ?? this.isVerified,
      dominantLanguage: dominantLanguage ?? this.dominantLanguage,
      bio: bio ?? this.bio,
      url: url ?? this.url,
      topSongs: topSongs ?? this.topSongs,
      topAlbums: topAlbums ?? this.topAlbums,
      singles: singles ?? this.singles,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'imageUrl': imageUrl,
      'followerCount': followerCount,
      'fanCount': fanCount,
      'isVerified': isVerified,
      'dominantLanguage': dominantLanguage,
      'bio': bio,
      'url': url,
      'topSongs': topSongs.map((s) => s.toJson()).toList(),
      'topAlbums': topAlbums.map((a) => {
        'id': a.id,
        'name': a.name,
        'artist': a.artist,
        'year': a.year,
        'coverUrl': a.coverUrl,
        'songCount': a.songCount,
        'language': a.language,
        'url': a.url,
      }).toList(),
      'singles': singles.map((s) => s.toJson()).toList(),
    };
  }

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      role: (json['role'] ?? 'Artist').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      followerCount: json['followerCount'] is int
          ? json['followerCount'] as int
          : int.tryParse(json['followerCount']?.toString() ?? ''),
      fanCount: json['fanCount']?.toString(),
      isVerified: json['isVerified'] == true,
      dominantLanguage: (json['dominantLanguage'] ?? 'Hindi').toString(),
      bio: (json['bio'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
      topSongs: json['topSongs'] is List
          ? (json['topSongs'] as List)
              .whereType<Map<String, dynamic>>()
              .map((s) => Song.fromJson(s))
              .toList()
          : const [],
      topAlbums: const [],
      singles: const [],
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        role,
        imageUrl,
        followerCount,
        fanCount,
        isVerified,
        dominantLanguage,
        bio,
        url,
        topSongs,
        topAlbums,
        singles,
      ];
}
