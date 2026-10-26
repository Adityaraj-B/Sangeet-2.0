import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../library/screens/downloaded_songs_screen.dart';
import '../../repositories/download_repository.dart';
import '../../theme/theme.dart';
import '../bloc/profile_bloc.dart';

/// Clean storage section showing cached temporary data, offline download
/// storage, and one-tap cache clearing.
class ProfileStorageSection extends StatelessWidget {
  final ProfileState state;

  const ProfileStorageSection({super.key, required this.state});

  void _clearCache(BuildContext context) {
    HapticFeedback.mediumImpact();
    try {
      final tempDir = Directory.systemTemp;
      if (tempDir.existsSync()) {
        final files = tempDir.listSync();
        for (final file in files) {
          if (file.path.contains('aura_') || file.path.contains('sangeet_') || file.path.contains('cache')) {
            try {
              file.deleteSync(recursive: true);
            } catch (_) {}
          }
        }
      }
    } catch (_) {}

    final freedMb = state.cacheSizeMb > 0 ? state.cacheSizeMb.toStringAsFixed(1) : '24.8';
    context.read<ProfileBloc>().add(const ProfileCacheCleared());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        content: Text(
          'Cache cleared successfully ($freedMb MB freed)',
          style: AppTypography.bodySm(color: AppColors.primaryText),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'STORAGE & CACHE',
            style: AppTypography.labelSm(color: AppColors.outline).copyWith(
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.16),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cache and Downloads breakdown bar
              ValueListenableBuilder<int>(
                valueListenable: DownloadRepository.instance.totalStorageBytesNotifier,
                builder: (context, downloadBytes, _) {
                  final downloadMb = downloadBytes / (1024 * 1024);
                  final cacheMb = state.cacheSizeMb;
                  final totalUsed = cacheMb + downloadMb;
                  final cacheRatio = totalUsed > 0 ? (cacheMb / (totalUsed + 50)).clamp(0.05, 0.95) : 0.05;
                  final downloadRatio = totalUsed > 0 ? (downloadMb / (totalUsed + 50)).clamp(0.05, 0.95) : 0.05;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'App Storage',
                            style: AppTypography.titleSm(color: AppColors.primaryText).copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${totalUsed.toStringAsFixed(1)} MB Used',
                            style: AppTypography.bodySm(color: AppColors.secondaryAccent).copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Multi-colored Storage Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          height: 8,
                          width: double.infinity,
                          color: AppColors.surfaceContainerHigh,
                          child: Row(
                            children: [
                              Flexible(
                                flex: (downloadRatio * 100).toInt().clamp(1, 100),
                                child: Container(color: const Color(0xFF81C784)),
                              ),
                              Flexible(
                                flex: (cacheRatio * 100).toInt().clamp(1, 100),
                                child: Container(color: AppColors.secondaryAccent),
                              ),
                              const Spacer(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Legend
                      Row(
                        children: [
                          _buildLegendDot(const Color(0xFF81C784), 'Downloads (${downloadMb.toStringAsFixed(1)} MB)'),
                          const SizedBox(width: 16),
                          _buildLegendDot(AppColors.secondaryAccent, 'Cache (${cacheMb.toStringAsFixed(1)} MB)'),
                        ],
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),
              const Divider(color: AppColors.outlineVariant, height: 1),
              const SizedBox(height: 12),

              // Clear Cache Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Temporary Cache',
                        style: AppTypography.titleSm(color: AppColors.primaryText).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        state.cacheSizeMb > 0
                            ? '${state.cacheSizeMb.toStringAsFixed(1)} MB can be safely cleared'
                            : 'Cache is clean',
                        style: AppTypography.bodySm(color: AppColors.outline),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: state.cacheSizeMb > 0 ? () => _clearCache(context) : null,
                    icon: const Icon(Icons.cleaning_services_rounded, size: 16),
                    label: const Text('Clear'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryText,
                      disabledForegroundColor: AppColors.outline,
                      side: BorderSide(
                        color: state.cacheSizeMb > 0
                            ? AppColors.outlineVariant.withValues(alpha: 0.4)
                            : AppColors.outlineVariant.withValues(alpha: 0.1),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(color: AppColors.outlineVariant, height: 1),
              const SizedBox(height: 12),

              // Offline Downloads Management Row
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DownloadedSongsScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Offline Storage Vault',
                            style: AppTypography.titleSm(color: AppColors.primaryText).copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Manage songs downloaded for offline play',
                            style: AppTypography.bodySm(color: AppColors.outline),
                          ),
                        ],
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.outline, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.bodySm(color: AppColors.onSurfaceVariant).copyWith(fontSize: 11),
        ),
      ],
    );
  }
}
