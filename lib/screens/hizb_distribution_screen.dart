import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../core/theme/app_theme.dart';
import '../core/constants/app_constants.dart';
import '../core/models/khatma.dart';
import '../core/data/quran_hizb_data.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/reading_provider.dart';

class HizbDistributionScreen extends ConsumerStatefulWidget {
  final String khatmaTitle;
  final String? khatmaObjectives;
  final bool isGroup;
  final List<String> members;

  const HizbDistributionScreen({
    super.key,
    required this.khatmaTitle,
    this.khatmaObjectives,
    required this.isGroup,
    this.members = const [],
  });

  @override
  ConsumerState<HizbDistributionScreen> createState() =>
      _HizbDistributionScreenState();
}

class _HizbDistributionScreenState extends ConsumerState<HizbDistributionScreen> {
  final Map<int, String> _assignments = {};

  List<String> get _participants {
    if (!widget.isGroup || widget.members.isEmpty) {
      return ['Moi'];
    }
    return ['Moi', ...widget.members];
  }

  String get _khatmaTitle => widget.khatmaTitle;
  String? get _khatmaObjectives => widget.khatmaObjectives;
  bool get _isGroup => widget.isGroup;
  List<String> get _members => widget.members;

  void _assignHizb(int hizbNumber, String? participant) {
    setState(() {
      if (participant == null || participant.isEmpty) {
        _assignments.remove(hizbNumber);
      } else {
        _assignments[hizbNumber] = participant;
      }
    });
  }

  void _manualDistribution() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Utilisez le bouton ✏️ à droite de chaque Hizb pour l\'assigner'),
      ),
    );
  }

  void _autoDistribute() {
    setState(() {
      _assignments.clear();
      final participants = _participants;
      for (var i = 1; i <= AppConstants.totalHizb; i++) {
        _assignments[i] = participants[(i - 1) % participants.length];
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Distribution automatique effectuée'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _confirmDistribution() async {
    final unassigned = List.generate(AppConstants.totalHizb, (i) => i + 1)
        .where((n) => !_assignments.containsKey(n) || _assignments[n]!.isEmpty)
        .length;

    if (unassigned > 0 && _isGroup) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Hizb non assignés'),
          content: Text(
            '$unassigned Hizb ne sont pas encore assignés. Voulez-vous utiliser la distribution automatique ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _autoDistribute();
              },
              child: const Text('Distribution auto'),
            ),
          ],
        ),
      );
      return;
    }

    if (unassigned > 0 && !_isGroup) {
      setState(() {
        for (var i = 1; i <= AppConstants.totalHizb; i++) {
          _assignments[i] = 'Moi';
        }
      });
    }

    final user = ref.read(currentUserProvider);
    final userId = user?.email ?? 'demo';
    final khatma = Khatma(
      id: 'local_${const Uuid().v4()}',
      title: _khatmaTitle,
      objectives: _khatmaObjectives,
      isGroup: _isGroup,
      members: _members,
      hizbAssignments: Map.from(_assignments),
      createdBy: userId,
      createdAt: DateTime.now(),
    );
    await ref.read(readingServiceProvider).saveKhatma(khatma);
    ref.invalidate(khatmatProvider);
    ref.invalidate(totalCompletedHizbProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Distribution confirmée ! Khatma créée.'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    }
  }

  void _sendReminder() {
    final lateMembers = _assignments.entries
        .where((e) => e.value != 'Moi')
        .map((e) => e.value)
        .toSet()
        .toList();

    if (lateMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun membre à rappeler')),
      );
      return;
    }

    Share.share(
      'Assalamu alaykum ! Rappel pour la Khatma "$_khatmaTitle" - '
      'il est temps de lire votre Hizb. بارك الله فيكم',
    );
  }

  @override
  Widget build(BuildContext context) {
    final assignedCount = _assignments.values.where((v) => v.isNotEmpty).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Distribution des Hizb'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _khatmaTitle,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$assignedCount/${AppConstants.totalHizb} Hizb assignés',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _autoDistribute,
                                  icon: const Icon(Icons.auto_awesome, size: 16),
                                  label: const Text('Auto'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _manualDistribution,
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Manuel'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Liste des 60 Hizb',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(AppConstants.totalHizb, (i) {
                    final hizbNum = i + 1;
                    final assigned = _assignments[hizbNum] ?? '';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: assigned.isNotEmpty
                              ? AppTheme.primaryGreen.withValues(alpha: 0.2)
                              : Colors.grey[300],
                          child: Text(
                            '$hizbNum',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: assigned.isNotEmpty
                                  ? AppTheme.primaryGreen
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                        title: Text(
                          QuranHizbData.hizbList[i]['range'] ?? 'Hizb $hizbNum',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                        subtitle: assigned.isNotEmpty
                            ? Text(
                                assigned,
                                style: TextStyle(
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            : const Text(
                                'Non assigné',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () => _showAssignDialog(hizbNum),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isGroup)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: OutlinedButton.icon(
                        onPressed: _sendReminder,
                        icon: const Icon(Icons.notifications_active),
                        label: const Text('Envoyer un rappel'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ),
                  FilledButton(
                    onPressed: () => _confirmDistribution(),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Confirmer la distribution'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAssignDialog(int hizbNum) {
    final current = _assignments[hizbNum];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assigner Hizb $hizbNum'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._participants.map((p) => RadioListTile<String>(
                  title: Text(p),
                  value: p,
                  groupValue: current ?? '',
                  onChanged: (v) {
                    _assignHizb(hizbNum, v);
                    Navigator.pop(context);
                  },
                )),
            RadioListTile<String>(
              title: const Text('Non assigné'),
              value: '',
              groupValue: current ?? '',
              onChanged: (v) {
                _assignHizb(hizbNum, null);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

