import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/hizb_definitions.dart';
import '../core/extensions/khatma_creation_l10n_extension.dart';
import '../core/models/khatma.dart';
import '../core/models/khatma_creation_failure.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/khatma_creation_provider.dart';
import '../core/providers/reading_provider.dart';
import '../core/theme/app_theme.dart';
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
        child: SafeArea(
          child: CreateCollaborativeKhatmaForm(isGroup: isGroup),
        ),
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

class CreateCollaborativeKhatmaForm extends ConsumerStatefulWidget {
  final bool isGroup;

  const CreateCollaborativeKhatmaForm({super.key, required this.isGroup});

  @override
  ConsumerState<CreateCollaborativeKhatmaForm> createState() =>
      _CreateCollaborativeKhatmaFormState();
}

class _CreateCollaborativeKhatmaFormState
    extends ConsumerState<CreateCollaborativeKhatmaForm> {
  final _titleController = TextEditingController();
  final _objectivesController = TextEditingController();
  final _membersController = TextEditingController();
  final List<String> _members = [];
  bool _navigated = false;
  bool _isBusy = false;
  KhatmaCreationPhase _phase = KhatmaCreationPhase.idle;
  KhatmaCreationFailure? _failure;

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

  String _ctaLabel(AppLocalizations l10n, KhatmaCreationSession session) {
    return switch (session.phase) {
      KhatmaCreationPhase.submitting => l10n.khatmaCreationSubmitting,
      KhatmaCreationPhase.initializing => l10n.khatmaCreationInitializing,
      KhatmaCreationPhase.ready => l10n.khatmaCreated,
      KhatmaCreationPhase.idle =>
        session.failure != null ? l10n.khatmaCreationRetry : l10n.createKhatma,
    };
  }

  Future<void> _submit() async {
    if (_isBusy || _navigated) return;

    final l10n = AppLocalizations.of(context)!;
    final user = ref.read(currentUserProvider);
    final createdBy = user?.email?.trim();
    if (createdBy == null || createdBy.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.khatmaCreationAuthRequired),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final title = _titleController.text.trim().isEmpty
        ? l10n.myKhatma
        : _titleController.text.trim();
    final objectives = _objectivesController.text.trim();

    setState(() {
      _isBusy = true;
      _phase = KhatmaCreationPhase.submitting;
      _failure = null;
    });

    try {
      setState(() => _phase = KhatmaCreationPhase.initializing);
      final ready = await ref
          .read(khatmaCreationControllerProvider.notifier)
          .submit(
            title: title,
            createdBy: createdBy,
            isGroup: widget.isGroup,
            isPublic: false,
            hizbDefinitionId: HizbDefinitions.quranFoundationHafsV1,
            objectives: objectives.isEmpty ? null : objectives,
            members: List<String>.from(_members),
          );

      if (!mounted || _navigated) return;
      setState(() => _phase = KhatmaCreationPhase.ready);
      if (ready.id != ref.read(khatmaCreationControllerProvider).khatmaId) {
        throw InitializationFailed(
          'Route id mismatch',
          khatmaId: ready.id,
        );
      }

      ref.invalidate(khatmatProvider);
      ref.invalidate(khatmatWithStatusProvider);
      ref.invalidate(totalCompletedHizbProvider);
      ref.invalidate(khatmaLoadProvider(ready.id));
      ref.invalidate(khatmaByIdProvider(ready.id));

      if (!mounted) return;
      final router = GoRouter.of(context);
      final nav = Navigator.of(context);
      _navigated = true;
      if (nav.canPop()) {
        nav.pop();
      }
      router.push('/khatma/${ready.id}', extra: {'khatma': ready});
    } on KhatmaCreationFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _phase = KhatmaCreationPhase.idle;
        _failure = failure;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translateKhatmaCreationKey(failure.userMessageKey()),
          ),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: l10n.khatmaCreationRetry,
            onPressed: _submit,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final busy = _isBusy || _navigated;
    final session = KhatmaCreationSession(
      phase: _phase,
      failure: _failure,
    );

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
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
            enabled: !busy,
            decoration: InputDecoration(
              labelText: l10n.khatmaTitle,
              hintText: l10n.khatmaExampleTitle,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _objectivesController,
            enabled: !busy,
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
                    enabled: !busy,
                    decoration: InputDecoration(
                      labelText: l10n.inviteMembers,
                      hintText: l10n.memberEmail,
                    ),
                    onSubmitted: (_) => _addMember(),
                  ),
                ),
                IconButton(
                  onPressed: busy ? null : _addMember,
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
                          onDeleted: busy
                              ? null
                              : () => setState(() => _members.remove(m)),
                        ))
                    .toList(),
              ),
            ],
          ],
          if (session.failure != null) ...[
            const SizedBox(height: 16),
            Text(
              l10n.translateKhatmaCreationKey(
                session.failure!.userMessageKey(),
              ),
              style: TextStyle(color: Colors.red.shade700),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: busy ? null : _submit,
            child: Text(_ctaLabel(l10n, session)),
          ),
        ],
        ),
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
