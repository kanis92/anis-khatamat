import 'package:flutter/material.dart';
import 'package:flutter_quran/flutter_quran.dart';

/// Écran Mushaf Hafs - Lecture du Coran (King Fahd Complex, Madina)
class MushafHafsScreen extends StatefulWidget {
  const MushafHafsScreen({super.key});

  @override
  State<MushafHafsScreen> createState() => _MushafHafsScreenState();
}

class _MushafHafsScreenState extends State<MushafHafsScreen> {
  @override
  void initState() {
    super.initState();
    FlutterQuran().init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterQuranScreen(
        appBar: AppBar(
          title: const Text('Mushaf Hafs - مصحف حفص'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}
