import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/auth.dart';
import '../../components/track_artwork.dart';
import '../../theme/theme.dart';
import '../bloc/profile_bloc.dart';

/// Clean, modern user profile header showing avatar, name, email,
/// subscription status chip, and edit profile action.
class ProfileHeader extends StatelessWidget {
  final ProfileState state;

  const ProfileHeader({super.key, required this.state});

  void _showEditProfileSheet(BuildContext context, String currentName, String currentAvatar) {
    HapticFeedback.lightImpact();
    final nameController = TextEditingController(text: currentName);
    final avatarController = TextEditingController(text: currentAvatar);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Profile',
                    style: AppTypography.titleLg(color: AppColors.primaryText),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.outline),
                    onPressed: () => Navigator.of(bottomSheetContext).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Display Name',
                style: AppTypography.labelSm(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                style: AppTypography.bodyMd(color: AppColors.primaryText),
                decoration: InputDecoration(
                  hintText: 'Enter your name',
                  hintStyle: AppTypography.bodyMd(color: AppColors.outline),
                  filled: true,
                  fillColor: AppColors.surfaceContainer,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.secondaryAccent, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Avatar Image URL (Optional)',
                style: AppTypography.labelSm(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: avatarController,
                style: AppTypography.bodyMd(color: AppColors.primaryText),
                decoration: InputDecoration(
                  hintText: 'https://...',
                  hintStyle: AppTypography.bodyMd(color: AppColors.outline),
                  filled: true,
                  fillColor: AppColors.surfaceContainer,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.secondaryAccent, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final newName = nameController.text.trim();
                    final newAvatar = avatarController.text.trim();
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(bottomSheetContext);
                    final profileBloc = context.read<ProfileBloc>();

                    if (newName.isNotEmpty) {
                      profileBloc.add(ProfileDisplayNameUpdated(newName));
                    }
                    if (newAvatar.isNotEmpty) {
                      profileBloc.add(ProfileAvatarUrlUpdated(newAvatar));
                    }

                    navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.surfaceContainerHigh,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        content: Text(
                          'Profile updated successfully',
                          style: AppTypography.bodySm(color: AppColors.primaryText),
                        ),
                      ),
                    );

                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        if (newName.isNotEmpty) await user.updateDisplayName(newName);
                        if (newAvatar.isNotEmpty) await user.updatePhotoURL(newAvatar);
                        await user.reload();
                      }
                    } catch (_) {}
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryAccent,
                    foregroundColor: AppColors.neutralCanvas,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Save Changes',
                    style: AppTypography.labelLg(color: AppColors.neutralCanvas).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSubscriptionSheet(BuildContext context, String currentPlan) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        final isPremium = currentPlan == 'Sangeet Premium';
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Plan',
                    style: AppTypography.titleLg(color: AppColors.primaryText),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.outline),
                    onPressed: () => Navigator.of(bottomSheetContext).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.secondaryAccent.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryAccent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: AppColors.secondaryAccent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentPlan,
                            style: AppTypography.titleMd(color: AppColors.primaryText),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isPremium ? 'Active subscription · \$4.99/mo' : 'Ad-supported free listener',
                            style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(Icons.check_circle_rounded, 'Hi-Res Lossless Audio Streaming'),
              const SizedBox(height: 8),
              _buildFeatureItem(Icons.check_circle_rounded, 'Unlimited Offline Downloads'),
              const SizedBox(height: 8),
              _buildFeatureItem(Icons.check_circle_rounded, 'Completely Ad-Free Listening'),
              const SizedBox(height: 8),
              _buildFeatureItem(Icons.check_circle_rounded, 'Unlimited Track Skips & Queuing'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final nextPlan = isPremium ? 'Free Plan' : 'Sangeet Premium';
                    context.read<ProfileBloc>().add(ProfilePlanChanged(nextPlan));
                    Navigator.of(bottomSheetContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.surfaceContainerHigh,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        content: Text(
                          'Plan changed to $nextPlan',
                          style: AppTypography.bodySm(color: AppColors.primaryText),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPremium ? AppColors.surfaceContainerHigh : AppColors.secondaryAccent,
                    foregroundColor: isPremium ? AppColors.primaryText : AppColors.neutralCanvas,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    isPremium ? 'Switch to Free Plan' : 'Upgrade to Premium (\$4.99/mo)',
                    style: AppTypography.labelLg(
                      color: isPremium ? AppColors.primaryText : AppColors.neutralCanvas,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.secondaryAccent, size: 16),
        const SizedBox(width: 10),
        Text(
          text,
          style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final authUser = authState.user;

    final displayName = (authUser?.displayName.isNotEmpty ?? false)
        ? authUser!.displayName
        : state.displayName;

    final email = (authUser?.email.isNotEmpty ?? false)
        ? authUser!.email
        : state.email;

    final avatarUrl = (authUser?.avatarUrl?.isNotEmpty ?? false)
        ? authUser!.avatarUrl!
        : state.avatarUrl;

    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar with Edit badge
              GestureDetector(
                onTap: () => _showEditProfileSheet(context, displayName, avatarUrl),
                child: Stack(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.secondaryAccent.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: SafeImage(
                          urlOrPath: avatarUrl,
                          fit: BoxFit.cover,
                          fallback: Container(
                            color: AppColors.surfaceContainerHigh,
                            alignment: Alignment.center,
                            child: Text(
                              initial,
                              style: AppTypography.headlineMd(
                                color: AppColors.secondaryAccent,
                              ).copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryAccent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surfaceContainerLow,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 12,
                          color: AppColors.neutralCanvas,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Name, Email, and Subscription Chip
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: AppTypography.titleLg(color: AppColors.primaryText).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      email,
                      style: AppTypography.bodySm(color: AppColors.outline),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Subscription Badge
                    GestureDetector(
                      onTap: () => _showSubscriptionSheet(context, state.planName),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: state.planName == 'Sangeet Premium'
                              ? AppColors.secondaryAccent.withValues(alpha: 0.15)
                              : AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: state.planName == 'Sangeet Premium'
                                ? AppColors.secondaryAccent.withValues(alpha: 0.4)
                                : AppColors.outlineVariant.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              state.planName == 'Sangeet Premium'
                                  ? Icons.workspace_premium_rounded
                                  : Icons.music_note_rounded,
                              size: 12,
                              color: state.planName == 'Sangeet Premium'
                                  ? AppColors.secondaryAccent
                                  : AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              state.planName.toUpperCase(),
                              style: AppTypography.labelSm(
                                color: state.planName == 'Sangeet Premium'
                                    ? AppColors.secondaryAccent
                                    : AppColors.onSurfaceVariant,
                              ).copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 12,
                              color: state.planName == 'Sangeet Premium'
                                  ? AppColors.secondaryAccent
                                  : AppColors.outline,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Edit Profile Action Button
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton.icon(
              onPressed: () => _showEditProfileSheet(context, displayName, avatarUrl),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: Text(
                'Edit Profile',
                style: AppTypography.labelMd(color: AppColors.primaryText).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryText,
                side: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.4),
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
