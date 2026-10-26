import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class ProfileDisplayNameUpdated extends ProfileEvent {
  final String name;
  const ProfileDisplayNameUpdated(this.name);

  @override
  List<Object?> get props => [name];
}

class ProfileAvatarUrlUpdated extends ProfileEvent {
  final String avatarUrl;
  const ProfileAvatarUrlUpdated(this.avatarUrl);

  @override
  List<Object?> get props => [avatarUrl];
}

class ProfileStreamingQualityChanged extends ProfileEvent {
  final String quality;
  const ProfileStreamingQualityChanged(this.quality);

  @override
  List<Object?> get props => [quality];
}

class ProfileDownloadQualityChanged extends ProfileEvent {
  final String quality;
  const ProfileDownloadQualityChanged(this.quality);

  @override
  List<Object?> get props => [quality];
}

class ProfileEqualizerPresetSelected extends ProfileEvent {
  final String preset;
  const ProfileEqualizerPresetSelected(this.preset);

  @override
  List<Object?> get props => [preset];
}

class ProfileCrossfadeToggled extends ProfileEvent {
  const ProfileCrossfadeToggled();
}

class ProfileCrossfadeDurationChanged extends ProfileEvent {
  final int durationSeconds;
  const ProfileCrossfadeDurationChanged(this.durationSeconds);

  @override
  List<Object?> get props => [durationSeconds];
}

class ProfileWifiOnlyToggled extends ProfileEvent {
  const ProfileWifiOnlyToggled();
}

class ProfileNormalizeVolumeToggled extends ProfileEvent {
  const ProfileNormalizeVolumeToggled();
}

class ProfileNotificationsToggled extends ProfileEvent {
  const ProfileNotificationsToggled();
}

class ProfilePlanChanged extends ProfileEvent {
  final String plan;
  const ProfilePlanChanged(this.plan);

  @override
  List<Object?> get props => [plan];
}

class ProfileCacheCleared extends ProfileEvent {
  const ProfileCacheCleared();
}

// Backwards compatibility events
class ProfileExclusiveModeToggled extends ProfileEvent {
  const ProfileExclusiveModeToggled();
}

class ProfileBitPerfectToggled extends ProfileEvent {
  const ProfileBitPerfectToggled();
}

class ProfileGearSwitched extends ProfileEvent {
  final String gearName;
  const ProfileGearSwitched(this.gearName);

  @override
  List<Object?> get props => [gearName];
}

// ─── State ───────────────────────────────────────────────────────────────────

class ProfileState extends Equatable {
  final String displayName;
  final String email;
  final String avatarUrl;
  final String streamingQuality;
  final String downloadQuality;
  final String equalizerPreset;
  final bool crossfadeEnabled;
  final int crossfadeDuration;
  final bool streamWifiOnly;
  final bool normalizeVolume;
  final bool notificationsEnabled;
  final String planName;
  final double cacheSizeMb;
  final String activeGear;

  const ProfileState({
    this.displayName = 'Music Lover',
    this.email = 'listener@sangeet.app',
    this.avatarUrl =
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=400',
    this.streamingQuality = 'High (320 kbps)',
    this.downloadQuality = 'High (320 kbps)',
    this.equalizerPreset = 'Balanced',
    this.crossfadeEnabled = true,
    this.crossfadeDuration = 4,
    this.streamWifiOnly = false,
    this.normalizeVolume = true,
    this.notificationsEnabled = true,
    this.planName = 'Sangeet Premium',
    this.cacheSizeMb = 28.4,
    this.activeGear = 'Default Output',
  });

  // Backwards compatibility getters
  String get userName => displayName;
  String get userRole => planName;
  String get memberSince => 'Member since 2023';
  String get hoursListened => '142';
  String get losslessPercentage => '98.4%';
  String get mastersCount => '24';
  bool get exclusiveMode => streamWifiOnly;
  bool get bitPerfectMode => streamingQuality.contains('Lossless');
  String get primaryGear => activeGear;
  String get primaryDac => '';
  String get secondaryGear => '';
  String get secondaryGearDetails => '';
  String get streamingResolution => streamingQuality;
  String get offlineStorageInfo => '${cacheSizeMb.toStringAsFixed(1)} MB Cached';
  double get offlineStorageFraction => 0.12;
  String get targetCurve => 'Preset: $equalizerPreset';
  String get subscriptionTier => planName;
  String get subscriptionSubtitle => planName == 'Sangeet Premium'
      ? 'Ad-free · Offline Playback · Lossless'
      : 'Standard Audio with Ads';
  String get subscriptionPrice =>
      planName == 'Sangeet Premium' ? '\$4.99 / Month' : 'Free';

