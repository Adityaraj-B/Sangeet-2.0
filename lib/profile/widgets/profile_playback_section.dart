import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../theme/theme.dart';
import '../bloc/profile_bloc.dart';

/// Clean playback and audio settings section including audio quality,
/// equalizer presets, crossfade, Wi-Fi only streaming, and volume normalization.
class ProfilePlaybackSection extends StatelessWidget {
  final ProfileState state;

  const ProfilePlaybackSection({super.key, required this.state});

  void _showStreamingQualitySheet(BuildContext context, String currentQuality) {
    HapticFeedback.lightImpact();
    final options = [
      {'title': 'Data Saver (96 kbps)', 'desc': 'Lowest data usage, suitable for slow connections'},
      {'title': 'Normal (160 kbps)', 'desc': 'Balanced audio quality and data consumption'},
      {'title': 'High (320 kbps)', 'desc': 'Crisp, punchy MP3/AAC audio (Recommended)'},
      {'title': 'Hi-Res Lossless (FLAC)', 'desc': 'Direct studio master uncompressed fidelity'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Streaming Audio Quality',
                  style: AppTypography.titleLg(color: AppColors.primaryText),
                ),
              ),
              const SizedBox(height: 12),
              ...options.map((opt) {
                final isSelected = currentQuality == opt['title'];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                  leading: Icon(
                    isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                    color: isSelected ? AppColors.secondaryAccent : AppColors.outline,
                  ),
                  title: Text(
                    opt['title']!,
                    style: AppTypography.titleSm(
                      color: isSelected ? AppColors.secondaryAccent : AppColors.primaryText,
                    ).copyWith(fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
                  ),
                  subtitle: Text(
                    opt['desc']!,
                    style: AppTypography.bodySm(color: AppColors.outline),
                  ),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.read<ProfileBloc>().add(ProfileStreamingQualityChanged(opt['title']!));
                    Navigator.of(bottomSheetContext).pop();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showDownloadQualitySheet(BuildContext context, String currentQuality) {
    HapticFeedback.lightImpact();
    final options = [
      {'title': 'Standard (160 kbps)', 'desc': 'Uses less storage space per song (~3 MB)'},
      {'title': 'High (320 kbps)', 'desc': 'Great balance of quality and storage (~8 MB)'},
      {'title': 'Very High (Lossless)', 'desc': 'Highest quality offline audio (~30 MB)'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Download Audio Quality',
                  style: AppTypography.titleLg(color: AppColors.primaryText),
                ),
              ),
              const SizedBox(height: 12),
              ...options.map((opt) {
                final isSelected = currentQuality == opt['title'];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                  leading: Icon(
                    isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                    color: isSelected ? AppColors.secondaryAccent : AppColors.outline,
                  ),
                  title: Text(
                    opt['title']!,
                    style: AppTypography.titleSm(
                      color: isSelected ? AppColors.secondaryAccent : AppColors.primaryText,
                    ).copyWith(fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
                  ),
                  subtitle: Text(
                    opt['desc']!,
                    style: AppTypography.bodySm(color: AppColors.outline),
                  ),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.read<ProfileBloc>().add(ProfileDownloadQualityChanged(opt['title']!));
                    Navigator.of(bottomSheetContext).pop();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showEqualizerSheet(BuildContext context, String currentPreset) {
    HapticFeedback.lightImpact();
    final presets = [
      'Balanced',
      'Bass Boost',
      'Acoustic',
      'Vocal Clarity',
      'Pop',
      'Rock & Punch',
      'Electronic',
      'Treble Booster',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Equalizer Presets',
                  style: AppTypography.titleLg(color: AppColors.primaryText),
                ),
              ),
              const SizedBox(height: 12),
              ...presets.map((preset) {
                final isSelected = currentPreset == preset;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  leading: Icon(
                    isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color: isSelected ? AppColors.secondaryAccent : AppColors.outline,
                    size: 20,
                  ),
                  title: Text(
                    preset,
                    style: AppTypography.titleSm(
                      color: isSelected ? AppColors.secondaryAccent : AppColors.primaryText,
                    ).copyWith(fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
                  ),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.read<ProfileBloc>().add(ProfileEqualizerPresetSelected(preset));
                    Navigator.of(bottomSheetContext).pop();
                  },
                );
              }),
            ],
          ),
        );
      },
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
            'PLAYBACK & AUDIO',
            style: AppTypography.labelSm(color: AppColors.outline).copyWith(
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.16),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Streaming Quality Tile
              _SettingTile(
                title: 'Streaming Quality',
                subtitle: state.streamingQuality,
                icon: Icons.graphic_eq_rounded,
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.outline, size: 20),
                onTap: () => _showStreamingQualitySheet(context, state.streamingQuality),
              ),
              _buildDivider(),

              // Download Quality Tile
              _SettingTile(
                title: 'Download Quality',
                subtitle: state.downloadQuality,
                icon: Icons.file_download_outlined,
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.outline, size: 20),
                onTap: () => _showDownloadQualitySheet(context, state.downloadQuality),
              ),
              _buildDivider(),

              // Equalizer Preset Tile
              _SettingTile(
                title: 'Equalizer',
                subtitle: state.equalizerPreset,
                icon: Icons.tune_rounded,
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.outline, size: 20),
                onTap: () => _showEqualizerSheet(context, state.equalizerPreset),
              ),
              _buildDivider(),

