import 'package:flutter_test/flutter_test.dart';
import 'package:sangeet/player/bloc/player_bloc.dart';
import 'package:sangeet/main_layout/bloc/main_layout_bloc.dart';
import 'package:sangeet/home/bloc/home_bloc.dart';
import 'package:sangeet/profile/bloc/profile_bloc.dart';
import 'package:sangeet/search/bloc/search_bloc.dart';
import 'package:sangeet/library/bloc/library_bloc.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PlayerBloc initializes with empty queue', () {
    final bloc = PlayerBloc();
    expect(bloc.state.queue.isEmpty, true);
    expect(bloc.state.currentTrack, isNull);
    bloc.close();
  });

  test('MainLayoutBloc starts on listen tab and can switch tabs', () async {
    final bloc = MainLayoutBloc();
    expect(bloc.state.activeTab, NavTab.listen);

    bloc.add(const NavigationTabChanged(NavTab.library));
    await pumpEventQueue();
    expect(bloc.state.activeTab, NavTab.library);

    bloc.add(const NavigationTabChanged(NavTab.browse));
    await pumpEventQueue();
    expect(bloc.state.activeTab, NavTab.browse);

    bloc.add(const NavigationTabChanged(NavTab.profile));
    await pumpEventQueue();
    expect(bloc.state.activeTab, NavTab.profile);

    bloc.close();
  });

  test('HomeBloc starts with All selected', () {
    final bloc = HomeBloc();
    expect(bloc.state.selectedFilter, 'All');
    bloc.close();
  });

  test(
    'ProfileBloc initializes with default audiophile state and handles toggles',
    () async {
      final bloc = ProfileBloc();
      expect(bloc.state.userName, 'Music Lover');
      expect(bloc.state.exclusiveMode, false);
      expect(bloc.state.hoursListened, '142');

      bloc.add(const ProfileExclusiveModeToggled());
      await pumpEventQueue();
      expect(bloc.state.exclusiveMode, true);

      bloc.add(const ProfileGearSwitched('Focal Bathys'));
      await pumpEventQueue();
      expect(bloc.state.activeGear, 'Focal Bathys');

      bloc.add(const ProfileCacheCleared());
      await pumpEventQueue();
      expect(bloc.state.cacheSizeMb, 0.0);

      bloc.close();
    },
  );

  test(
    'SearchBloc initializes with default filters and filters sessions',
    () async {
      final bloc = SearchBloc();
      expect(bloc.state.selectedFilter, 'Classical');
      expect(bloc.state.allSessions.length, 3);
      expect(bloc.state.filteredSessions.length, 3);
      expect(bloc.state.isSearching, false);

      bloc.add(const SearchFilterSelected('Ambient'));
      await pumpEventQueue();
      expect(bloc.state.selectedFilter, 'Ambient');

      bloc.add(const SearchQueryChanged('Kyoto'));
      await pumpEventQueue();
      expect(bloc.state.isSearching, true);
      expect(bloc.state.filteredSessions.length, 1);
      expect(bloc.state.filteredSessions.first.title, contains('Kyoto Rain'));

      bloc.add(const SearchQueryCleared());
      await pumpEventQueue();
      expect(bloc.state.isSearching, false);
      expect(bloc.state.filteredSessions.length, 3);

      bloc.close();
    },
  );

  test(
    'LibraryBloc initializes with default playlists and handles events',
    () async {
      final bloc = LibraryBloc();
      expect(bloc.state.selectedFilter, 'Playlists');
      expect(bloc.state.isGridView, true);
      expect(bloc.state.playlists.length, 0);
      expect(bloc.state.recentTracks.length, 0);
      expect(bloc.state.followedArtists.length, 5);

      bloc.add(const LibraryFilterSelected('Downloaded'));
      await pumpEventQueue();
      expect(bloc.state.selectedFilter, 'Downloaded');

      bloc.add(const LibrarySortChanged('Alphabetical (A-Z)'));
      await pumpEventQueue();
      expect(bloc.state.currentSort, 'Alphabetical (A-Z)');

      bloc.add(const LibraryViewModeToggled(false));
      await pumpEventQueue();
      expect(bloc.state.isGridView, false);

      bloc.add(const LibraryPlaylistCreated('New Audiophile Vault'));
      await pumpEventQueue();
      expect(bloc.state.playlists.length, 1);
      expect(bloc.state.playlists.first.title, 'New Audiophile Vault');

      bloc.close();
    },
  );
}
