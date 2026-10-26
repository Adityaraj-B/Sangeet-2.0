import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../home/screens/recent_listening_screen.dart';
import '../screens/liked_songs_screen.dart';
import '../screens/downloaded_songs_screen.dart';
import '../../insights/screens/insights_tab_screen.dart';
import '../../theme/theme.dart';
import '../bloc/library_bloc.dart';

class LibraryFilterPills extends StatelessWidget {
  final LibraryState state;

  const LibraryFilterPills({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: state.availableFilters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = state.availableFilters[index];
          final isSelected = filter == state.selectedFilter;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              if (filter == 'History') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const RecentListeningScreen(),
                  ),
                );
              } else if (filter == 'Liked Songs') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LikedSongsScreen(),
                  ),
                );
              } else if (filter == 'Downloaded') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const DownloadedSongsScreen(),
                  ),
                );
              } else if (filter == 'Insights' || filter == 'Listening Insights') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const InsightsTabScreen(),
                  ),
                );
              } else {
                context.read<LibraryBloc>().add(LibraryFilterSelected(filter));
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.secondary
                    : AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? AppColors.secondary
                      : AppColors.outlineVariant.withValues(alpha: 0.12),
                  width: 0.8,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                filter.toUpperCase(),
                style: AppTypography.labelSm(
                  color: isSelected ? AppColors.onSecondary : AppColors.onSurfaceVariant,
                ).copyWith(
                  fontSize: 10,
                  letterSpacing: 0.8,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