              // Crossfade Tile
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.compare_arrows_rounded, color: AppColors.primaryText, size: 18),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Crossfade Songs',
                                style: AppTypography.titleSm(color: AppColors.primaryText).copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                state.crossfadeEnabled
                                    ? '${state.crossfadeDuration}s transition between songs'
                                    : 'Off (Standard gap between tracks)',
                                style: AppTypography.bodySm(color: AppColors.outline),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: state.crossfadeEnabled,
                          activeTrackColor: AppColors.secondaryAccent,
                          onChanged: (_) {
                            HapticFeedback.lightImpact();
                            context.read<ProfileBloc>().add(const ProfileCrossfadeToggled());
                          },
                        ),
                      ],
                    ),
                    if (state.crossfadeEnabled) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('1s', style: AppTypography.labelSm(color: AppColors.outline)),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: AppColors.secondaryAccent,
                                inactiveTrackColor: AppColors.surfaceContainerHigh,
                                thumbColor: AppColors.secondaryAccent,
                                overlayColor: AppColors.secondaryAccent.withValues(alpha: 0.15),
                                trackHeight: 3,
                              ),
                              child: Slider(
                                value: state.crossfadeDuration.toDouble(),
                                min: 1,
                                max: 12,
                                divisions: 11,
                                label: '${state.crossfadeDuration}s',
                                onChanged: (val) {
                                  context.read<ProfileBloc>().add(
                                        ProfileCrossfadeDurationChanged(val.round()),
                                      );
                                },
                              ),
                            ),
                          ),
                          Text('12s', style: AppTypography.labelSm(color: AppColors.outline)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              _buildDivider(),

              // Stream on Wi-Fi Only Switch
              _SettingTile(
                title: 'Stream on Wi-Fi Only',
                subtitle: 'Reduces mobile data consumption',
                icon: Icons.wifi_rounded,
                trailing: Switch.adaptive(
                  value: state.streamWifiOnly,
                  activeTrackColor: AppColors.secondaryAccent,
                  onChanged: (_) {
                    HapticFeedback.lightImpact();
                    context.read<ProfileBloc>().add(const ProfileWifiOnlyToggled());
                  },
                ),
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.read<ProfileBloc>().add(const ProfileWifiOnlyToggled());
                },
              ),
              _buildDivider(),

              // Normalize Volume Switch
              _SettingTile(
                title: 'Normalize Volume',
                subtitle: 'Maintains consistent loudness across tracks',
                icon: Icons.volume_up_rounded,
                trailing: Switch.adaptive(
                  value: state.normalizeVolume,
                  activeTrackColor: AppColors.secondaryAccent,
                  onChanged: (_) {
                    HapticFeedback.lightImpact();
                    context.read<ProfileBloc>().add(const ProfileNormalizeVolumeToggled());
                  },
                ),
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.read<ProfileBloc>().add(const ProfileNormalizeVolumeToggled());
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: AppColors.outlineVariant.withValues(alpha: 0.14),
      height: 1,
      indent: 56,
      endIndent: 16,
    );
  }
}

class _SettingTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget trailing;
  final VoidCallback onTap;

  const _SettingTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primaryText, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleSm(color: AppColors.primaryText).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySm(color: AppColors.outline),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
