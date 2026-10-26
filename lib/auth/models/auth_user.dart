import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Represents an authenticated listener session in Sangeet / Aura.
class AuthUser extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String memberTier;
  final DateTime memberSince;

  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.memberTier = 'Atelier Private Listener',
    required this.memberSince,
  });

  factory AuthUser.fromFirebaseUser(User user, {String? memberTier}) {
    String name = user.displayName ?? '';
    if (name.isEmpty && user.email != null && user.email!.isNotEmpty) {
      name = user.email!.split('@').first;
      if (name.isNotEmpty) {
        name = '${name[0].toUpperCase()}${name.substring(1)}';
      }
    }
    if (name.isEmpty) name = 'Private Listener';

    return AuthUser(
      id: user.uid,
      email: user.email ?? '',
      displayName: name,
      avatarUrl: user.photoURL ??
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=400',
      memberTier: memberTier ?? 'Atelier Private Listener',
      memberSince: user.metadata.creationTime ?? DateTime.now(),
    );
  }

  static AuthUser anonymous() {
    return AuthUser(
      id: 'listener-demo',
      email: 'client@aura-atelier.com',
      displayName: 'Julian Vance',
      avatarUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=400',
      memberTier: 'Master Artisan Tier',
      memberSince: DateTime.now().subtract(const Duration(days: 365)),
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        avatarUrl,
        memberTier,
        memberSince,
      ];
}
