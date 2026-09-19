import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_exception.dart';
import '../extensions/l10n_extensions.dart';
import '../models/khatma.dart';
import '../providers/home_dashboard_provider.dart';
import '../providers/reading_provider.dart';
import '../../l10n/gen_l10n/app_localizations.dart';
import 'anis_button.dart';

Future<Khatma?> showEditKhatmaMetadataSheet(
  BuildContext context,
  WidgetRef ref,
  Khatma khatma,
) {
  final hostContext = context;
  return showModalBottomSheet<Khatma>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: _EditKhatmaMetadataSheet(
          hostContext: hostContext,
          khatma: khatma,
        ),
      );
    },
  );
}

class _EditKhatmaMetadataSheet extends ConsumerStatefulWidget {
  const _EditKhatmaMetadataSheet({
    required this.hostContext,
    required this.khatma,
  });

  final BuildContext hostContext;
  final Khatma khatma;

  @override
  ConsumerState<_EditKhatmaMetadataSheet> createState() =>
      _EditKhatmaMetadataSheetState();
}

class _EditKhatmaMetadataSheetState
    extends ConsumerState<_EditKhatmaMetadataSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _objectivesController;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.khatma.title);
    _objectivesController = TextEditingController(
      text: widget.khatma.objectives ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _objectivesController.dispose();
    super.dispose();
  }

  String _messageForError(Object error, AppLocalizations l10n) {
    if (error is ApiException) {
      if (error.code == ApiErrorCode.notFound) {
        return l10n.khatmaMetadataApiOutdated;
      }
      if (error.code == ApiErrorCode.forbidden) {
        return l10n.khatmaMetadataForbidden;
      }
      if (error.code == ApiErrorCode.networkError ||
          error.code == ApiErrorCode.timeout) {
        return l10n.khatmaMetadataNetworkError;
      }
      if (error.code == ApiErrorCode.authRequired ||
          error.code == ApiErrorCode.authInvalid) {
        return l10n.khatmaMetadataAuthError;
      }
      if (error.code == ApiErrorCode.internal && error.message != null) {
        return '${l10n.khatmaMetadataSaveFailed}\n(${error.message})';
      }
    }
    return l10n.khatmaMetadataSaveFailed;
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final newTitle = _titleController.text.trim();
    if (newTitle.isEmpty) return;

    final newObjectives = _objectivesController.text.trim();
    final unchanged = newTitle == widget.khatma.title.trim() &&
        newObjectives == (widget.khatma.objectives ?? '').trim();
    if (unchanged) {
      if (mounted) Navigator.pop(context);
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final updated = await ref.read(khatmaMetadataServiceProvider).updateMetadata(
            current: widget.khatma,
            title: newTitle,
            objectives: newObjectives,
          );

      ref.invalidate(khatmatProvider);
      ref.invalidate(homeDashboardProvider);
      ref.invalidate(khatmaByIdProvider(widget.khatma.id));
      ref.invalidate(khatmaStreamProvider(widget.khatma.id));

      if (!mounted) return;
      Navigator.pop(context, updated);
      if (widget.hostContext.mounted) {
        ScaffoldMessenger.of(widget.hostContext).showSnackBar(
          SnackBar(content: Text(l10n.khatmaMetadataSaved)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = _messageForError(e, l10n));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.editKhatmaMetadata,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              enabled: !_saving,
              decoration: InputDecoration(
                labelText: l10n.khatmaTitle,
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _objectivesController,
              enabled: !_saving,
              decoration: InputDecoration(
                labelText: l10n.objectives,
              ),
              minLines: 2,
              maxLines: 4,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
              if (_errorMessage == l10n.khatmaMetadataApiOutdated) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.khatmaMetadataApiOutdatedHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700],
                      ),
                ),
              ],
            ],
            const SizedBox(height: 20),
            AnisButton(
              label: _saving ? '…' : l10n.saveKhatmaChanges,
              onPressed: _saving ? null : _save,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}
