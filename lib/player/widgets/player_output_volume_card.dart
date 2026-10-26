import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audio_session/audio_session.dart';
import '../../theme/theme.dart';

/// Representation of an audio output endpoint detected by the system.
class AudioDeviceItem {
  final String id;
  final String name;
  final String spec;
  final String category;
  final IconData icon;
  final AudioDeviceType type;

  const AudioDeviceItem({
    required this.id,
    required this.name,
    required this.spec,
    required this.category,
    required this.icon,
    required this.type,
  });
}

/// Card showing the active audio output destination with real hardware detection.
/// Automatically filters out internal system ports and call earpieces, showing
/// only genuine music listening endpoints (Phone Loudspeaker, Bluetooth, Wired, USB DAC).
class PlayerOutputVolumeCard extends StatefulWidget {
  const PlayerOutputVolumeCard({super.key});

  @override
  State<PlayerOutputVolumeCard> createState() => _PlayerOutputVolumeCardState();
}

// Alias for semantic clarity
typedef PlayerOutputDeviceCard = PlayerOutputVolumeCard;

class _PlayerOutputVolumeCardState extends State<PlayerOutputVolumeCard> {
  StreamSubscription<Set<AudioDevice>>? _devicesSub;

  static const AudioDeviceItem _defaultSpeaker = AudioDeviceItem(
    id: 'builtin_speaker',
    name: 'Phone Loudspeaker',
    spec: 'Internal Stereo Acoustic Drivers',
    category: 'SPEAKER',
    icon: Icons.speaker_rounded,
    type: AudioDeviceType.builtInSpeaker,
  );

  late List<AudioDeviceItem> _availableDevices;
  AudioDeviceItem? _selectedDevice;

  @override
  void initState() {
    super.initState();
    _availableDevices = [_defaultSpeaker];
    _selectedDevice = _defaultSpeaker;
    _initAudioDevices();
  }

  @override
  void dispose() {
    _devicesSub?.cancel();
    super.dispose();
  }

