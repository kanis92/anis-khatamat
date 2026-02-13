import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/khatma.dart';
import '../models/reading_progress.dart';

/// Service de persistance : Firestore + backup local
class ReadingService {
  static const _khatmatKey = 'anis_khatmat';
  static const _progressKey = 'anis_progress';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Khatma>> getKhatmat(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('khatmat')
          .where('createdBy', isEqualTo: userId)
          .get();
      final list = snapshot.docs
          .map((d) => Khatma.fromMap({...d.data(), 'id': d.id}))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (_) {
      return await _getKhatmatLocal();
    }
  }

  Future<List<Khatma>> _getKhatmatLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_khatmatKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => Khatma.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveKhatma(Khatma khatma) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await _getKhatmatLocal();
    final index = list.indexWhere((k) => k.id == khatma.id);
    if (index >= 0) {
      list[index] = khatma;
    } else {
      list.insert(0, khatma);
    }
    await prefs.setString(_khatmatKey, jsonEncode(list.map((k) => k.toMap()).toList()));
    try {
      if (khatma.id.startsWith('local_')) {
        final doc = await _firestore.collection('khatmat').add(khatma.toMap());
        final updated = Khatma(
          id: doc.id,
          title: khatma.title,
          objectives: khatma.objectives,
          isGroup: khatma.isGroup,
          members: khatma.members,
          hizbAssignments: khatma.hizbAssignments,
          createdBy: khatma.createdBy,
          createdAt: khatma.createdAt,
        );
        final newList = list.map((k) => k.id == khatma.id ? updated : k).toList();
        await prefs.setString(_khatmatKey, jsonEncode(newList.map((k) => k.toMap()).toList()));
      } else {
        await _firestore.collection('khatmat').doc(khatma.id).set(khatma.toMap());
      }
    } catch (_) {}
  }

  Future<ReadingProgress?> getProgress(String khatmaId, String userId) async {
    try {
      final doc = await _firestore
          .collection('reading_progress')
          .doc('${khatmaId}_$userId')
          .get();
      if (doc.exists) {
        return ReadingProgress.fromMap({...doc.data()!, 'khatmaId': khatmaId, 'userId': userId});
      }
    } catch (_) {}
    return await _getProgressLocal(khatmaId, userId);
  }

  Future<ReadingProgress?> _getProgressLocal(String khatmaId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final map = prefs.getString('$_progressKey$khatmaId\$$userId');
    if (map == null) return null;
    return ReadingProgress.fromMap(jsonDecode(map) as Map<String, dynamic>);
  }

  Future<void> toggleHizbCompleted(String khatmaId, String userId, int hizbNumber) async {
    final progress = await getProgress(khatmaId, userId) ??
        ReadingProgress(khatmaId: khatmaId, userId: userId, lastUpdated: DateTime.now());
    final newSet = Set<int>.from(progress.completedHizb);
    if (newSet.contains(hizbNumber)) {
      newSet.remove(hizbNumber);
    } else {
      newSet.add(hizbNumber);
    }
    final updated = progress.copyWith(
      completedHizb: newSet,
      lastUpdated: DateTime.now(),
    );
    await _saveProgress(updated);
  }

  Future<void> _saveProgress(ReadingProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_progressKey${progress.khatmaId}\$${progress.userId}',
      jsonEncode(progress.toMap()),
    );
    try {
      await _firestore
          .collection('reading_progress')
          .doc('${progress.khatmaId}_${progress.userId}')
          .set(progress.toMap());
    } catch (_) {}
  }

  Future<int> getTotalCompletedHizb(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_progressKey));
    int total = 0;
    for (final key in keys) {
      if (key.contains(userId)) {
        final json = prefs.getString(key);
        if (json != null) {
          final p = ReadingProgress.fromMap(jsonDecode(json) as Map<String, dynamic>);
          total += p.completedCount;
        }
      }
    }
    return total;
  }
}
