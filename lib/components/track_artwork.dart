import 'dart:io';
import 'package:flutter/material.dart';
import '../repositories/download_repository.dart';
import '../theme/theme.dart';

String _sanitizePath(String raw) {
  final trimmed = raw.trim();
  if (trimmed.startsWith('file://')) {
    try {
      return Uri.parse(trimmed).toFilePath();
    } catch (_) {
      return trimmed.replaceFirst('file://', '');
    }
  }
  return trimmed;
}

bool _isRemoteUrl(String pathOrUrl) {
  final lower = pathOrUrl.trim().toLowerCase();
  return lower.startsWith('http://') || lower.startsWith('https://');
}

/// Safely constructs an [ImageProvider] for either a remote URL, a local file, or null.
/// Prevents "No host specified in URI" errors when offline vault paths are passed to NetworkImage.
ImageProvider? safeImageProvider(String? pathOrUrl) {
  if (pathOrUrl == null || pathOrUrl.trim().isEmpty) return null;
  final trimmed = pathOrUrl.trim();
  if (_isRemoteUrl(trimmed)) {
    return NetworkImage(trimmed);
  }
  final cleanPath = _sanitizePath(trimmed);
  try {
    final file = File(cleanPath);
    if (file.existsSync()) {
      return FileImage(file);
    }
  } catch (_) {}
  return null;
}

/// A safe image widget that handles both network URLs and local file paths seamlessly.
class SafeImage extends StatelessWidget {
  final String? urlOrPath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? fallback;

  const SafeImage({
    super.key,
    required this.urlOrPath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (urlOrPath == null || urlOrPath!.trim().isEmpty) {
      return fallback ?? const SizedBox.shrink();
    }
    final raw = urlOrPath!.trim();
    if (_isRemoteUrl(raw)) {
      return Image.network(
        raw,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => fallback ?? const SizedBox.shrink(),
      );
    }

    final cleanPath = _sanitizePath(raw);
    try {
      final file = File(cleanPath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (_, _, _) => fallback ?? const SizedBox.shrink(),
        );
      }
    } catch (_) {}

    return fallback ?? const SizedBox.shrink();
  }
}

/// A universal, offline-first artwork image widget.
///
/// Reliably renders album artwork whether the source is:
/// 1. A local file path inside the private offline vault (`Image.file`).
/// 2. A remote HTTP URL (`Image.network`).
/// 3. A remote HTTP URL while offline, automatically falling back to the
///    locally downloaded copy stored in [DownloadRepository].
class TrackArtwork extends StatelessWidget {
  final String? albumArt;
  final String? trackId;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? fallback;

  const TrackArtwork({
    super.key,
    required this.albumArt,
    this.trackId,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.fallback,
  });

  Widget _buildFallback() {
    return fallback ??
        Container(
          width: width,
          height: height,
          color: AppColors.surfaceContainerHigh,
          child: const Center(
            child: Icon(
              Icons.music_note_rounded,
              color: AppColors.outline,
              size: 20,
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = _buildImage();

    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: imageWidget,
    );
  }

  Widget _buildImage() {
    final rawArt = albumArt?.trim();

    // 1. Direct local file check on albumArt path
    if (rawArt != null && rawArt.isNotEmpty && !_isRemoteUrl(rawArt)) {
      try {
        final cleanPath = _sanitizePath(rawArt);
        final localFile = File(cleanPath);
        if (localFile.existsSync()) {
          return Image.file(
            localFile,
            fit: fit,
            width: width,
            height: height,
            errorBuilder: (_, _, _) => _checkLocalVaultFallback(),
          );
        }
      } catch (_) {}
    }

    // 2. Check offline vault if trackId is known
    if (trackId != null) {
      final vaultPath = DownloadRepository.instance.getLocalArtPath(trackId!);
      if (vaultPath != null && vaultPath.isNotEmpty) {
        try {
          final cleanVault = _sanitizePath(vaultPath);
          final vaultFile = File(cleanVault);
          if (vaultFile.existsSync()) {
            return Image.file(
              vaultFile,
              fit: fit,
              width: width,
              height: height,
              errorBuilder: (_, _, _) => _buildFallback(),
            );
          }
        } catch (_) {}
      }
    }

    // 3. Remote HTTP URL
    if (rawArt != null && rawArt.isNotEmpty && _isRemoteUrl(rawArt)) {
      return Image.network(
        rawArt,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => _checkLocalVaultFallback(),
      );
    }

    // 4. Fallback check on vault if not already checked
    return _checkLocalVaultFallback();
  }

  Widget _checkLocalVaultFallback() {
    if (trackId != null) {
      final vaultPath = DownloadRepository.instance.getLocalArtPath(trackId!);
      if (vaultPath != null && vaultPath.isNotEmpty) {
        try {
          final cleanVault = _sanitizePath(vaultPath);
          final vaultFile = File(cleanVault);
          if (vaultFile.existsSync()) {
            return Image.file(
              vaultFile,
              fit: fit,
              width: width,
              height: height,
              errorBuilder: (_, _, _) => _buildFallback(),
            );
          }
        } catch (_) {}
      }
    }
    return _buildFallback();
  }
}
