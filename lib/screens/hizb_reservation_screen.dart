import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quran/flutter_quran.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/hizb_definitions.dart';
import '../core/data/quran_hizb_data.dart';
import '../core/repositories/hizb_index_repository.dart';
import '../core/models/hizb_display_metadata.dart';
import '../core/models/hizb_reservation.dart';
import '../core/models/khatma.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/reading_provider.dart';
import '../core/services/khatma_completion_seen_service.dart';
import '../core/services/khatma_link_service.dart';
import '../core/services/guest_service.dart';
import '../core/utils/error_utils.dart';
import '../core/utils/khatma_completion_utils.dart';
import '../core/services/reservation_service.dart';
import '../core/utils/khatma_participant_id.dart';
import '../core/theme/app_theme.dart';
import '../core/extensions/l10n_extensions.dart';
import '../widgets/khatma/khatma_completion_celebration_overlay.dart';
import 'mushaf_hafs_screen.dart';
import 'mushaf_warsh_screen.dart';
import 'mushaf_women_screen.dart';

/// Écran de réservation collaborative des Hizb
class HizbReservationScreen extends ConsumerStatefulWidget {
  final Khatma khatma;
  final String? guestId;

  const HizbReservationScreen({super.key, required this.khatma, this.guestId});

  @override
  ConsumerState<HizbReservationScreen> createState() =>
      _HizbReservationScreenState();
}

class _HizbReservationScreenState extends ConsumerState<HizbReservationScreen> {
  final Set<int> _optimisticReserved = {};
  final Map<int, String> _optimisticReservedNames = {};
  final Set<int> _optimisticCompleted = {};
  bool _isLoading = false;
  bool _isGridView = false; // false = liste (affichage préféré), true = grille
  /// Cache local pour mise à jour dynamique du compteur (Khatma locale ou délai provider)
  Khatma? _lastKnownKhatma;
  String? _legacyGuestId;
  bool _completionHandled = false;

  @override
  void initState() {
    super.initState();
    _loadLegacyGuestId();
  }

  Future<void> _loadLegacyGuestId() async {
    if (widget.guestId == null) return;
    final legacy = await GuestService().getLegacyGuestIdForKhatma(
      widget.khatma.id,
    );
    if (mounted && legacy != null) {
      setState(() => _legacyGuestId = legacy);
    }
  }

  String get _userId {
    if (widget.guestId != null) return widget.guestId!;
    final fromAuth = KhatmaParticipantId.fromFirebaseUser(
      FirebaseAuth.instance.currentUser,
    );
    if (fromAuth != null) return fromAuth;
    return ref.read(currentUserProvider)?.email ?? 'demo';
  }

