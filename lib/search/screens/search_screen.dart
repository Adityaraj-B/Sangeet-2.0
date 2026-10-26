import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/search_bloc.dart';
import '../widgets/search_bar_header.dart';
import '../widgets/sound_architecture_section.dart';
import '../widgets/sonic_spectra_section.dart';
import '../widgets/curated_sessions_section.dart';

import '../widgets/global_search_results_section.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SearchBloc>(
      create: (_) => SearchBloc(),
      child: const _SearchScreenView(),
    );
  }
}

// Aliases for Browse tab backwards compatibility
typedef BrowseScreen = SearchScreen;

class _SearchScreenView extends StatelessWidget {
  const _SearchScreenView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        return _SearchBody(state: state);
      },
    );
  }
}

class _SearchBody extends StatelessWidget {
  final SearchState state;

  const _SearchBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top + 12;
    // Space for floating mini player + bottom nav bar + on-screen keyboard when typing
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomPadding = 24.0 + 80.0 + 64.0 + keyboardInset;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        top: topPadding,
        bottom: bottomPadding,
        left: 20,
        right: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dynamic Header + Search Input Bar + Filter Chips
          SearchBarHeader(state: state),
          const SizedBox(height: 24),

          // When searching, show live global search results
          if (state.isSearching) ...[
            GlobalSearchResultsSection(state: state),
          ] else ...[
            // Section 1: Sound Architecture (Curated Editorial Master Cards)
            const SoundArchitectureSection(),
            const SizedBox(height: 24),

            // Section 2: Browse by Genre & Mood (2-Column Grid)
            SonicSpectraSection(categories: state.sonicCategories),
            const SizedBox(height: 24),

            // Section 3: Curated Sessions (Listening History)
            const CuratedSessionsSection(),
          ],
        ],
      ),
    );
  }
}
