import 'package:flutter/foundation.dart';

/// Type de marqueur de subdivision dans le Quran
enum SubdivisionType {
  hizb,   // حزب - Hizb (1/60 du Quran)
  rub,    // ربع - Quart de Hizb
  nisf,   // نصف - Moitié de Hizb
  thumun, // ثمن - Huitième de Hizb
}

/// Granularité de tracking pour Wird
enum SubdivisionGranularity {
  hizb,   // Track au niveau Hizb (60 segments)
  rub,    // Track au niveau Rub' (240 segments)
  nisf,   // Track au niveau Nisf (120 segments)
  thumun, // Track au niveau Thumun (480 segments)
}

/// Marqueur de subdivision coranique.
/// 
/// Représente un point de division canonique dans le Quran,
/// défini UNIQUEMENT par sa coordonnée coranique (surah:ayah).
/// 
/// La pagination Mushaf n'est PAS une propriété du marqueur:
/// elle dépend de l'édition physique/numérique utilisée.
@immutable
class SubdivisionMarker {
  /// ID global du segment (0-indexed)
  /// Ex: Rub' définition → 0..239
  final int segmentId;

  /// Numéro du Hizb auquel appartient ce marqueur (1-60)
  final int hizbNumber;

  /// Type de subdivision
  final SubdivisionType type;

  /// Index de cette subdivision dans le Hizb (0-indexed)
  /// Ex: Pour Rub' → 0, 1, 2, 3 (4 Rub' par Hizb)
  final int indexInHizb;

  /// Coordonnée coranique canonique du début de ce segment
  final int surah;
  final int ayah;

  const SubdivisionMarker({
    required this.segmentId,
    required this.hizbNumber,
    required this.type,
    required this.indexInHizb,
    required this.surah,
    required this.ayah,
  });

  /// Label arabe localisé
  String get arabicLabel {
    switch (type) {
      case SubdivisionType.hizb:
        return 'حزب $hizbNumber';
      case SubdivisionType.nisf:
        return 'نصف الحزب $hizbNumber';
      case SubdivisionType.rub:
        final q = indexInHizb == 1 ? 'ربع' : 'ثلاثة أرباع';
        return '$q الحزب $hizbNumber';
      case SubdivisionType.thumun:
        return 'ثمن الحزب $hizbNumber';
    }
  }

  /// Label français localisé
  String get frenchLabel {
    switch (type) {
      case SubdivisionType.hizb:
        return 'Hizb $hizbNumber';
      case SubdivisionType.nisf:
        return '½ Hizb $hizbNumber';
      case SubdivisionType.rub:
        final q = indexInHizb == 1 ? '¼' : '¾';
        return '$q Hizb $hizbNumber';
      case SubdivisionType.thumun:
        // Calcul de la fraction exacte
        final fractions = ['⅛', '⅜', '⅝', '⅞'];
        final thumunIndex = (segmentId % 8) - 1; // Thumun non-Rub/Nisf/Hizb
        final frac = fractions[thumunIndex % 4];
        return '$frac Hizb $hizbNumber';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubdivisionMarker &&
          runtimeType == other.runtimeType &&
          segmentId == other.segmentId &&
          surah == other.surah &&
          ayah == other.ayah;

  @override
  int get hashCode => segmentId.hashCode ^ surah.hashCode ^ ayah.hashCode;

  @override
  String toString() =>
      'SubdivisionMarker(id: $segmentId, hizb: $hizbNumber, type: $type, $surah:$ayah)';
}
