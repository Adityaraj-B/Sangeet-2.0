import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/auth.dart';
import '../../theme/theme.dart';
import '../bloc/profile_bloc.dart';

/// Clean Account & App section including Plan details, Notifications toggle,
/// About Sangeet, Privacy Policy, and Sign Out confirmation.
class ProfileAccountSection extends StatelessWidget {
  final ProfileState state;

  const ProfileAccountSection({super.key, required this.state});

  void _showAboutDialog(BuildContext context) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceContainerLow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondaryAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.music_note_rounded,
                  color: AppColors.secondaryAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Sangeet',
                style: AppTypography.titleLg(color: AppColors.primaryText),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'High-Fidelity Music Streaming Experience',
                style: AppTypography.bodyMd(color: AppColors.primaryText).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sangeet brings studio-grade acoustics, lossless streaming, and offline playback to your fingertips with a minimalist, distraction-free aesthetic.',
                style: AppTypography.bodySm(color: AppColors.outline),
              ),
              const SizedBox(height: 16),
              Text(
                'Version: 2.4.0 (Build 240)\nAudio Engine: ExoPlayer / AudioService\nFramework: Flutter 3.x',
                style: AppTypography.labelSm(color: AppColors.outlineVariant),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Close',
                style: AppTypography.labelMd(color: AppColors.secondaryAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceContainerLow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Terms & Privacy',
            style: AppTypography.titleLg(color: AppColors.primaryText),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Privacy Guarantee',
                  style: AppTypography.titleSm(color: AppColors.secondaryAccent),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your playback history and playlists are stored locally and encrypted securely when synced to your cloud account. We never sell your personal data or listening habits.',
                  style: AppTypography.bodySm(color: AppColors.outline),
                ),
                const SizedBox(height: 12),
                Text(
                  'Offline Storage',
                  style: AppTypography.titleSm(color: AppColors.secondaryAccent),
                ),
                const SizedBox(height: 4),
                Text(
                  'All offline downloads are kept securely within the app\'s sandbox vault strictly for your personal listening enjoyment.',
                  style: AppTypography.bodySm(color: AppColors.outline),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Got It',
                style: AppTypography.labelMd(color: AppColors.secondaryAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmSignOut(BuildContext context) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceContainerLow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Log Out?',
            style: AppTypography.titleLg(color: AppColors.primaryText),
          ),
          content: Text(
            'Are you sure you want to log out of your Sangeet account? Your offline songs and playlists will remain safe on your device.',
            style: AppTypography.bodySm(color: AppColors.outline),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: AppTypography.labelMd(color: AppColors.onSurfaceVariant),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<AuthBloc>().add(const AuthSignOutRequested());
              },
              child: Text(
                'Log Out',
                style: AppTypography.labelMd(color: AppColors.error).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
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
            'ACCOUNT & APP',
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
              // Notifications
              _AccountTile(
                title: 'Notifications',
                subtitle: 'New song releases & playlist recommendations',
                icon: Icons.notifications_outlined,
                trailing: Switch.adaptive(
                  value: state.notificationsEnabled,
                  activeTrackColor: AppColors.secondaryAccent,
                  onChanged: (_) {
                    HapticFeedback.lightImpact();
                    context.read<ProfileBloc>().add(const ProfileNotificationsToggled());
                  },
                ),
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.read<ProfileBloc>().add(const ProfileNotificationsToggled());
                },
              ),
              _buildDivider(),

              // About Sangeet
              _AccountTile(
                title: 'About Sangeet',
                subtitle: 'Version 2.4.0 (Build 240)',
                icon: Icons.info_outline_rounded,
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.outline, size: 20),
                onTap: () => _showAboutDialog(context),
              ),
              _buildDivider(),

              // Terms & Privacy
              _AccountTile(
                title: 'Terms & Privacy Policy',
                subtitle: 'Data usage & licensing information',
                icon: Icons.privacy_tip_outlined,
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.outline, size: 20),
                onTap: () => _showPrivacyDialog(context),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Log Out Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => _confirmSignOut(context),
            icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
            label: Text(
              'Log Out',
              style: AppTypography.labelLg(color: AppColors.error).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(
                color: AppColors.error.withValues(alpha: 0.35),
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Subtle copyright / version text
        Center(
          child: Text(
            'SANGEET · CRAFTED FOR MUSIC LOVERS',
            style: AppTypography.labelSm(
              color: AppColors.outline.withValues(alpha: 0.6),
            ).copyWith(letterSpacing: 1.5, fontSize: 10),
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

class _AccountTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget trailing;
  final VoidCallback onTap;

  const _AccountTile({
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
