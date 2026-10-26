import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/album.dart';
import '../../models/artist.dart';
import '../../models/song.dart';
import '../../repositories/music_repository.dart';
import '../../services/remote_music_service.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class ArchivalSession extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final String badge;
  final String imageUrl;
  final String duration;
  final String format;

  const ArchivalSession({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.imageUrl,
    required this.duration,
    required this.format,
  });

  @override
  List<Object?> get props =>
      [id, title, subtitle, badge, imageUrl, duration, format];
}

class SonicSpectrumCategory extends Equatable {
  final String id;
  final String tag;
  final String title;
  final String imageUrl;

  const SonicSpectrumCategory({
    required this.id,
    required this.tag,
    required this.title,
    required this.imageUrl,
  });

  @override
  List<Object?> get props => [id, tag, title, imageUrl];
}

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

class SearchQueryChanged extends SearchEvent {
  final String query;
  const SearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class SearchPerformSearch extends SearchEvent {
  final String query;
  const SearchPerformSearch(this.query);

  @override
  List<Object?> get props => [query];
}

class SearchCategoryChanged extends SearchEvent {
  final String category;
  const SearchCategoryChanged(this.category);

  @override
  List<Object?> get props => [category];
}

class SearchFilterSelected extends SearchEvent {
  final String filter;
  const SearchFilterSelected(this.filter);

  @override
  List<Object?> get props => [filter];
}

class SearchQueryCleared extends SearchEvent {
  const SearchQueryCleared();
}

// ─── State ───────────────────────────────────────────────────────────────────

class SearchState extends Equatable {
  final String query;
  final bool isLoading;
  final String? errorMessage;
  final List<Song> searchResults;
  final List<Artist> artistResults;
  final List<Album> albumResults;
  final String activeCategory;
  final String selectedFilter;
  final List<String> availableFilters;
  final List<ArchivalSession> allSessions;
  final List<ArchivalSession> filteredSessions;
  final List<SonicSpectrumCategory> sonicCategories;

