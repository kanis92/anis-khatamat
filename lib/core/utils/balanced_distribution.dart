/// Distribution équilibrée d'unités entières sur plusieurs jours.
///
/// Distribue N unités sur D jours de manière déterministe avec variation minimale.
///
/// **Garanties :**
/// - Somme exacte : sum(allocations) = totalUnits
/// - Variation minimale : max - min ≤ 1
/// - Ordre déterministe : jours avec +1 unité en premier
///
/// **Exemples :**
/// ```dart
/// balancedDistribution(240, 29) → [9,9,9,9,9,9, 8,8,8,...,8] (6×9 + 23×8)
/// balancedDistribution(240, 30) → [8,8,8,...,8] (30×8)
/// balancedDistribution(240, 31) → [8,8,...,8, 7,7,...,7] (23×8 + 8×7)
/// ```
List<int> balancedDistribution(int totalUnits, int totalDays) {
  if (totalDays <= 0) return [];
  if (totalUnits <= 0) return List.filled(totalDays, 0);

  final baseAllocation = totalUnits ~/ totalDays; // quotient entier
  final remainder = totalUnits % totalDays; // reste

  final distribution = <int>[];

  // Les 'remainder' premiers jours reçoivent baseAllocation + 1
  for (var i = 0; i < remainder; i++) {
    distribution.add(baseAllocation + 1);
  }

  // Les jours restants reçoivent baseAllocation
  for (var i = remainder; i < totalDays; i++) {
    distribution.add(baseAllocation);
  }

  return distribution;
}
