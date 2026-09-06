import 'package:flutter/widgets.dart';

/// Formate une durée de manière locale-aware sans logique business.
class DurationFormatter {
  const DurationFormatter._();

  /// Formate une durée en heures/minutes selon la locale.
  /// 
  /// Conventions:
  /// - FR: 3h 15m (compact, espace après chiffre)
  /// - EN: 3h 15m (compact, no space)
  /// - AR: 3 س 15 د (Arabic units with Eastern Arabic numerals option)
  static String format(Duration duration, BuildContext context) {
    final locale = Localizations.localeOf(context);
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (locale.languageCode == 'ar') {
      // Arabic: use Arabic hour/minute abbreviations
      if (hours > 0 && minutes > 0) {
        return '$hours س $minutes د';
      } else if (hours > 0) {
        return '$hours س';
      } else {
        return '$minutes د';
      }
    } else if (locale.languageCode == 'fr') {
      // French: compact with space
      if (hours > 0 && minutes > 0) {
        return '${hours}h ${minutes}m';
      } else if (hours > 0) {
        return '${hours}h';
      } else {
        return '${minutes}min';
      }
    } else {
      // English and others: compact no space
      if (hours > 0 && minutes > 0) {
        return '${hours}h ${minutes}m';
      } else if (hours > 0) {
        return '${hours}h';
      } else {
        return '${minutes}min';
      }
    }
  }
  
  /// Version sans context pour usage dans providers (utilise format compact par défaut)
  static String formatCompact(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}min';
    }
  }
}