  const SearchState({
    this.query = '',
    this.isLoading = false,
    this.errorMessage,
    this.searchResults = const [],
    this.artistResults = const [],
    this.albumResults = const [],
    this.activeCategory = 'ALL',
    this.selectedFilter = 'Classical',
    this.availableFilters = const [
      'Classical',
      'Romantic',
      'Pop',
      'Ambient',
      'Jazz',
      'Electronic',
      'Folk & Acoustic',
    ],
    this.allSessions = const [
      ArchivalSession(
        id: 'session-1',
        title: 'Midnight Resonance',
        subtitle: 'Binaural 432Hz Master • 1h 24m',
        badge: 'Spatial',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBGVK1LINXTvY0q0slezF9K-ag1P8QsLTQnIri4hAw5pP7imvqkNZuCBgkH77ksLmMNjO_SqSvsqEJR5V8UwgKx-2j-JXa6LixHCS-CyljNn-06AA9gTP0JuoEWNVmSSdsCN8PIFLGztH-Q1UL1w0oZY68ymgduU_mX3ROuYzwfX0Eyu6JUABXh8--FFGuI1PqifKDbl8TR5hEsf6221UXrr2nd0cRjE6eXgQFxu3qtKA1BL__dAlY-wg',
        duration: '1h 24m',
        format: 'DSD 256',
      ),
      ArchivalSession(
        id: 'session-2',
        title: 'Field Recordings: Kyoto Rain',
        subtitle: 'Stereo Spatial Array • 45m',
        badge: '96/24',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCvj6GPvfHLZZ9DEypg_tTiBMzkSAmKXvcyNyfxRAd6T9oT_xaBii0CTiSmoe7AVilxBRgEDAf18Gz2A5PBc_x5kM9xcp1QLIe_b0aydcfF-WUIvgigh6Xqy70t5hxW5WoT-ngqfVGZtn75XR8mTOAE9feDmoMMz9TJRzSId8dNRRnhTQaIYmU_EvCWYbfmUhGQ_TKAVJSknCiu2oivj0Hb2JdgDUEa_BCqEV4mINhtMRPbwZBHAftibg',
        duration: '45m',
        format: 'FLAC 96/24',
      ),
      ArchivalSession(
        id: 'session-3',
        title: 'The Berlin Piano Sessions',
        subtitle: 'Bösendorfer 290 Imperial • 52m',
        badge: 'DSD64',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBkpODXUDaosw-F421ETXLhjyMBbWzRIbd-GCZFYq8n1QCeNYVDpn0dcIOnIt1Zstyx4y2s0-xduJIHbdT-TP1qzXvP-TeijaGnn4JsLadQkjzcxsWSZY3UBtSf5yjXgJQy1SUPpzw6uIg2bCVVEMdBkZlqm_RlrVw3mci_e1oqaXuvFhzfoFEjn-WOAdq7Otu1960g7LpL1XEaOOoUPY0K1O1BCD3SVi_dEYVYUq0P7jPSPD4zHe3Csg',
        duration: '52m',
        format: 'DSD 64',
      ),
    ],
    this.filteredSessions = const [
      ArchivalSession(
        id: 'session-1',
        title: 'Midnight Resonance',
        subtitle: 'Binaural 432Hz Master • 1h 24m',
        badge: 'Spatial',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBGVK1LINXTvY0q0slezF9K-ag1P8QsLTQnIri4hAw5pP7imvqkNZuCBgkH77ksLmMNjO_SqSvsqEJR5V8UwgKx-2j-JXa6LixHCS-CyljNn-06AA9gTP0JuoEWNVmSSdsCN8PIFLGztH-Q1UL1w0oZY68ymgduU_mX3ROuYzwfX0Eyu6JUABXh8--FFGuI1PqifKDbl8TR5hEsf6221UXrr2nd0cRjE6eXgQFxu3qtKA1BL__dAlY-wg',
        duration: '1h 24m',
        format: 'DSD 256',
      ),
      ArchivalSession(
        id: 'session-2',
        title: 'Field Recordings: Kyoto Rain',
        subtitle: 'Stereo Spatial Array • 45m',
        badge: '96/24',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCvj6GPvfHLZZ9DEypg_tTiBMzkSAmKXvcyNyfxRAd6T9oT_xaBii0CTiSmoe7AVilxBRgEDAf18Gz2A5PBc_x5kM9xcp1QLIe_b0aydcfF-WUIvgigh6Xqy70t5hxW5WoT-ngqfVGZtn75XR8mTOAE9feDmoMMz9TJRzSId8dNRRnhTQaIYmU_EvCWYbfmUhGQ_TKAVJSknCiu2oivj0Hb2JdgDUEa_BCqEV4mINhtMRPbwZBHAftibg',
        duration: '45m',
        format: 'FLAC 96/24',
      ),
      ArchivalSession(
        id: 'session-3',
        title: 'The Berlin Piano Sessions',
        subtitle: 'Bösendorfer 290 Imperial • 52m',
        badge: 'DSD64',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBkpODXUDaosw-F421ETXLhjyMBbWzRIbd-GCZFYq8n1QCeNYVDpn0dcIOnIt1Zstyx4y2s0-xduJIHbdT-TP1qzXvP-TeijaGnn4JsLadQkjzcxsWSZY3UBtSf5yjXgJQy1SUPpzw6uIg2bCVVEMdBkZlqm_RlrVw3mci_e1oqaXuvFhzfoFEjn-WOAdq7Otu1960g7LpL1XEaOOoUPY0K1O1BCD3SVi_dEYVYUq0P7jPSPD4zHe3Csg',
        duration: '52m',
        format: 'DSD 64',
      ),
    ],
    this.sonicCategories = const [
      SonicSpectrumCategory(
        id: 'cat-1',
        tag: 'CHAMBER',
        title: 'Neo-Classical & Strings',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBEfrmVVR5HijeroGtJrMewyaDq9huUVh_EeUAe2bHxj1NaQYCNlFCo3eQUF0MyQzcDl1_zyPbmv4ZE_Wx8wx2ZNGXtZr0mVxJAai_qiX23DaC78Dlbh8GqPLKd5cZDMQpvt7x6zQToOw-_9jq0Bghl6QzW4uvqcuASKwH3UFC3jxUXf6uOo7ywiG1bto9Bq5InV9md5rIxtxqAxkzivj9Fy-T2uCMehxBYsk-xmYhZ5d2hIpyL88Jymw',
      ),
      SonicSpectrumCategory(
        id: 'cat-2',
        tag: 'DEEP RES',
        title: 'Deep Ambient & Drone',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDJRUAw6Pvpa9AoKaJz87TvUfc4IixWrsBNTQiWfj6UAobJYHN1vSTT2gs496SbkGY0IDAIS7WP5szDp26hH2Va-WE0zFqUi6-xPML6gDU5ReRuQYsnI3uuVok3GLvjwLAJS9lnKElOuKhb_5aLpSJOQ8FgYH6uzvkWNvPN2yKAdwq85TcpaivFLzV9BSqF9W2bFlmYl3Rq3EKMMYtetlEhz_4y2vQOmdkDT1RZrOem1pAfMoVkuiOzgg',
      ),
      SonicSpectrumCategory(
        id: 'cat-3',
        tag: 'ACOUSTIC',
        title: 'Contemporary Jazz & Brass',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuD69lD0nTWky2s22Z6A5YPLSGegCqSl2aKNLW-Tte1lrCZ9dclFHIEsBTBLceeayAyZHhswjeAD5oHnAbU4sMs5N8w5klQTEOXVxLWP1iUJQyZjcVTU6fA9dOeMENsmXzM4CrIkbRhK_m_fqPTqnofBM9MwjHBH1YGGW9r_nYb2s83jHNaTIU0K5Y4HZgKzmMFPhxyhICzNaZiBDGrGI5uo-PC_sygF1hpExLp4p2Hb5RAfRFriKMPIaQ',
      ),
      SonicSpectrumCategory(
        id: 'cat-4',
        tag: 'SYNTHESIS',
        title: 'Minimalist Electronic',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBtENMsukji3K3yYHEuYnSCRzA9u4_l1a41XQUU7kpkvPTDgzNZItpoxphTxnsDhUWMp6hRiBnqxwBYx5bKWQDCXkuOI8HYQ-TW8LSBlBwY7XWgp-wRrew2FtDYg3utotuXYa7R1uSUUDKpUzv03rwn_96cQG-LWSfrEjqVGWYMf_1knYYICNVDny8YLUjhJTEukcmrFE0emhJL42R0SIBELXLbgoDP0lUs5gRph-sPaIv26o2udoBBlg',
      ),
      SonicSpectrumCategory(
        id: 'cat-5',
        tag: 'HERITAGE',
        title: 'World Archives & Sacred',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCSbWlkCSO9EFBOE-SqgCHXOWExd-kXCiwdNbb57-2hiaMpbJyyThU6bJONlJgNUJMrdmalXJN-Xni-xJv5gM0K9pCwxaf5J594fl-uZj7jwvMOOaLpYZeaVHFYvB8y58DIy9AqQxMsfn_Q3wi9oLZOvIbPfoWyoCUwu5uBTTxUAH-TIqhK7MTILnAmLxYgDey6DiLqQ1FcvAC5ENyVK4EH1MnuQ3OGSdItGbH4puKtttcO8Ffkzjg0gw',
      ),
      SonicSpectrumCategory(
        id: 'cat-6',
        tag: '32-BIT FLOAT',
        title: 'Audiophile Vinyl Rips',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuClQh03hYMZ3wRYD2w3gocQD7cBKnz83wOtCcUvRFRUVCic5owPo3ETLNPuu2T_UaHd4fadxG5pfaOPLLSf0TbW5XXCoGeZur_vHxJ-fwV8KAcTayz1G5rvexZPO2-SVSH2olF--MRUHBExx4sLbSlEFrf-y85J0rJOzabmiJKNCcWEYeT0DrxD1z8-lHKAkkfGNxz1Wumj9rjGxUn_cZ-Qx0Pg00uRTYtJbF8tptJT7mfutSF2JQQLcQ',
      ),
    ],
  });

