import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Service pour les participants sans compte (invités Firebase Anonymous).
/// Identité canonique Firestore : [authUid] (= request.auth.uid).
class GuestService {
  static const _prefix = 'anis_guest_';

  Future<String> getGuestIdForKhatma(String khatmaId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('$_prefix$khatmaId');
    if (json == null) return '';
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return map['authUid'] as String? ?? map['guestId'] as String? ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Legacy guest_{uuid} stocké avant migration vers auth.uid.
  Future<String?> getLegacyGuestIdForKhatma(String khatmaId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('$_prefix$khatmaId');
    if (json == null) return null;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      final legacy = map['legacyGuestId'] as String?;
      if (legacy != null && legacy.isNotEmpty) return legacy;
      final guestId = map['guestId'] as String?;
      if (guestId != null && guestId.startsWith('guest_')) return guestId;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> getGuestNameForKhatma(String khatmaId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('$_prefix$khatmaId');
    if (json == null) return null;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return map['name'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Enregistre l'invité avec authUid canonique (Firebase Anonymous UID).
  Future<String> joinAsGuest(String khatmaId, String authUid, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString('$_prefix$khatmaId');
    String? legacyGuestId;
    if (existing != null) {
      try {
        final map = jsonDecode(existing) as Map<String, dynamic>;
        final old = map['guestId'] as String?;
        if (old != null && old.startsWith('guest_') && old != authUid) {
          legacyGuestId = old;
        }
        final oldLegacy = map['legacyGuestId'] as String?;
        if (oldLegacy != null && oldLegacy.isNotEmpty) {
          legacyGuestId = oldLegacy;
        }
      } catch (_) {}
    }
    await prefs.setString(
      '$_prefix$khatmaId',
      jsonEncode({
        'authUid': authUid,
        'guestId': authUid,
        if (legacyGuestId != null) 'legacyGuestId': legacyGuestId,
        'name': name.trim(),
      }),
    );
    return authUid;
  }

  Future<void> clearGuestForKhatma(String khatmaId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$khatmaId');
  }

  /// IDs des Khatmas rejointes en invité (prefs locales).
  Future<List<String>> getJoinedKhatmaIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getKeys()
        .where((k) => k.startsWith(_prefix))
        .map((k) => k.substring(_prefix.length))
        .where((id) => id.isNotEmpty)
        .toList();
  }
}
