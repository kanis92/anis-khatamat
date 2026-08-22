import 'package:flutter/material.dart';
import 'package:flutter_quran/flutter_quran.dart';

import '../core/data/quran_hizb_data.dart';
import '../core/theme/app_theme.dart';

/// Écran de recherche dans le Coran (arabe)
class QuranSearchScreen extends StatefulWidget {
  const QuranSearchScreen({super.key});

  @override
  State<QuranSearchScreen> createState() => _QuranSearchScreenState();
}

bool _isAyahInHizb(Ayah ayah, int hizb) {
  if (hizb < 1 || hizb > 60) return true;
  final range = QuranHizbData.getHizbData(hizb)['range'] ?? '';
  final parts = range.split(' - ');
  if (parts.length != 2) return true;
  final startParts = parts[0].trim().split(':');
  final endParts = parts[1].trim().split(':');
  if (startParts.length < 2 || endParts.length < 2) return true;
  final startSurah = int.tryParse(startParts[0].trim()) ?? 0;
  final startAyah = int.tryParse(startParts[1].trim()) ?? 0;
  final endSurah = int.tryParse(endParts[0].trim()) ?? 0;
  final endAyah = int.tryParse(endParts[1].trim()) ?? 0;
  return QuranHizbData.isAyahInRange(
    ayah.surahNumber, ayah.ayahNumber,
    startSurah, startAyah, endSurah, endAyah,
  );
}

class _QuranSearchScreenState extends State<QuranSearchScreen> {
  List<Ayah> _ayahs = [];
  int? _surahFilter;
  int? _hizbFilter;
  String _lastQuery = '';

  void _doSearch(String txt) {
    _lastQuery = txt;
    var results = FlutterQuran().search(txt);
    if (_surahFilter != null) {
      results = results.where((a) => a.surahNumber == _surahFilter).toList();
    }
    if (_hizbFilter != null) {
      results = results.where((a) => _isAyahInHizb(a, _hizbFilter!)).toList();
    }
    setState(() => _ayahs = [...results]);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'بحث في القرآن',
            style: AppTheme.arabicTextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  onChanged: (txt) => _doSearch(txt),
                  decoration: InputDecoration(
                    hintText: 'بحث',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        value: _surahFilter,
                        decoration: const InputDecoration(
                          labelText: 'Sourate',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Toutes')),
                          ...List.generate(114, (i) => i + 1).map(
                            (n) => DropdownMenuItem(value: n, child: Text('Sourate $n')),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() => _surahFilter = v);
                          _doSearch(_lastQuery);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        value: _hizbFilter,
                        decoration: const InputDecoration(
                          labelText: 'Hizb',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Tous')),
                          ...List.generate(60, (i) => i + 1).map(
                            (n) => DropdownMenuItem(value: n, child: Text('Hizb $n')),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() => _hizbFilter = v);
                          _doSearch(_lastQuery);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _ayahs.isEmpty
                      ? Center(
                          child: Text(
                            'اكتب للبحث في القرآن',
                            style: AppTheme.arabicTextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _ayahs.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final ayah = _ayahs[i];
                            return ListTile(
                              title: Text(
                                ayah.ayah.replaceAll('\n', ' '),
                                style: AppTheme.arabicTextStyle(
                                  fontSize: 18,
                                  height: 1.6,
                                ),
                              ),
                              subtitle: Text(
                                ayah.surahNameAr,
                                style: AppTheme.arabicTextStyle(
                                  fontSize: 14,
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                FlutterQuran().navigateToAyah(ayah);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
