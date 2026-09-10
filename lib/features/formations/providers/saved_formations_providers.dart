import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/saved_formation_item.dart';
import 'formations_providers.dart';

/// Provider for all saved formation items
final savedFormationsProvider =
    FutureProvider<List<SavedFormationItem>>((ref) async {
  final apiService = ref.watch(formationsApiServiceProvider);
  return apiService.getSavedItems();
});

/// Provider to check if a specific target is saved
final isSavedProvider =
    Provider.family<bool, ({SavedItemType type, String targetId})>((ref, param) {
  final savedItemsAsync = ref.watch(savedFormationsProvider);

  return savedItemsAsync.maybeWhen(
    data: (items) => items.any(
      (item) => item.type == param.type && item.targetId == param.targetId,
    ),
    orElse: () => false,
  );
});

/// Notifier for saved formations mutations
final savedFormationsNotifierProvider =
    Provider<SavedFormationsNotifier>((ref) {
  return SavedFormationsNotifier(ref);
});

class SavedFormationsNotifier {
  final Ref _ref;

  SavedFormationsNotifier(this._ref);

  /// Save a formation item (idempotent)
  Future<void> saveItem({
    required SavedItemType type,
    required String targetId,
    String? courseId,
  }) async {
    final apiService = _ref.read(formationsApiServiceProvider);

    await apiService.saveItem(
      type: type,
      targetId: targetId,
      courseId: courseId,
    );

    // Refresh the list
    _ref.invalidate(savedFormationsProvider);
  }

  /// Remove a saved item by ID
  Future<void> removeSavedItemById(String savedItemId) async {
    final apiService = _ref.read(formationsApiServiceProvider);

    await apiService.removeSavedItem(savedItemId);

    // Refresh the list
    _ref.invalidate(savedFormationsProvider);
  }

  /// Remove a saved item by finding it first (by type and targetId)
  Future<void> removeSavedItem({
    required SavedItemType type,
    required String targetId,
  }) async {
    // Find the saved item first
    final savedItemsAsync = _ref.read(savedFormationsProvider);
    final savedItem = savedItemsAsync.valueOrNull?.firstWhere(
      (item) => item.type == type && item.targetId == targetId,
      orElse: () => throw Exception('Saved item not found'),
    );

    if (savedItem != null) {
      await removeSavedItemById(savedItem.id);
    }
  }

  /// Toggle saved state (save if not saved, remove if saved)
  Future<void> toggleSaved({
    required SavedItemType type,
    required String targetId,
    String? courseId,
  }) async {
    final isSaved = _ref.read(isSavedProvider((type: type, targetId: targetId)));

    if (isSaved) {
      await removeSavedItem(type: type, targetId: targetId);
    } else {
      await saveItem(type: type, targetId: targetId, courseId: courseId);
    }
  }
}
