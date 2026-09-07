/// Stable taxonomy of pedagogical pillars for ANIS Formations.
///
/// Machine IDs are independent from translated labels.
enum PedagogicalPillar {
  foundationsPractice('foundations_practice'),
  quranReading('quran_reading'),
  prophetSeerahSunnah('prophet_seerah_sunnah'),
  dailyLifeFrance('daily_life_france'),
  characterEthics('character_ethics'),
  spiritualityHeart('spirituality_heart');

  const PedagogicalPillar(this.id);

  final String id;

  static PedagogicalPillar? fromId(String id) {
    try {
      return values.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
