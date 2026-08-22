import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'khatma_participant_id.dart';

/// Type d'identité canonique Firestore (aligné sur `firestore.rules`).
enum ParticipantIdentityType { member, guest, none }

/// Contrat d'identité unique : Auth Firebase → identifiants Firestore.
class ParticipantIdentity {
  const ParticipantIdentity({
    required this.authUid,
    required this.canonicalId,
    required this.type,
    this.email,
    this.emailVerified = false,
    this.providerIds = const [],
    this.isDemoMode = false,
  });

  final String? authUid;
  final String? email;
  final String canonicalId;
  final ParticipantIdentityType type;
  final bool emailVerified;
  final List<String> providerIds;
  final bool isDemoMode;

  bool get isMemberEmail => type == ParticipantIdentityType.member;
  bool get isGuest => type == ParticipantIdentityType.guest;
  bool get hasFirebaseAuth => authUid != null && authUid!.isNotEmpty;

  /// Peut créer/écrire une Khatma Firestore (`createdBy == userEmail()`).
  bool get canWriteKhatma => isMemberEmail && email != null && email!.isNotEmpty;

  /// Identité depuis FirebaseAuth (source de vérité runtime).
  static ParticipantIdentity? fromFirebaseAuth({bool isDemoMode = false}) {
    if (isDemoMode) {
      return const ParticipantIdentity(
        authUid: 'demo-user',
        email: 'demo@test.com',
        canonicalId: 'demo@test.com',
        type: ParticipantIdentityType.none,
        isDemoMode: true,
      );
    }
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
    if (user == null) return null;

    final canonical = KhatmaParticipantId.fromFirebaseUser(user);
    if (canonical == null) {
      return ParticipantIdentity(
        authUid: user.uid,
        email: user.email,
        canonicalId: user.uid,
        type: ParticipantIdentityType.none,
        emailVerified: user.emailVerified,
        providerIds: user.providerData.map((p) => p.providerId).toList(),
      );
    }

    return ParticipantIdentity(
      authUid: user.uid,
      email: user.isAnonymous ? null : user.email,
      canonicalId: canonical,
      type: user.isAnonymous
          ? ParticipantIdentityType.guest
          : ParticipantIdentityType.member,
      emailVerified: user.emailVerified,
      providerIds: user.providerData.map((p) => p.providerId).toList(),
    );
  }

  /// Libellé UI (sans PII complète).
  String get displayLabel {
    if (isDemoMode) return 'Mode démo';
    if (type == ParticipantIdentityType.member) {
      final name = email?.split('@').first;
      if (name != null && name.isNotEmpty) return name;
    }
    if (type == ParticipantIdentityType.guest) return 'Invité';
    return 'Non connecté';
  }

  String get displayInitial {
    final label = displayLabel.trim();
    if (label.isEmpty) return '?';
    return label.substring(0, 1).toUpperCase();
  }
}

/// Instrumentation DEV temporaire — sans JWT, email ni uid complets.
class AuthDiag {
  AuthDiag._();

  static String _mask(String? value) {
    if (value == null || value.isEmpty) return '—';
    if (value.length <= 4) return '${value[0]}***';
    return '${value.substring(0, 2)}…${value.substring(value.length - 2)}';
  }

  /// Journalise l'état Auth avant une opération Firestore sensible.
  static Future<void> logContext(
    String source, {
    bool refreshToken = false,
    bool isDemoMode = false,
  }) async {
    if (!kDebugMode) return;

    final identity = ParticipantIdentity.fromFirebaseAuth(isDemoMode: isDemoMode);
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {}

    var tokenOk = false;
    if (user != null && refreshToken) {
      try {
        await user.getIdToken(true);
        tokenOk = true;
      } catch (_) {}
    }

    final hasUser = user != null;
    final anonymous = user?.isAnonymous ?? false;
    final hasEmail = user?.email != null && user!.email!.isNotEmpty;

    debugPrint(
      '[AuthDiag] source=$source '
      'user=$hasUser '
      'anonymous=$anonymous '
      'email=${hasEmail ? 'OUI' : 'NON'} '
      'uid=${_mask(user?.uid)} '
      'emailVerified=${user?.emailVerified ?? false} '
      'providers=${identity?.providerIds.join(',') ?? '—'} '
      'canonicalType=${identity?.type.name ?? 'none'} '
      'canonicalId=${_mask(identity?.canonicalId)} '
      'demo=${isDemoMode ? 'OUI' : 'NON'}'
      '${refreshToken ? ' tokenRefresh=${tokenOk ? 'OK' : 'FAIL'}' : ''}',
    );
  }
}

/// Raccourci pour l'UI : lit demoMode via callback si nécessaire.
ParticipantIdentity? resolveParticipantIdentity({bool isDemoMode = false}) =>
    ParticipantIdentity.fromFirebaseAuth(isDemoMode: isDemoMode);
