import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../core/models/khatma.dart';
import '../core/providers/reading_provider.dart';

class KhatmaScreen extends ConsumerWidget {
  const KhatmaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final khatmatAsync = ref.watch(khatmatProvider);
    final khatmat = khatmatAsync.valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Khatma'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CreateKhatmaCard(
              onIndividual: () => _showCreateKhatmaDialog(context, isGroup: false),
              onGroup: () => _showCreateKhatmaDialog(context, isGroup: true),
            ),
            const SizedBox(height: 24),
            Text(
              'Vos Khatmat en cours',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (khatmat.isEmpty)
              _EmptyStateCard(
                message: 'Aucune Khatma en cours',
                actionLabel: 'Créer une Khatma',
                onAction: () => _showCreateKhatmaDialog(context, isGroup: false),
              )
            else
              ...khatmat.map((k) => _KhatmaCard(
                    khatma: k,
                    onTap: () => context.push('/khatma/${k.id}', extra: {'khatma': k}),
                  )),
            const SizedBox(height: 24),
            Text(
              'Options de lecture',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _MushafOptionsCard(
              onHafsTap: () => context.push('/mushaf/hafs'),
              onWarshTap: () => context.push('/mushaf/warsh'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateKhatmaDialog(BuildContext context, {required bool isGroup}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _CreateKhatmaForm(isGroup: isGroup),
      ),
    );
  }
}

class _CreateKhatmaCard extends StatelessWidget {
  final VoidCallback onIndividual;
  final VoidCallback onGroup;

  const _CreateKhatmaCard({
    required this.onIndividual,
    required this.onGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.add_circle, color: AppTheme.primaryGreen, size: 32),
                const SizedBox(width: 12),
                Text(
                  'Créer une nouvelle Khatma',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Choisissez le type de Khatma',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onIndividual,
                    icon: const Icon(Icons.person),
                    label: const Text('Individuelle'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onGroup,
                    icon: const Icon(Icons.groups),
                    label: const Text('Groupe'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KhatmaCard extends StatelessWidget {
  final Khatma khatma;
  final VoidCallback onTap;

  const _KhatmaCard({
    required this.khatma,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
          child: Icon(
            khatma.isGroup ? Icons.groups : Icons.person,
            color: AppTheme.primaryGreen,
          ),
        ),
        title: Text(khatma.title),
        subtitle: Text(
          '${khatma.isGroup ? 'Groupe' : 'Individuelle'} • '
          '${khatma.createdAt.day}/${khatma.createdAt.month}/${khatma.createdAt.year}',
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

class _CreateKhatmaForm extends StatefulWidget {
  final bool isGroup;

  const _CreateKhatmaForm({required this.isGroup});

  @override
  State<_CreateKhatmaForm> createState() => _CreateKhatmaFormState();
}

class _CreateKhatmaFormState extends State<_CreateKhatmaForm> {
  final _titleController = TextEditingController();
  final _objectivesController = TextEditingController();
  final _membersController = TextEditingController();
  final List<String> _members = [];

  @override
  void dispose() {
    _titleController.dispose();
    _objectivesController.dispose();
    _membersController.dispose();
    super.dispose();
  }

  void _addMember() {
    final email = _membersController.text.trim();
    if (email.isNotEmpty && !_members.contains(email)) {
      setState(() {
        _members.add(email);
        _membersController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.isGroup ? 'Khatma de groupe' : 'Khatma individuelle',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Titre de la Khatma',
              hintText: 'Ex: Khatma Ramadan 2025',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _objectivesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Objectifs',
              hintText: 'Décrivez vos objectifs...',
            ),
          ),
          if (widget.isGroup) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _membersController,
                    decoration: const InputDecoration(
                      labelText: 'Inviter des membres',
                      hintText: 'Email du membre',
                    ),
                    onSubmitted: (_) => _addMember(),
                  ),
                ),
                IconButton(
                  onPressed: _addMember,
                  icon: const Icon(Icons.add_circle),
                ),
              ],
            ),
            if (_members.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _members
                    .map((m) => Chip(
                          label: Text(m),
                          onDeleted: () =>
                              setState(() => _members.remove(m)),
                        ))
                    .toList(),
              ),
            ],
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/khatma/distribute', extra: {
                'title': _titleController.text.trim().isEmpty
                    ? 'Ma Khatma'
                    : _titleController.text.trim(),
                'objectives': _objectivesController.text.trim().isEmpty
                    ? null
                    : _objectivesController.text.trim(),
                'isGroup': widget.isGroup,
                'members': _members,
              });
            },
            child: const Text('Suivant → Distribution des Hizb'),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyStateCard({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _MushafOptionsCard extends StatelessWidget {
  final VoidCallback? onHafsTap;
  final VoidCallback? onWarshTap;

  const _MushafOptionsCard({
    this.onHafsTap,
    this.onWarshTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.menu_book, color: AppTheme.primaryGreen),
            title: const Text('Mushaf Hafs'),
            subtitle: const Text('Version la plus répandue'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: onHafsTap ?? () {},
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.menu_book, color: AppTheme.accentGold),
            title: const Text('Mushaf Warsh'),
            subtitle: const Text('Version d\'Afrique du Nord'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: onWarshTap ?? () {},
          ),
        ],
      ),
    );
  }
}
