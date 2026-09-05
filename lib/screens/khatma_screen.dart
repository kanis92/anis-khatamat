import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../core/models/khatma.dart';
import '../core/providers/reading_provider.dart';
import '../core/services/khatma_link_service.dart';
import '../l10n/gen_l10n/app_localizations.dart';

class KhatmaScreen extends ConsumerWidget {
  const KhatmaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final khatmatAsync = ref.watch(khatmatProvider);
    final khatmat = khatmatAsync.valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.khatma),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CreateKhatmaCard(
              onCreateGroup: () => _showCreateKhatmaDialog(context, isGroup: true),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.myKhatmat,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (khatmat.isEmpty)
              _EmptyStateCard(
                message: l10n.noKhatma,
                description: l10n.khatmaEmptyMessage,
                actionLabel: l10n.createKhatma,
                onAction: () => _showCreateKhatmaDialog(context, isGroup: true),
              )
            else
              ...khatmat.map((k) => _KhatmaCard(
                    khatma: k,
                    onTap: () => context.push('/khatma/${k.id}', extra: {'khatma': k}),
                  )),
            const SizedBox(height: 24),
            Text(
              l10n.readingOptions,
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
  final VoidCallback onCreateGroup;

  const _CreateKhatmaCard({
    required this.onCreateGroup,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: InkWell(
        onTap: onCreateGroup,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.add_circle, color: AppTheme.primaryGreen, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.createNewKhatma,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.inviteFamilyFriends,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 20, color: AppTheme.primaryGreen),
            ],
          ),
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
            Icons.groups,
            color: AppTheme.primaryGreen,
          ),
        ),
        title: Text(khatma.title),
        subtitle: Text(
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
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.createCollaborativeKhatma,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: l10n.khatmaTitle,
              hintText: l10n.khatmaExampleTitle,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _objectivesController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: l10n.objectives,
              hintText: l10n.describeObjectives,
            ),
          ),
          if (widget.isGroup) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _membersController,
                    decoration: InputDecoration(
                      labelText: l10n.inviteMembers,
                      hintText: l10n.memberEmail,
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
              context.push(KhatmaLinkService.distributePath, extra: {
                'title': _titleController.text.trim().isEmpty
                    ? l10n.myKhatma
                    : _titleController.text.trim(),
                'objectives': _objectivesController.text.trim().isEmpty
                    ? null
                    : _objectivesController.text.trim(),
                'isGroup': widget.isGroup,
                'members': _members,
              });
            },
            child: Text(l10n.nextDistribution),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String message;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyStateCard({
    required this.message,
    required this.description,
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.menu_book, color: AppTheme.primaryGreen),
            title: Text(l10n.mushafHafs),
            subtitle: Text(l10n.mushafHafsDesc),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: onHafsTap ?? () {},
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.menu_book, color: AppTheme.accentGold),
            title: Text(l10n.mushafWarsh),
            subtitle: Text(l10n.mushafWarshDesc),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: onWarshTap ?? () {},
          ),
        ],
      ),
    );
  }
}
