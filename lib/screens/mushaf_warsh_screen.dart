import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../core/theme/app_theme.dart';
import '../core/extensions/l10n_extensions.dart';

/// Écran Mushaf Warsh - Lecture par sourate (API Al-Quran Cloud)
class MushafWarshScreen extends StatefulWidget {
  const MushafWarshScreen({super.key});

  @override
  State<MushafWarshScreen> createState() => _MushafWarshScreenState();
}

class _MushafWarshScreenState extends State<MushafWarshScreen> {
  static const _baseUrl = 'https://api.alquran.cloud/v1';
  static const _edition = 'quran-uthmani';

  List<Map<String, dynamic>>? _surahs;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSurahs();
  }

  Future<void> _loadSurahs() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/quran/$_edition'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final surahs = (data['data'] as Map<String, dynamic>)['surahs']
            as List<dynamic>;
        setState(() {
          _surahs = surahs
              .map((s) => s as Map<String, dynamic>)
              .toList();
          _loading = false;
          _error = null;
        });
      } else {
        setState(() {
          _error = 'Erreur de chargement';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.mushafWarsh} - المصحف'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(dynamic l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadSurahs,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    if (_surahs == null || _surahs!.isEmpty) {
      return const Center(child: Text('Aucune donnée'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _surahs!.length,
      itemBuilder: (context, index) {
        final surah = _surahs![index];
        final number = surah['number'] as int;
        final name = surah['englishName'] as String? ?? 'Surah $number';
        final arabicName = surah['name'] as String? ?? '';
        final ayahsCount = surah['numberOfAyahs'] as int? ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            leading: CircleAvatar(
              backgroundColor: AppTheme.accentGold.withValues(alpha: 0.3),
              child: Text(
                '$number',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentGold,
                ),
              ),
            ),
            title: Text(
              '$name - $arabicName',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('$ayahsCount آيات'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _openSurah(number, surah),
          ),
        );
      },
    );
  }

  void _openSurah(int number, Map<String, dynamic> surah) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _SurahWarshReader(
          surahNumber: number,
          surahName: surah['name'] as String? ?? '',
          surahEnglishName: surah['englishName'] as String? ?? '',
        ),
      ),
    );
  }
}

class _SurahWarshReader extends StatefulWidget {
  final int surahNumber;
  final String surahName;
  final String surahEnglishName;

  const _SurahWarshReader({
    required this.surahNumber,
    required this.surahName,
    required this.surahEnglishName,
  });

  @override
  State<_SurahWarshReader> createState() => _SurahWarshReaderState();
}

class _SurahWarshReaderState extends State<_SurahWarshReader> {
  static const _baseUrl = 'https://api.alquran.cloud/v1';
  static const _edition = 'quran-uthmani';

  List<Map<String, dynamic>>? _ayahs;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSurah();
  }

  Future<void> _loadSurah() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/surah/${widget.surahNumber}/$_edition'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final surahData = data['data'] as Map<String, dynamic>;
        final ayahs = surahData['ayahs'] as List<dynamic>;
        setState(() {
          _ayahs = ayahs
              .map((a) => a as Map<String, dynamic>)
              .toList();
          _loading = false;
          _error = null;
        });
      } else {
        setState(() {
          _error = 'Erreur de chargement';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.surahEnglishName} - ${widget.surahName}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadSurah,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    if (_ayahs == null || _ayahs!.isEmpty) {
      return const Center(child: Text('Aucune donnée'));
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _ayahs!.length,
        itemBuilder: (context, index) {
          final ayah = _ayahs![index];
          final number = ayah['numberInSurah'] as int? ?? index + 1;
          String text = ayah['text'] as String? ?? '';
          text = text.replaceAll('\ufeff', ''); // Supprimer BOM

          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 24,
                      height: 2.0,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
