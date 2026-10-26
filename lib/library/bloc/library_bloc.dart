import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class LibraryPlaylist extends Equatable {
  final String id;
  final String title;
  final String trackCountText;
  final String curatorText;
  final String telemetryBadge;
  final String imageUrl;

  const LibraryPlaylist({
    required this.id,
    required this.title,
    required this.trackCountText,
    required this.curatorText,
    required this.telemetryBadge,
    required this.imageUrl,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        trackCountText,
        curatorText,
        telemetryBadge,
        imageUrl,
      ];
}

class LibraryRecentTrack extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String duration;
  final String formatBadge;
  final String imageUrl;

  const LibraryRecentTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.duration,
    required this.formatBadge,
    required this.imageUrl,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        artist,
        duration,
        formatBadge,
        imageUrl,
      ];
}

class FollowedArtist extends Equatable {
  final String id;
  final String name;
  final String imageUrl;

  const FollowedArtist({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  @override
  List<Object?> get props => [id, name, imageUrl];
}

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class LibraryEvent extends Equatable {
  const LibraryEvent();

  @override
  List<Object?> get props => [];
}

class LibraryFilterSelected extends LibraryEvent {
  final String filter;
  const LibraryFilterSelected(this.filter);

  @override
  List<Object?> get props => [filter];
}

class LibrarySortChanged extends LibraryEvent {
  final String sortOption;
  const LibrarySortChanged(this.sortOption);

  @override
  List<Object?> get props => [sortOption];
}

class LibraryViewModeToggled extends LibraryEvent {
  final bool isGridView;
  const LibraryViewModeToggled(this.isGridView);

  @override
  List<Object?> get props => [isGridView];
}

class LibraryPlaylistCreated extends LibraryEvent {
  final String title;
  const LibraryPlaylistCreated(this.title);

  @override
  List<Object?> get props => [title];
}

// ─── State ───────────────────────────────────────────────────────────────────

class LibraryState extends Equatable {
  final String selectedFilter;
  final List<String> availableFilters;
  final String currentSort;
  final List<String> availableSorts;
  final bool isGridView;
  final String masterCount;
  final String offlineStorage;
  final List<LibraryPlaylist> playlists;
  final List<LibraryRecentTrack> recentTracks;
  final List<FollowedArtist> followedArtists;

  const LibraryState({
    this.selectedFilter = 'Playlists',
    this.availableFilters = const [
      'Playlists',
      'Liked Songs',
      'Insights',
      'Liked Playlists',
      'History',
      'Downloaded',
      'Albums',
      'Artists',
      'Podcasts & Essays',
      'Spatial Audio',
    ],
    this.currentSort = 'Recently Added',
    this.availableSorts = const [
      'Recently Added',
      'Alphabetical (A-Z)',
      'Most Played',
      'Master Fidelity',
    ],
    this.isGridView = true,
    this.masterCount = '384 MASTERS',
    this.offlineStorage = '28.4 GB Offline',
    this.playlists = const [],
    this.recentTracks = const [],
    this.followedArtists = const [
      FollowedArtist(
        id: 'artist-1',
        name: 'Nils Frahm',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBX7YjjZmc4-2Ko63SYRj6BgFQmLD1Q795PPmn8T-RUBiabjHanem-Id0W8QHsqZX0GXhKGyov6OvAlub6fBmCKgQ3OwckiIVHGABJaqsLTRzEZoUnyf38dHVDRLvv_32CYwXFceILgJSzosuPfgLCivOMzquyAV5Gat0Ni2LeDjfkH4qpdR373S4yBbY7FxETEpWNlTeE6JQAgxGbgU6sRq6XAqTPERw8O1yGb98i8qUkAPk3nHMIH_g',
      ),
      FollowedArtist(
        id: 'artist-2',
        name: 'Ólafur Arnalds',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDeOD0-PPPMA7szD9UeNWR4ThjBYARChO27XI2Q5wSd22w1eFnWcV6FTMGSeixnrOosbOyFQX169vZkiF1CPIaxhJjN9oCjp24wNf8ZxnNfebkgLq3gTymAupgL_mlRRet16sbZg4OznhOrMHsU4PNHg4iVZNWiJpM9dsk_O9N9mVn5u9_QR1nkzcZxtbpiaMYplBGwwYKM-hGihHcXb_7QTTAjrxUnm-UaWsvXJk_LxVCFk-2y2uYYlg',
      ),
      FollowedArtist(
        id: 'artist-3',
        name: 'Max Richter',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCZDwr1XP1sDsFl_FyzzdxQy15QPDrka1bCDBf2KIwvHzVRqxbv1umZ5IGzT7er-hS6MrybtTPkPbB9fAlpnP5ea5vsNwLeBCLRgpkwMJ6fAmKqdXjT5s60yFl2Q-5kQEF38HQyB8Bc78kM2wbnok93JF9SKTCAI8rburU6SE60I1yrzHE0tidi9ceWcfDpaE54e2_2fexNOdGO7ps4faxiJa7hZJMztsEwq_7BvH-jZryze807kHMOOA',
      ),
      FollowedArtist(
        id: 'artist-4',
        name: 'Hania Rani',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBdQ8_pLkmXelZLeYK2-H-IM-HwYcoyMVLTsnhDtRSEuh7LUoHXHilQx2MV-QZfRX-S2SUAxjsdw1KRMeN0a8M203yS7y4nQw9UwT_msFr3sRuqpRHwRggMlKsEtZPchdkqq-7GBporvonml3WIwS7KEswRBgJ5LWfctM2n7N8feSREudaNpfuGmNN8g-R-KsIw3yBTVHxhPYKJeFQvTL71CXO9n1uqdys3fyB1lxdkDrV6qf7uuqy8DA',
      ),
      FollowedArtist(
        id: 'artist-5',
        name: 'Jon Hopkins',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAVI16WMVrMegnidX1sHAFsl3Q5JwhkMGo069t3_-s0YJD4qjpj0797wKNmYzGoegrE_EZWkFXvCi2ZntNydusBOVb-BItVNh86MYHa_twjbjATAzkvBOwJEp1drTkMCoNlgj0KvPrfYCTMDrGlHPKbgKwWTh19452dnPZJRhdz8OTEP0stpSYGJzIh1Od2DqR7FfpVz1QJR3jUL5svUmcEHqEv6T33c5sF9q3_ND8poQYBucj5UXnxUg',
      ),
    ],
  });

  LibraryState copyWith({
    String? selectedFilter,
    List<String>? availableFilters,
    String? currentSort,
    List<String>? availableSorts,
    bool? isGridView,
    String? masterCount,
    String? offlineStorage,
    List<LibraryPlaylist>? playlists,
    List<LibraryRecentTrack>? recentTracks,
    List<FollowedArtist>? followedArtists,
  }) {
    return LibraryState(
      selectedFilter: selectedFilter ?? this.selectedFilter,
      availableFilters: availableFilters ?? this.availableFilters,
      currentSort: currentSort ?? this.currentSort,
      availableSorts: availableSorts ?? this.availableSorts,
      isGridView: isGridView ?? this.isGridView,
      masterCount: masterCount ?? this.masterCount,
      offlineStorage: offlineStorage ?? this.offlineStorage,
      playlists: playlists ?? this.playlists,
      recentTracks: recentTracks ?? this.recentTracks,
      followedArtists: followedArtists ?? this.followedArtists,
    );
  }

  @override
  List<Object?> get props => [
        selectedFilter,
        availableFilters,
        currentSort,
        availableSorts,
        isGridView,
        masterCount,
        offlineStorage,
        playlists,
        recentTracks,
        followedArtists,
      ];
}

// ─── BLoC ────────────────────────────────────────────────────────────────────

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  LibraryBloc() : super(const LibraryState()) {
    on<LibraryFilterSelected>((event, emit) {
      emit(state.copyWith(selectedFilter: event.filter));
    });

    on<LibrarySortChanged>((event, emit) {
      emit(state.copyWith(currentSort: event.sortOption));
    });

    on<LibraryViewModeToggled>((event, emit) {
      emit(state.copyWith(isGridView: event.isGridView));
    });

    on<LibraryPlaylistCreated>((event, emit) {
      final newPlaylist = LibraryPlaylist(
        id: 'pl-${DateTime.now().millisecondsSinceEpoch}',
        title: event.title,
        trackCountText: '0 tracks',
        curatorText: 'Curated by you',
        telemetryBadge: 'Hi-Res Lossless',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDQxJWv6w03AjHVrc7qkg4vJgd5-SkAD4F52QNGU9iniPcsjEGlp-spt-j4oUxFKucQBRJTG6IVTUuUR0VB7x1yFw3-Y4-qo4R8pDv0n3Crs9pYXxZpjFEw_qO_yc7Tyolhj4SGWm7WtO1iNW3XkztFc2NSDB6kM4DI2AJiiRFvFtQ7PT6cgzi5lQ68MPVCYXpkL0IDIqHXXQLr8ShWt1GHqm2275Z-X9oHgeVszzeuS_xRUyATl3ud-Q',
      );
      emit(state.copyWith(
        playlists: [newPlaylist, ...state.playlists],
      ));
    });
  }
}
