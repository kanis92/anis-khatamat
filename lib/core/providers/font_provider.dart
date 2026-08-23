import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _fontKey = 'app_ui_font';

/// Polices disponibles pour l'interface — toutes bi-script arabe + latin
enum AppFont {
  cairo('Cairo', 'القاهرة', 'Moderne · Standard des apps arabes'),
  tajawal('Tajawal', 'تجوّل', 'Épuré · Médias et actualité arabes'),
  readexPro('Readex Pro', 'ريدكس برو', 'Premium · Conçu pour bi-script arabe/latin'),
  almarai('Almarai', 'المراعي', 'Corporate · Grandes marques du monde arabe');

  const AppFont(this.displayName, this.arabicName, this.description);

  /// Nom affiché en français
  final String displayName;

  /// Nom en arabe (affiché dans la police elle-même)
  final String arabicName;

  /// Description courte
  final String description;
}

final fontProvider = StateNotifierProvider<FontNotifier, AppFont>((ref) {
  return FontNotifier();
});

class FontNotifier extends StateNotifier<AppFont> {
  FontNotifier() : super(AppFont.cairo) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_fontKey);
    if (saved != null) {
      try {
        state = AppFont.values.firstWhere((f) => f.name == saved);
      } catch (_) {
        state = AppFont.cairo;
      }
    }
  }

  Future<void> setFont(AppFont font) async {
    state = font;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontKey, font.name);
  }
}
