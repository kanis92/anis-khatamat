import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../core/theme/app_theme.dart';
import '../core/constants/app_constants.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/reading_provider.dart';

/// Écran de partage des accomplissements - Carte visuelle avec partage WhatsApp
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final userName = user?.displayName ?? user?.email?.split('@').first ?? 'Utilisateur';
    final completedHizb = ref.watch(totalCompletedHizbProvider).valueOrNull ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accomplissements'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AchievementMapCard(
              userName: userName,
              completedHizb: completedHizb,
              totalHizb: AppConstants.totalHizb,
            ),
            const SizedBox(height: 24),
            _ShareSection(
              userName: userName,
              completedHizb: completedHizb,
              totalHizb: AppConstants.totalHizb,
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementMapCard extends StatelessWidget {
  final String userName;
  final int completedHizb;
  final int totalHizb;

  const _AchievementMapCard({
    required this.userName,
    required this.completedHizb,
    required this.totalHizb,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalHizb > 0 ? completedHizb / totalHizb : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                border: Border.all(
                  color: AppTheme.primaryGreen,
                  width: 4,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$completedHizb',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                            ),
                      ),
                      Text(
                        '/ $totalHizb Hizb',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              userName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hizb complétés',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareSection extends StatelessWidget {
  final String userName;
  final int completedHizb;
  final int totalHizb;

  const _ShareSection({
    required this.userName,
    required this.completedHizb,
    required this.totalHizb,
  });

  void _shareToWhatsApp() {
    final message = '''
🕌 ANIS Khatamat - Accomplissement

$userName a complété $completedHizb Hizb sur $totalHizb !
ماشاء الله

Téléchargez ANIS Khatamat pour suivre votre progression.
''';
    Share.share(
      message,
      subject: 'Mon accomplissement - ANIS Khatamat',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.share, color: AppTheme.primaryGreen),
                const SizedBox(width: 12),
                Text(
                  'Partager mes accomplissements',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Partagez votre progression sur WhatsApp ou d\'autres applications.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _shareToWhatsApp,
              icon: const Icon(Icons.share),
              label: const Text('Partager (WhatsApp, etc.)'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF25D366), // WhatsApp green
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