  bool get isSearching => query.trim().isNotEmpty;
  bool get hasResults =>
      searchResults.isNotEmpty ||
      artistResults.isNotEmpty ||
      albumResults.isNotEmpty;

  SearchState copyWith({
    String? query,
    bool? isLoading,
    String? errorMessage,
    List<Song>? searchResults,
    List<Artist>? artistResults,
    List<Album>? albumResults,
    String? activeCategory,
    String? selectedFilter,
    List<String>? availableFilters,
    List<ArchivalSession>? allSessions,
    List<ArchivalSession>? filteredSessions,
    List<SonicSpectrumCategory>? sonicCategories,
  }) {
    return SearchState(
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchResults: searchResults ?? this.searchResults,
      artistResults: artistResults ?? this.artistResults,
      albumResults: albumResults ?? this.albumResults,
      activeCategory: activeCategory ?? this.activeCategory,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      availableFilters: availableFilters ?? this.availableFilters,
      allSessions: allSessions ?? this.allSessions,
      filteredSessions: filteredSessions ?? this.filteredSessions,
      sonicCategories: sonicCategories ?? this.sonicCategories,
    );
  }

  @override
  List<Object?> get props => [
        query,
        isLoading,
        errorMessage,
        searchResults,
        artistResults,
        albumResults,
        activeCategory,
        selectedFilter,
        availableFilters,
        allSessions,
        filteredSessions,
        sonicCategories,
      ];
}

// ─── BLoC ────────────────────────────────────────────────────────────────────

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final MusicRepository _musicRepository;
  Timer? _debounceTimer;