  ProfileState copyWith({
    String? displayName,
    String? email,
    String? avatarUrl,
    String? streamingQuality,
    String? downloadQuality,
    String? equalizerPreset,
    bool? crossfadeEnabled,
    int? crossfadeDuration,
    bool? streamWifiOnly,
    bool? normalizeVolume,
    bool? notificationsEnabled,
    String? planName,
    double? cacheSizeMb,
    String? activeGear,
    // Compat copyWith parameters
    String? userName,
    String? userRole,
    String? memberSince,
    String? hoursListened,
    String? losslessPercentage,
    String? mastersCount,
    bool? exclusiveMode,
    String? primaryGear,
    String? primaryDac,
    String? secondaryGear,
    String? secondaryGearDetails,
    String? streamingResolution,
    String? offlineStorageInfo,
    double? offlineStorageFraction,
    String? targetCurve,
    String? subscriptionTier,
    String? subscriptionSubtitle,
    String? subscriptionPrice,
  }) {
    return ProfileState(
      displayName: displayName ?? userName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      streamingQuality: streamingQuality ?? streamingResolution ?? this.streamingQuality,
      downloadQuality: downloadQuality ?? this.downloadQuality,
      equalizerPreset: equalizerPreset ?? this.equalizerPreset,
      crossfadeEnabled: crossfadeEnabled ?? this.crossfadeEnabled,
      crossfadeDuration: crossfadeDuration ?? this.crossfadeDuration,
      streamWifiOnly: streamWifiOnly ?? exclusiveMode ?? this.streamWifiOnly,
      normalizeVolume: normalizeVolume ?? this.normalizeVolume,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      planName: planName ?? subscriptionTier ?? this.planName,
      cacheSizeMb: cacheSizeMb ?? this.cacheSizeMb,
      activeGear: activeGear ?? primaryGear ?? this.activeGear,
    );
  }

  @override
  List<Object?> get props => [
        displayName,
        email,
        avatarUrl,
        streamingQuality,
        downloadQuality,
        equalizerPreset,
        crossfadeEnabled,
        crossfadeDuration,
        streamWifiOnly,
        normalizeVolume,
        notificationsEnabled,
        planName,
        cacheSizeMb,
        activeGear,
      ];
}

// ─── BLoC ────────────────────────────────────────────────────────────────────

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc() : super(const ProfileState()) {
    on<ProfileDisplayNameUpdated>((event, emit) {
      emit(state.copyWith(displayName: event.name));
    });

    on<ProfileAvatarUrlUpdated>((event, emit) {
      emit(state.copyWith(avatarUrl: event.avatarUrl));
    });

    on<ProfileStreamingQualityChanged>((event, emit) {
      emit(state.copyWith(streamingQuality: event.quality));
    });

    on<ProfileDownloadQualityChanged>((event, emit) {
      emit(state.copyWith(downloadQuality: event.quality));
    });

    on<ProfileEqualizerPresetSelected>((event, emit) {
      emit(state.copyWith(equalizerPreset: event.preset));
    });

    on<ProfileCrossfadeToggled>((event, emit) {
      emit(state.copyWith(crossfadeEnabled: !state.crossfadeEnabled));
    });

    on<ProfileCrossfadeDurationChanged>((event, emit) {
      emit(state.copyWith(crossfadeDuration: event.durationSeconds));
    });

    on<ProfileWifiOnlyToggled>((event, emit) {
      emit(state.copyWith(streamWifiOnly: !state.streamWifiOnly));
    });

    on<ProfileNormalizeVolumeToggled>((event, emit) {
      emit(state.copyWith(normalizeVolume: !state.normalizeVolume));
    });

    on<ProfileNotificationsToggled>((event, emit) {
      emit(state.copyWith(notificationsEnabled: !state.notificationsEnabled));
    });

    on<ProfilePlanChanged>((event, emit) {
      emit(state.copyWith(planName: event.plan));
    });

    on<ProfileCacheCleared>((event, emit) {
      emit(state.copyWith(cacheSizeMb: 0.0));
    });

    // Compat handlers
    on<ProfileExclusiveModeToggled>((event, emit) {
      emit(state.copyWith(streamWifiOnly: !state.streamWifiOnly));
    });

    on<ProfileBitPerfectToggled>((event, emit) {
      final isLossless = state.streamingQuality.contains('Lossless');
      emit(state.copyWith(
        streamingQuality: isLossless ? 'High (320 kbps)' : 'Hi-Res Lossless (FLAC)',
      ));
    });

    on<ProfileGearSwitched>((event, emit) {
      emit(state.copyWith(activeGear: event.gearName));
    });
  }
}