  Future<void> _initAudioDevices() async {
    try {
      final session = await AudioSession.instance;
      final devices = await session.getDevices(
        includeInputs: false,
        includeOutputs: true,
      );

      if (mounted) {
        _syncDevices(devices);
      }

      _devicesSub = session.devicesStream.listen((allDevices) {
        if (mounted) {
          final outputs = allDevices.where((d) => d.isOutput).toSet();
          _syncDevices(outputs);
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('PlayerOutputVolumeCard: Error detecting audio devices: $e');
      }
      if (mounted) {
        _fallbackDefaults();
      }
    }
  }

  void _syncDevices(Set<AudioDevice> rawDevices) {
    final mapped = <AudioDeviceItem>[];
    final seenKeys = <String>{};

    for (final dev in rawDevices) {
      if (!dev.isOutput) continue;

      // 1. Explicitly filter out phone call earpiece / ear receiver
      if (dev.type == AudioDeviceType.builtInEarpiece) continue;

      // 2. Only allow genuine consumer media endpoints (exclude internal system ports)
      final isMediaEndpoint = dev.type == AudioDeviceType.builtInSpeaker ||
          dev.type == AudioDeviceType.builtInSpeakerSafe ||
          dev.type == AudioDeviceType.bluetoothA2dp ||
          dev.type == AudioDeviceType.bluetoothLe ||
          dev.type == AudioDeviceType.bluetoothSco ||
          dev.type == AudioDeviceType.wiredHeadphones ||
          dev.type == AudioDeviceType.wiredHeadset ||
          dev.type == AudioDeviceType.usbAudio ||
          dev.type == AudioDeviceType.airPlay ||
          dev.type == AudioDeviceType.hdmi ||
          dev.type == AudioDeviceType.hdmiArc ||
          dev.type == AudioDeviceType.hearingAid;

      if (!isMediaEndpoint) continue;

      // 3. Filter out any vendor-specific strings for ear receiver / telephony / system ports
      final lowerName = dev.name.toLowerCase();
      if (lowerName.contains('earpiece') ||
          lowerName.contains('ear receiver') ||
          lowerName.contains('receiver') ||
          lowerName.contains('telephony') ||
          lowerName.contains('submix') ||
          lowerName.contains('system')) {
        continue;
      }

      final item = _mapAudioDevice(dev);

      // Deduplicate speaker ports so only one speaker entry is displayed
      final dedupeKey = (item.type == AudioDeviceType.builtInSpeaker ||
              item.type == AudioDeviceType.builtInSpeakerSafe)
          ? 'builtin_speaker'
          : item.name;

      if (seenKeys.contains(dedupeKey)) continue;
      seenKeys.add(dedupeKey);

      mapped.add(item);
    }

    if (mapped.isEmpty) {
      mapped.add(_defaultSpeaker);
    }

    setState(() {
      _availableDevices = mapped;

      // Preserve selection if still available, otherwise prioritize external or speaker
      if (_selectedDevice != null) {
        final stillExists = mapped.indexWhere((d) => d.id == _selectedDevice!.id);
        if (stillExists >= 0) {
          _selectedDevice = mapped[stillExists];
        } else {
          _selectedDevice = mapped.first;
        }
      } else {
        // Prioritize Bluetooth or Wired if connected, otherwise phone speaker
        final prioritized = mapped.firstWhere(
          (d) =>
              d.type == AudioDeviceType.bluetoothA2dp ||
              d.type == AudioDeviceType.bluetoothLe ||
              d.type == AudioDeviceType.wiredHeadphones ||
              d.type == AudioDeviceType.wiredHeadset ||
              d.type == AudioDeviceType.usbAudio,
          orElse: () => mapped.first,
        );
        _selectedDevice = prioritized;
      }
    });
  }

  void _fallbackDefaults() {
    setState(() {
      _availableDevices = [_defaultSpeaker];
      _selectedDevice = _defaultSpeaker;
    });
  }

  AudioDeviceItem _mapAudioDevice(AudioDevice dev) {
    String name = dev.name.trim();
    String spec = 'Hi-Fi Audio Destination';
    String category = 'SPEAKER';
    IconData icon = Icons.speaker_rounded;

    switch (dev.type) {
      case AudioDeviceType.bluetoothA2dp:
      case AudioDeviceType.bluetoothSco:
      case AudioDeviceType.bluetoothLe:
        if (name.isEmpty) name = 'Bluetooth Audio Device';
        spec = 'Wireless A2DP · Hi-Res Stream';
        category = 'BLUETOOTH';
        icon = Icons.bluetooth_audio_rounded;
        break;

      case AudioDeviceType.builtInSpeaker:
      case AudioDeviceType.builtInSpeakerSafe:
        if (name.isEmpty || name.toLowerCase() == 'speaker') {
          name = 'Phone Loudspeaker';
        }
        spec = 'Internal Stereo Acoustic Drivers';
        category = 'SPEAKER';
        icon = Icons.speaker_rounded;
        break;

      case AudioDeviceType.wiredHeadphones:
      case AudioDeviceType.wiredHeadset:
        if (name.isEmpty) name = 'Wired Headphones';
        spec = 'Analog 3.5mm Jack · Direct Audio';
        category = 'WIRED';
        icon = Icons.headphones_rounded;
        break;

      case AudioDeviceType.usbAudio:
        if (name.isEmpty) name = 'USB-C Audio / External DAC';
        spec = 'USB Audio Class 2.0 · Direct PCM Out';
        category = 'USB DAC';
        icon = Icons.album_rounded;
        break;

      case AudioDeviceType.airPlay:
        if (name.isEmpty) name = 'AirPlay Speaker';
        spec = 'Lossless ALAC Network Stream';
        category = 'AIRPLAY';
        icon = Icons.airplay_rounded;
        break;

      case AudioDeviceType.hdmi:
      case AudioDeviceType.hdmiArc:
        if (name.isEmpty) name = 'HDMI Output';
        spec = 'Multi-Channel PCM Digital Stream';
        category = 'HDMI';
        icon = Icons.tv_rounded;
        break;

      case AudioDeviceType.hearingAid:
        if (name.isEmpty) name = 'Hearing Device';
        spec = 'Direct Stream Low-Latency Audio';
        category = 'HEARING';
        icon = Icons.hearing_rounded;
        break;

      default:
        name = 'Phone Loudspeaker';
        spec = 'Internal Stereo Acoustic Drivers';
        category = 'SPEAKER';
        icon = Icons.speaker_rounded;
        break;
    }

    return AudioDeviceItem(
      id: dev.id,
      name: name,
      spec: spec,
      category: category,
      icon: icon,
      type: dev.type,
    );
  }

  void _showDeviceSwitchSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLow,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final hasBluetoothOrWired = _availableDevices.any((d) =>
            d.type != AudioDeviceType.builtInSpeaker &&
            d.type != AudioDeviceType.builtInSpeakerSafe);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sheet Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OUTPUT DESTINATIONS',
                          style: AppTypography.labelSm(color: AppColors.secondary).copyWith(
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Select audio hardware to stream to',
                          style: AppTypography.labelSm(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22),
                      color: AppColors.onSurfaceVariant,
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Device List (Only genuine media listening endpoints)
                ..._availableDevices.map((device) {
                  final isSelected = device.id == _selectedDevice?.id;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.secondaryContainer.withValues(alpha: 0.18)
                          : AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.secondary.withValues(alpha: 0.5)
                            : AppColors.outlineVariant.withValues(alpha: 0.1),
                        width: isSelected ? 1.2 : 0.8,
                      ),
                    ),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.secondary.withValues(alpha: 0.18)
                              : AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          device.icon,
                          size: 22,
                          color: isSelected
                              ? AppColors.secondary
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              device.name,
                              style: AppTypography.bodyMd(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.onSurface,
                              ).copyWith(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.secondary.withValues(alpha: 0.2)
                                  : AppColors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              device.category,
                              style: AppTypography.labelSm(
                                color: isSelected
                                    ? AppColors.secondary
                                    : AppColors.onSurfaceVariant,
                              ).copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          device.spec,
                          style: AppTypography.labelSm(
                            color: isSelected
                                ? AppColors.onSurface
                                : AppColors.onSurfaceVariant,
                          ).copyWith(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.secondary,
                              size: 22,
                            )
                          : null,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedDevice = device;
                        });
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                  );
                }),

                // If no external Bluetooth or wired headphones are connected, show informative status
                if (!hasBluetoothOrWired) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.12),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.bluetooth_searching_rounded,
                            size: 18,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Connect Bluetooth or Headphones',
                                style: AppTypography.labelSm(color: AppColors.onSurface).copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Connect in phone settings to auto-route playback.',
                                style: AppTypography.labelSm(color: AppColors.onSurfaceVariant).copyWith(
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Outputs update automatically when Bluetooth or headphones connect.',
                        style: AppTypography.labelSm(
                          color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                        ).copyWith(fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = _selectedDevice ?? _defaultSpeaker;
    final activeName = active.name;
    final activeSpec = active.spec;
    final activeIcon = active.icon;
    final activeCategory = active.category;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.12),
          width: 0.8,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showDeviceSwitchSheet(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Device Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      activeIcon,
                      size: 20,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Device Name & Spec
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              activeName,
                              style: AppTypography.bodySm(color: AppColors.onSurface).copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Active status badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: AppColors.secondary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  activeCategory,
                                  style: AppTypography.labelSm(color: AppColors.secondary).copyWith(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activeSpec,
                        style: AppTypography.labelSm(color: AppColors.onSurfaceVariant).copyWith(
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // SWITCH CTA Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.2),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'SWITCH',
                        style: AppTypography.labelSm(color: AppColors.secondary).copyWith(
                          fontSize: 10.5,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: AppColors.secondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
