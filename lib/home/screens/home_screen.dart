import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../library/screens/downloaded_songs_screen.dart';
import '../../repositories/music_repository.dart';
import '../../services/connectivity_service.dart';
import '../../theme/theme.dart';
import '../widgets/editorial_header.dart';
import '../widgets/banner.dart';
import '../widgets/recent_listening.dart';
import '../widgets/trending_albums.dart';
import '../widgets/home_playlists.dart';
import '../widgets/acoustic_quote.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Alias for backwards compatibility
typedef ListenScreen = HomeScreen;

class _HomeScreenState extends State<HomeScreen> {
  int _refreshCounter = 0;
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    HapticFeedback.mediumImpact();

    // 1. Actively test and refresh internet connectivity
    final isOnline = await ConnectivityService.instance.checkConnection();

    // 2. Clear in-memory caches
    MusicRepository.instance.clearCache();
    HomeBanner.clearCache();
    TrendingAlbumsSection.clearCache();

    // 3. Pre-fetch fresh items if internet is back
    if (isOnline) {
      try {
        await Future.wait([
          MusicRepository.instance.getTrending(),
          MusicRepository.instance.getTrendingAlbums(limit: 10),
        ]);
      } catch (_) {}
    }

    if (!mounted) return;

    setState(() {
      _refreshCounter++;
      _isRefreshing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            Icon(
              isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
              color: isOnline ? const Color(0xFF26A69A) : const Color(0xFFE5A93C),
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isOnline
                    ? 'Connected! Refreshed latest studio music.'
                    : 'Still offline. You can listen to your downloaded songs.',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 4;
    // Space for floating mini-player + bottom nav
    const bottomPad = 24.0 + 80.0 + 64.0;

    return RefreshIndicator(
      color: AppColors.secondary,
      backgroundColor: AppColors.surfaceContainerHigh,
      displacement: top + 16,
      strokeWidth: 2.4,
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.only(top: top, bottom: bottomPad),
        child: Column(
          key: ValueKey(_refreshCounter),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EditorialHeader(),
            _HomeOfflineCard(
              onRefreshTap: _handleRefresh,
              isRefreshing: _isRefreshing,
            ),
            const HomeBanner(),
            const RecentListening(),
            const TrendingAlbumsSection(),
            const HomePlaylistsSection(),
            const AcousticQuote(),
          ],
        ),
      ),
    );
  }
}

/// Offline notice card shown on the Home screen when no internet connection is detected.
///
/// Provides a direct action chip to navigate to [DownloadedSongsScreen] and a manual Refresh button.
class _HomeOfflineCard extends StatelessWidget {
  final Future<void> Function() onRefreshTap;
  final bool isRefreshing;

  const _HomeOfflineCard({
    required this.onRefreshTap,
    required this.isRefreshing,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ConnectivityService.instance.isOnlineNotifier,
      builder: (context, _) {
        final isOnline = ConnectivityService.instance.isOnline;
        if (isOnline) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 18),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF191612).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFC5A059).withValues(alpha: 0.35),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC5A059).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.wifi_off_rounded,
                        size: 17,
                        color: Color(0xFFE5A93C),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Offline Mode Active',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: isRefreshing ? null : onRefreshTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.outlineVariant.withValues(alpha: 0.2),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isRefreshing)
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.8,
                                color: Color(0xFFC5A059),
                              ),
                            )
                          else
                            const Icon(
                              Icons.refresh_rounded,
                              size: 14,
                              color: Color(0xFFC5A059),
                            ),
                          const SizedBox(width: 5),
                          Text(
                            isRefreshing ? 'Checking...' : 'Refresh',
                            style: const TextStyle(
                              color: Color(0xFFC5A059),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'No internet connection detected. You can listen to your downloaded songs offline without interruption, or pull down to refresh when reconnected.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC5A059),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.offline_pin_rounded,
                    size: 16,
                    color: Colors.black,
                  ),
                  label: const Text(
                    'Play Downloaded Songs',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      letterSpacing: -0.1,
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DownloadedSongsScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