  SearchBloc({MusicRepository? musicRepository})
      : _musicRepository =
            musicRepository ?? MusicRepository(RemoteMusicService()),
        super(const SearchState()) {
    on<SearchQueryChanged>(_onQueryChanged);
    on<SearchPerformSearch>(_onPerformSearch);
    on<SearchCategoryChanged>(_onCategoryChanged);
    on<SearchFilterSelected>(_onFilterSelected);
    on<SearchQueryCleared>(_onQueryCleared);
  }

  Future<void> _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    final rawQuery = event.query;
    final trimmed = rawQuery.trim();
    _debounceTimer?.cancel();

    if (trimmed.isEmpty) {
      emit(state.copyWith(
        query: '',
        isLoading: false,
        searchResults: const [],
        artistResults: const [],
        albumResults: const [],
        errorMessage: null,
        filteredSessions: state.allSessions,
      ));
      return;
    }

    // Local instant filter for immediate UI feedback
    final qLower = trimmed.toLowerCase();
    final localMatches = state.allSessions.where((s) {
      return s.title.toLowerCase().contains(qLower) ||
          s.subtitle.toLowerCase().contains(qLower) ||
          s.badge.toLowerCase().contains(qLower);
    }).toList();

    emit(state.copyWith(
      query: rawQuery,
      isLoading: true,
      errorMessage: null,
      filteredSessions: localMatches,
    ));

    // Debounce global network API call by 350ms
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (!isClosed) {
        add(SearchPerformSearch(trimmed));
      }
    });
  }

  Future<void> _onPerformSearch(
    SearchPerformSearch event,
    Emitter<SearchState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) return;

    emit(state.copyWith(query: query, isLoading: true, errorMessage: null));

    try {
      final results = await Future.wait([
        _musicRepository.searchSongs(query).catchError((_) => <Song>[]),
        _musicRepository.searchArtists(query).catchError((_) => <Artist>[]),
        _musicRepository.searchAlbums(query).catchError((_) => <Album>[]),
      ]);

      final songs = results[0] as List<Song>;
      final artists = results[1] as List<Artist>;
      final albums = results[2] as List<Album>;

      // Verify the current query hasn't changed while awaiting response
      if (state.query.trim().toLowerCase() == query.toLowerCase()) {
        emit(state.copyWith(
          isLoading: false,
          searchResults: songs,
          artistResults: artists,
          albumResults: albums,
          errorMessage: null,
        ));
      }
    } catch (e) {
      if (state.query.trim().toLowerCase() == query.toLowerCase()) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage:
              'Failed to search audio archives. Please check network connection.',
        ));
      }
    }
  }

  void _onCategoryChanged(
    SearchCategoryChanged event,
    Emitter<SearchState> emit,
  ) {
    emit(state.copyWith(activeCategory: event.category));
  }

  Future<void> _onFilterSelected(
    SearchFilterSelected event,
    Emitter<SearchState> emit,
  ) async {
    emit(state.copyWith(selectedFilter: event.filter));
    add(SearchQueryChanged(event.filter));
  }

  Future<void> _onQueryCleared(
    SearchQueryCleared event,
    Emitter<SearchState> emit,
  ) async {
    _debounceTimer?.cancel();
    emit(state.copyWith(
      query: '',
      isLoading: false,
      searchResults: const [],
      artistResults: const [],
      albumResults: const [],
      errorMessage: null,
      filteredSessions: state.allSessions,
    ));
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}

// Aliases for BrowseScreen conventions
typedef BrowseBloc = SearchBloc;
typedef BrowseEvent = SearchEvent;
typedef BrowseState = SearchState;