  Khatma get _khatma {
    final stream =
        ref.watch(khatmaStreamProvider(widget.khatma.id)).valueOrNull;
    final fromProvider =
        stream ?? ref.watch(khatmaByIdProvider(widget.khatma.id)).valueOrNull;
    // Priorité : provider (Firestore) > cache local (après mutation) > initial
    if (fromProvider != null) {
      _lastKnownKhatma = fromProvider;
    }
    var k = fromProvider ?? _lastKnownKhatma ?? widget.khatma;
    for (final n in _optimisticReserved) {
      k = k.copyWith(
        hizbReservations: {
          ...k.hizbReservations,
          n: HizbReservation(
            status: HizbReservationStatus.reserved,
            reservedBy: _userId,
            reservedForName: _optimisticReservedNames[n],
            reservedAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(days: 7)),
          ),
        },
      );
    }
    for (final n in _optimisticCompleted) {
      final prev = k.hizbReservations[n];
      if (prev != null) {
        k = k.copyWith(
          hizbReservations: {
            ...k.hizbReservations,
            n: prev.copyWith(
              status: HizbReservationStatus.completed,
              completedAt: DateTime.now(),
            ),
          },
        );
      }
    }
    return k;
  }

  HizbReservation _resolveForDisplay(HizbReservation r) {
    if (r.isSoftLocked &&
        r.softLockExpiresAt != null &&
        DateTime.now().isAfter(r.softLockExpiresAt!)) {
      return const HizbReservation(status: HizbReservationStatus.available);
    }
    if (r.isReserved &&
        r.expiresAt != null &&
        DateTime.now().isAfter(r.expiresAt!)) {
      return const HizbReservation(status: HizbReservationStatus.expired);
    }
    return r;
  }

  HizbReservation _getReservation(int hizbNum) {
    final r = _khatma.hizbReservations[hizbNum] ??
        (_khatma.hasSupportedHizbDefinition
            ? HizbIndexRepository.reservationSnapshot(
                hizbNum,
                definitionId: _khatma.hizbDefinitionId,
              )
            : const HizbReservation(
                status: HizbReservationStatus.available,
                hizbNumber: null,
              ));
    return _resolveForDisplay(r.copyWith(hizbNumber: hizbNum));
  }

  HizbDisplayMetadata? _metadataFor(int hizbNum) {
    if (!_khatma.hasSupportedHizbDefinition) return null;
    return HizbDisplayMetadata.fromDefinition(
      hizbNum,
      definitionId: _khatma.hizbDefinitionId,
      languageCode: Localizations.localeOf(context).languageCode,
    );
  }

  bool _isMine(int hizbNum) {
    final r = _getReservation(hizbNum);
    return KhatmaParticipantId.ownsReservation(
      r,
      _userId,
      legacyGuestId: _legacyGuestId,
    );
  }

  String _reservationErrorMessage(ReservationException e) {
    switch (e.code) {
      case ReservationErrorCode.alreadyReserved:
        return 'Hizb ${e.hizbNumber ?? 0} déjà réservé';
      case ReservationErrorCode.limitReached:
        return e.message;
      case ReservationErrorCode.expired:
        return 'Réservation expirée';
      case ReservationErrorCode.softLockExpired:
        return 'Pré-réservation expirée';
      case ReservationErrorCode.notYours:
        return 'Ce Hizb ne vous appartient pas';
      case ReservationErrorCode.alreadyExtended:
        return 'Prolongation déjà utilisée';
      default:
        return e.message;
    }
  }

  /// Nom affiché pour "Pour moi" (invité ou compte)
  String get _myDisplayName {
    if (widget.guestId != null) {
      return KhatmaParticipantId.displayNameFromKhatma(
        guestParticipants: _khatma.guestParticipants,
        participantId: _userId,
        legacyGuestId: _legacyGuestId,
      );
    }
    final email = ref.read(currentUserProvider)?.email;
    if (email != null && _khatma.guestParticipants[email] != null) {
      return _khatma.guestParticipants[email]!;
    }
    final user = ref.read(currentUserProvider);
    final dn = user?.displayName?.trim();
    return dn != null && dn.isNotEmpty
        ? dn
        : (user?.email?.split('@').first ?? 'Anonyme');
  }

  Future<void> _showReserveForDialog(
    int hizbNum, {
    required void Function(String? name) onConfirm,
  }) async {
    if (!mounted) return;
    final name = await showDialog<String?>(
      context: context,
      builder:
          (ctx) => _ReserveForDialog(
            hizbNum: hizbNum,
            myDisplayName: _myDisplayName,
            onConfirm: (n) => Navigator.pop(ctx, n),
          ),
    );
    onConfirm(name);
  }

  Future<void> _reserve(int hizbNum, {String? reservedForName}) async {
    if (_isLoading) return;
    final service = ref.read(reservationServiceProvider);
    final idempotencyKey = 'reserve_${_khatma.id}_$hizbNum';

    setState(() {
      _optimisticReserved.add(hizbNum);
      if (reservedForName != null)
        _optimisticReservedNames[hizbNum] = reservedForName;
      _isLoading = true;
    });

    try {
      await service.reserve(
        _khatma.id,
        hizbNum,
        _userId,
        reservedForName: reservedForName ?? _myDisplayName,
        idempotencyKey: idempotencyKey,
        source: widget.guestId != null ? 'webGuest' : 'app',
      );
      if (mounted) {
        final name = reservedForName ?? _myDisplayName;
        setState(() {
          _optimisticReserved.remove(hizbNum);
          _optimisticReservedNames.remove(hizbNum);
          _isLoading = false;
          _lastKnownKhatma = _khatma.copyWith(
            hizbReservations: {
              ..._khatma.hizbReservations,
              hizbNum: HizbReservation(
                status: HizbReservationStatus.reserved,
                reservedBy: _userId,
                reservedForName: name,
                reservedAt: DateTime.now(),
                expiresAt: DateTime.now().add(const Duration(hours: 48)),
              ),
            },
          );
        });
        ref.invalidate(khatmaByIdProvider(_khatma.id));
        ref.invalidate(khatmatProvider);
        ref.invalidate(khatmatWithStatusProvider);
        ref.invalidate(khatmaProgressProvider(_khatma.id));
        ref.invalidate(totalCompletedHizbProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hizb $hizbNum réservé ! (48h)'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } on ReservationException catch (e) {
      if (mounted) {
        setState(() {
          _optimisticReserved.remove(hizbNum);
          _optimisticReservedNames.remove(hizbNum);
          _isLoading = false;
        });
        ref.invalidate(khatmaByIdProvider(_khatma.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_reservationErrorMessage(e)),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _optimisticReserved.remove(hizbNum);
          _optimisticReservedNames.remove(hizbNum);
          _isLoading = false;
        });
        ref.invalidate(khatmaByIdProvider(_khatma.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorUtils.reservationMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _release(int hizbNum) async {
    if (_isLoading) return;
    final service = ref.read(reservationServiceProvider);

    setState(() => _isLoading = true);
    try {
      await service.release(_khatma.id, hizbNum, _userId);
      if (mounted) {
        setState(() => _isLoading = false);
        ref.invalidate(khatmaByIdProvider(_khatma.id));
        ref.invalidate(khatmatProvider);
        ref.invalidate(khatmatWithStatusProvider);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hizb $hizbNum libéré')));
      }
    } on ReservationException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_reservationErrorMessage(e)),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorUtils.reservationMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _start(int hizbNum) async {
    if (_isLoading) return;
    final service = ref.read(reservationServiceProvider);

    setState(() => _isLoading = true);
    try {
      await service.start(_khatma.id, hizbNum, _userId);
      if (mounted) {
        setState(() => _isLoading = false);
        ref.invalidate(khatmaByIdProvider(_khatma.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hizb $hizbNum : en cours de lecture')),
        );
      }
    } on ReservationException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_reservationErrorMessage(e)),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorUtils.reservationMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showNiyyahAndComplete(int hizbNum) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Intention (Niyyah)'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Optionnel : inscrivez votre intention avant de marquer ce Hizb comme terminé.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Ex: Pour plaire à Allah, pour ma famille...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Passer'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _complete(hizbNum);
                },
                child: const Text('Terminer'),
              ),
            ],
          ),
    );
  }

  Future<void> _maybeHandleKhatmaCompleted({
    required bool triggeredByUser,
  }) async {
    if (_completionHandled) return;
    if (!KhatmaCompletionUtils.isFullyCompleted(_khatma)) return;
    _completionHandled = true;

    final seenService = KhatmaCompletionSeenService();
    final alreadySeen = await seenService.hasSeenCelebration(_khatma.id);
    final playCelebration = triggeredByUser && !alreadySeen;

    if (playCelebration) {
      await seenService.markCelebrationSeen(_khatma.id);
      if (!mounted) return;
      await KhatmaCompletionCelebrationOverlay.show(
        context,
        completed: AppConstants.totalHizb,
        total: AppConstants.totalHizb,
      );
    }

    if (!mounted) return;
    context.pushReplacement(
      KhatmaLinkService.completionPath(_khatma.id),
      extra: {'khatma': _khatma, 'playCelebration': playCelebration},
    );
  }

  Future<void> _complete(int hizbNum) async {
    if (_isLoading) return;
    final service = ref.read(reservationServiceProvider);
    final countBefore = _khatma.completedReservationCount;

    setState(() {
      _optimisticCompleted.add(hizbNum);
      _isLoading = true;
    });

    try {
      final authUid =
          widget.guestId != null
              ? FirebaseAuth.instance.currentUser?.uid
              : null;
      final idempotencyKey = 'done_${_khatma.id}_$hizbNum';
      await service.done(
        _khatma.id,
        hizbNum,
        _userId,
        authUid: authUid,
        idempotencyKey: idempotencyKey,
      );
      if (mounted) {
        final prev = _khatma.hizbReservations[hizbNum];
        setState(() {
          _optimisticCompleted.remove(hizbNum);
          _isLoading = false;
          if (prev != null) {
            _lastKnownKhatma = _khatma.copyWith(
              hizbReservations: {
                ..._khatma.hizbReservations,
                hizbNum: prev.copyWith(
                  status: HizbReservationStatus.completed,
                  completedAt: DateTime.now(),
                ),
              },
            );
          }
        });
        ref.invalidate(khatmaByIdProvider(_khatma.id));
        ref.invalidate(khatmatProvider);
        ref.invalidate(khatmatWithStatusProvider);
        ref.invalidate(khatmaProgressProvider(_khatma.id));
        ref.invalidate(totalCompletedHizbProvider);

        final reachedCompletion = countBefore >= AppConstants.totalHizb - 1;
        if (reachedCompletion) {
          _lastKnownKhatma = (_lastKnownKhatma ?? _khatma).copyWith(
            completedHizbCount: AppConstants.totalHizb,
            completedAt: DateTime.now(),
          );
          await _maybeHandleKhatmaCompleted(triggeredByUser: true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hizb $hizbNum terminé ! ماشاء الله'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        }
      }
    } on ReservationException catch (e) {
      if (mounted) {
        setState(() {
          _optimisticCompleted.remove(hizbNum);
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_reservationErrorMessage(e)),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _optimisticCompleted.remove(hizbNum);
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorUtils.reservationMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _extend(int hizbNum) async {
    if (_isLoading) return;
    final service = ref.read(reservationServiceProvider);

    setState(() => _isLoading = true);
    try {
      await service.extend(_khatma.id, hizbNum, _userId);
      if (mounted) {
        setState(() => _isLoading = false);
        ref.invalidate(khatmaByIdProvider(_khatma.id));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hizb $hizbNum prolongé +24h')));
      }
    } on ReservationException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_reservationErrorMessage(e)),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorUtils.reservationMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  int? _pickAvailableHizb() {
    final service = ref.read(reservationServiceProvider);
    final limit = service.maxHizbPerUser(_khatma);
    if (_khatma.reservedByUser(_userId) >= limit) return null;
    final available = <int>[];
    for (var i = 1; i <= AppConstants.totalHizb; i++) {
      final r = _getReservation(i);
      if (r.isAvailable) available.add(i);
    }
    if (available.isEmpty) return null;
    return available[Random().nextInt(available.length)];
  }

  Future<void> _autoReserve() async {
    final hizb = _pickAvailableHizb();
    if (hizb != null) {
      _showReserveForDialog(
        hizb,
        onConfirm: (name) async {
          if (name != null) await _reserve(hizb, reservedForName: name);
        },
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucun Hizb disponible ou limite atteinte'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Widget _buildHizbItem(
    BuildContext context,
    int hizbNum,
    int index,
    bool isGrid,
  ) {
    final r = _getReservation(hizbNum);
    final isMine = _isMine(hizbNum);
    final isAvailable = r.isAvailable;
    final isCompleted = r.isCompleted;
    final isInProgress = r.isInProgress;
    final isSoftLocked = r.isSoftLocked;

    Color bgColor;
    IconData? icon;
    if (isCompleted) {
      bgColor = AppTheme.primaryGreen.withValues(alpha: 0.3);
      icon = Icons.check_circle;
    } else if (isMine && isInProgress) {
      bgColor = Colors.blue.withValues(alpha: 0.2);
      icon = Icons.play_circle;
    } else if (isMine) {
      bgColor = AppTheme.primaryGreen.withValues(alpha: 0.2);
      icon = Icons.person;
    } else if (isSoftLocked) {
      bgColor = Colors.amber.withValues(alpha: 0.2);
      icon = Icons.schedule;
    } else if (isAvailable) {
      bgColor = Colors.grey.withValues(alpha: 0.2);
      icon = null;
    } else {
      bgColor = Colors.orange.withValues(alpha: 0.2);
      icon = Icons.lock;
    }

    final metadata = _metadataFor(hizbNum);
    final range = metadata?.rangeLabel ?? '—';
    final displayName =
        !isAvailable &&
                r.reservedForName != null &&
                r.reservedForName!.isNotEmpty
            ? r.reservedForName!
            : null;

    if (isGrid) {
      return Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: _isLoading ? null : () => _showHizbActions(hizbNum),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null)
                  Icon(icon, size: 16, color: AppTheme.primaryGreen),
                if (icon != null) const SizedBox(height: 2),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showHizbReaderModal(context, hizbNum),
                  child: Text(
                    '$hizbNum',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color:
                          isAvailable
                              ? Colors.grey[700]
                              : AppTheme.primaryGreen,
                    ),
                  ),
                ),
                if (displayName != null)
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 8,
                      color: AppTheme.customNameColor,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Text(
                    range.split(' - ').first,
                    style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // Vue liste (style capture : cartes arrondies, badge gris/vert, Non assigné / Moi)
    final statusText =
        isAvailable
            ? 'Non assigné'
            : (isMine ? (displayName ?? 'Moi') : (displayName ?? 'Réservé'));
    final surah = metadata?.localizedSurahLabel ?? '—';
    final badgeColor =
        isAvailable || (!isMine && !isCompleted)
            ? Colors.grey.shade300
            : AppTheme.hizbReservedBadge.withValues(alpha: 0.35);
    final badgeTextColor =
        isAvailable || (!isMine && !isCompleted)
            ? Colors.grey.shade700
            : AppTheme.primaryGreen;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: _isLoading ? null : () => _showHizbActions(hizbNum),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Tooltip(
                message: 'Lire le Hizb',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showHizbReaderModal(context, hizbNum),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      metadata == null
                          ? 'Hizb $hizbNum'
                          : 'Hizb $hizbNum · ${metadata.localizedJuzLabel}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: badgeTextColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color:
                            displayName != null
                                ? AppTheme.customNameColor
                                : Colors.grey.shade800,
                      ),
                    ),
                    if (surah.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        surah,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      range,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (metadata != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        metadata.localizedPagesLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit, size: 22, color: Colors.grey.shade600),
                onPressed: _isLoading ? null : () => _showHizbActions(hizbNum),
                tooltip: 'Choisir ou réserver',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHizbReaderModal(BuildContext context, int hizbNum) {
    if (!_khatma.hasSupportedHizbDefinition) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cette Khatma doit être recréée avec le référentiel Hizb canonique.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final l10n = context.l10n;

    showModalBottomSheet(
      context: context,
      builder:
          (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${l10n.chooseMushafType} — Hizb $hizbNum',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: Icon(
                      Icons.menu_book,
                      color: AppTheme.primaryGreen,
                    ),
                    title: Text(l10n.mushafHafs),
                    subtitle: Text(l10n.mushafHafsDesc),
                    onTap: () {
                      Navigator.pop(ctx);
                      _openMushafModal(context, hizbNum, 'hafs');
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.menu_book, color: AppTheme.accentGold),
                    title: Text(l10n.mushafWarsh),
                    subtitle: Text(l10n.mushafWarshDesc),
                    onTap: () {
                      Navigator.pop(ctx);
                      _openMushafModal(context, hizbNum, 'warsh');
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.favorite,
                      color: AppTheme.mushafWomenRose,
                    ),
                    title: Text(l10n.mushafWomen),
                    subtitle: Text(l10n.mushafWomenDesc),
                    onTap: () {
                      Navigator.pop(ctx);
                      _openMushafModal(context, hizbNum, 'women');
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _openMushafModal(BuildContext context, int hizbNum, String type) {
    final definitionId = _khatma.hizbDefinitionId;
    if (!HizbDefinitions.isSupported(definitionId)) return;
    // « Lire » ouvre le début du Hizb. Sur un Hizb déjà commencé, on propose la
    // dernière page lue : HizbNavigationService ne la retiendra que si elle
    // tombe effectivement dans ce Hizb, sinon il ouvre le début.
    final resumePage =
        _getReservation(hizbNum).isInProgress
            ? FlutterQuran().getCurrentPageNumber()
            : null;

    final Widget mushafScreen;
    switch (type) {
      case 'warsh':
        mushafScreen = MushafWarshScreen(
          initialHizb: hizbNum,
          hizbDefinitionId: definitionId,
          resumePage: resumePage,
        );
        break;
      case 'women':
        mushafScreen = MushafWomenScreen(
          initialHizb: hizbNum,
          hizbDefinitionId: definitionId,
          resumePage: resumePage,
        );
        break;
      default:
        mushafScreen = MushafHafsScreen(
          initialHizb: hizbNum,
          hizbDefinitionId: definitionId,
          resumePage: resumePage,
        );
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.92,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: mushafScreen,
            ),
          ),
    );
  }

  void _showHizbActions(int hizbNum) {
    final r = _getReservation(hizbNum);
    final isMine = _isMine(hizbNum);
    final isAdmin = _khatma.createdBy == _userId;

    if (r.isAvailable) {
      _showReserveForDialog(
        hizbNum,
        onConfirm: (name) {
          if (name != null) _reserve(hizbNum, reservedForName: name);
        },
      );
      return;
    }

    if (!isMine && !isAdmin) return;

    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isMine && r.isReserved && !r.isInProgress)
                  ListTile(
                    leading: const Icon(
                      Icons.play_arrow,
                      color: AppTheme.primaryGreen,
                    ),
                    title: const Text('Je commence'),
                    subtitle: const Text('Marquer comme en cours de lecture'),
                    onTap: () {
                      Navigator.pop(context);
                      _start(hizbNum);
                    },
                  ),
                if (isMine && r.isReserved)
                  ListTile(
                    leading: const Icon(
                      Icons.check_circle,
                      color: AppTheme.primaryGreen,
                    ),
                    title: const Text('Terminé'),
                    subtitle: const Text('J\'ai lu ce Hizb'),
                    onTap: () {
                      Navigator.pop(context);
                      _showNiyyahAndComplete(hizbNum);
                    },
                  ),
                if (isMine && r.canExtend)
                  ListTile(
                    leading: const Icon(Icons.schedule, color: Colors.blue),
                    title: const Text('Prolonger +24h'),
                    subtitle: const Text('Une seule prolongation possible'),
                    onTap: () {
                      Navigator.pop(context);
                      _extend(hizbNum);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.cancel, color: Colors.orange),
                  title: Text(
                    isAdmin && !isMine
                        ? 'Libérer (admin)'
                        : 'Libérer ma réservation',
                  ),
                  subtitle: const Text('Le Hizb redevient disponible'),
                  onTap: () async {
                    Navigator.pop(context);
                    if (isAdmin && !isMine) {
                      final messenger = ScaffoldMessenger.of(context);
                      final service = ref.read(reservationServiceProvider);
                      try {
                        await service.adminForceRelease(
                          _khatma.id,
                          hizbNum,
                          _userId,
                        );
                        if (mounted) {
                          ref.invalidate(khatmaByIdProvider(_khatma.id));
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Hizb $hizbNum libéré par admin'),
                            ),
                          );
                        }
                      } catch (_) {
                        if (mounted) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Erreur'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } else {
                      _release(hizbNum);
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<Khatma?>>(khatmaStreamProvider(widget.khatma.id), (
      previous,
      next,
    ) {
      final k = next.valueOrNull;
      if (k != null && KhatmaCompletionUtils.isFullyCompleted(k)) {
        _maybeHandleKhatmaCompleted(triggeredByUser: false);
      }
    });

    final completed = _khatma.completedReservationCount;
    final total = AppConstants.totalHizb;

    return Scaffold(
      appBar: AppBar(
        title: Text(_khatma.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
            onPressed: () async {
              final completed = _khatma.completedReservationCount;
              final total = AppConstants.totalHizb;
              final text = KhatmaLinkService.joinInviteMessage(
                _khatma,
                bodyPrefix:
                    '🕌 Rejoignez ma Khatma "${_khatma.title}" !\n\n'
                    'Progression : $completed/$total Hizb\n\n',
              );
              final uri = Uri.parse(
                'https://wa.me/?text=${Uri.encodeComponent(text)}',
              );
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.platformDefault);
              } else {
                Share.share(text);
              }
            },
            tooltip: 'Partager sur WhatsApp',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              final completed = _khatma.completedReservationCount;
              final total = AppConstants.totalHizb;
              Share.share(
                KhatmaLinkService.joinInviteMessage(
                  _khatma,
                  bodyPrefix:
                      '🕌 Rejoignez ma Khatma "${_khatma.title}" !\n\n'
                      'Progression : $completed/$total Hizb\n\n',
                ),
              );
            },
            tooltip: 'Partager (autre app)',
          ),
          IconButton(
            icon: const Icon(Icons.menu_book),
            onPressed: () => context.push('/mushaf/hafs'),
            tooltip: 'Ouvrir le Mushaf',
          ),
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
            tooltip: _isGridView ? 'Vue liste' : 'Vue grille',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Réservation collaborative',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.guestId != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Connecté en tant que : ${_khatma.guestParticipants[widget.guestId] ?? 'Anonyme'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Découpage Hizb: ${QuranHizbData.hizbConventionLabel}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$completed / $total Hizb complétés',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: total > 0 ? completed / total : 0,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryGreen,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 6,
                ),
                if (_khatma.createdBy == _userId && widget.guestId == null) ...[
                  _LateMembersCard(khatma: _khatma),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _autoReserve,
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: const Text('Attribue-moi un Hizb'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () async {
                        final completed = _khatma.completedReservationCount;
                        final total = AppConstants.totalHizb;
                        final text = KhatmaLinkService.joinInviteMessage(
                          _khatma,
                          bodyPrefix:
                              '🕌 Rejoignez ma Khatma "${_khatma.title}" !\n\n'
                              'Progression : $completed/$total Hizb\n\n',
                        );
                        final uri = Uri.parse(
                          'https://wa.me/?text=${Uri.encodeComponent(text)}',
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.platformDefault,
                          );
                        } else {
                          Share.share(text);
                        }
                      },
                      icon: const Icon(Icons.chat, color: Colors.white),
                      label: const Text('WhatsApp'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _LegendItem(
                      color: Colors.grey,
                      icon: Icons.circle_outlined,
                      label: 'Disponible',
                    ),
                    _LegendItem(
                      color: AppTheme.primaryGreen,
                      icon: Icons.person,
                      label: 'Réservé par moi',
                    ),
                    _LegendItem(
                      color: Colors.orange,
                      icon: Icons.lock,
                      label: 'Réservé par un autre',
                    ),
                    _LegendItem(
                      color: AppTheme.primaryGreen,
                      icon: Icons.check_circle,
                      label: 'Terminé',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Appuyez sur un Hizb disponible pour le réserver (pour vous ou pour quelqu\'un hors de l\'app). Appuyez sur vos Hizb réservés pour les terminer ou les libérer.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_isGridView) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Liste des 60 Hizb',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Découpage Hizb: ${QuranHizbData.hizbConventionLabel}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600], fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Format Sourate:Verset — ex. 1:1 = Sourate 1 verset 1, 2:74 = Sourate 2 verset 74',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Expanded(
                  child:
                      _isGridView
                          ? GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 6,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: 0.85,
                                ),
                            itemCount: total,
                            // hizbNum = i + 1 = identifiant réel (1..60), pas l'index
                            itemBuilder:
                                (context, i) =>
                                    _buildHizbItem(context, i + 1, i, true),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.only(top: 8, bottom: 16),
                            itemCount: total,
                            // hizbNum = i + 1 = identifiant réel (1..60), pas l'index
                            itemBuilder:
                                (context, i) =>
                                    _buildHizbItem(context, i + 1, i, false),
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LateMembersCard extends StatelessWidget {
  final Khatma khatma;

  const _LateMembersCard({required this.khatma});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final lateItems = <MapEntry<int, HizbReservation>>[];
    for (final e in khatma.hizbReservations.entries) {
      final r = e.value;
      if (!r.isReserved || r.isCompleted) continue;
      final expiresAt = r.expiresAt;
      if (expiresAt == null) continue;
      if (expiresAt.isBefore(now) || expiresAt.difference(now).inHours < 24) {
        lateItems.add(e);
      }
    }
    lateItems.sort((a, b) {
      final aExp = a.value.expiresAt ?? now;
      final bExp = b.value.expiresAt ?? now;
      return aExp.compareTo(bExp);
    });
    if (lateItems.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Membres à rappeler',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...lateItems.take(3).map((e) {
            final exp = e.value.expiresAt!;
            final isOverdue = exp.isBefore(now);
            final by = e.value.reservedBy ?? 'Anonyme';
            final name =
                e.value.reservedForName ??
                khatma.guestParticipants[by] ??
                (by.contains('@') ? by.split('@').first : by);
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Hizb ${e.key} — $name : ${isOverdue ? "expiré" : "expire bientôt"}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.orange.shade900),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Dialogue pour choisir « Pour moi » ou « Pour quelqu'un d'autre » avant réservation
class _ReserveForDialog extends StatefulWidget {
  final int hizbNum;
  final String myDisplayName;
  final void Function(String?) onConfirm;

  const _ReserveForDialog({
    required this.hizbNum,
    required this.myDisplayName,
    required this.onConfirm,
  });

  @override
  State<_ReserveForDialog> createState() => _ReserveForDialogState();
}

class _ReserveForDialogState extends State<_ReserveForDialog> {
  bool _isForOther = false;
  late TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.myDisplayName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onReserve() {
    final name = _isForOther ? _controller.text.trim() : widget.myDisplayName;
    if (_isForOther && name.isEmpty) {
      setState(() => _errorText = 'Veuillez saisir le nom de la personne');
      return;
    }
    setState(() => _errorText = null);
    widget.onConfirm(name.isEmpty ? widget.myDisplayName : name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Hizb ${widget.hizbNum} — Pour qui réserver ?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RadioListTile<bool>(
              title: Text('Pour moi (${widget.myDisplayName})'),
              value: false,
              groupValue: _isForOther,
              onChanged:
                  (v) => setState(() {
                    _isForOther = false;
                    _errorText = null;
                  }),
            ),
            RadioListTile<bool>(
              title: const Text('Pour quelqu\'un d\'autre'),
              subtitle: const Text(
                'Personne hors de l\'app (ex: grand-parent, ami)',
              ),
              value: true,
              groupValue: _isForOther,
              onChanged:
                  (v) => setState(() {
                    _isForOther = true;
                    _errorText = null;
                  }),
            ),
            if (_isForOther) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'Nom de la personne',
                  hintText:
                      'Ex: Ahmed, Fatima... (pas besoin d\'être dans l\'app)',
                  errorText: _errorText,
                ),
                textCapitalization: TextCapitalization.words,
                autofocus: true,
                onChanged: (_) => setState(() => _errorText = null),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => widget.onConfirm(null),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _onReserve, child: const Text('Réserver')),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _LegendItem({
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
        ),
      ],
    );
  }
}
