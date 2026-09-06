import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../constants/hizb_definitions.dart';
import '../models/khatma.dart';
import '../models/khatma_creation_failure.dart';
import '../utils/auth_diag.dart';

/// Contrat injectable (tests + UI) pour la création collaborative.
abstract interface class KhatmaCreator {
  String allocateKhatmaId();

  Future<Khatma> createKhatma({
    required String title,
    required String createdBy,
    required bool isGroup,
    required bool isPublic,
    required String? hizbDefinitionId,
    String? resumeKhatmaId,
    String? objectives,
    List<String> members,
  });
}

/// Server-authoritative Khatma creation via Firebase callable Functions.
class KhatmaCreationService implements KhatmaCreator {
  KhatmaCreationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _khatmat =>
      _firestore.collection('khatmat');

  /// Alloue un ID Firestore avant toute écriture (compatibility shim).
  /// Note: The server now allocates IDs, but this maintains interface compatibility.
  @override
  String allocateKhatmaId() => _khatmat.doc().id;

  /// Crée une Khatma collaborative via Firebase callable function.
  @override
  Future<Khatma> createKhatma({
    required String title,
    required String createdBy,
    required bool isGroup,
    required bool isPublic,
    required String? hizbDefinitionId,
    String? resumeKhatmaId,
    String? objectives,
    List<String> members = const [],
  }) async {
    await AuthDiag.logContext('createKhatma', refreshToken: true);
    _requireAuthenticatedCreator(createdBy);

    if (hizbDefinitionId != null) {
      HizbDefinitions.requireSupported(hizbDefinitionId);
    }

    try {
      _logStage('call_function', null);

      // Call server-authoritative function
      final callable = _functions.httpsCallable('createCollaborativeKhatma');
      final result = await callable.call<Map<String, dynamic>>({
        'title': title,
        'isGroup': isGroup,
        'isPublic': isPublic,
        if (hizbDefinitionId != null) 'hizbDefinitionId': hizbDefinitionId,
        if (objectives != null && objectives.trim().isNotEmpty)
          'objectives': objectives.trim(),
        if (members.isNotEmpty) 'members': members,
      });

      final khatmaId = result.data['khatmaId'] as String;
      _logStage('function_success', khatmaId);

      // Load created Khatma
      final khatma = await _loadKhatma(khatmaId);
      _logStage('loaded', khatmaId);

      return khatma;
    } on FirebaseFunctionsException catch (e) {
      _logStage('function_error_${e.code}', null);
      throw _mapFunctionsException(e);
    } on FirebaseException catch (e) {
      _logStage('firebase_${e.code}', null);
      throw fromFirebaseException(e, khatmaId: null);
    } catch (e) {
      _logStage('unknown', null);
      throw UnknownCreationError(e.runtimeType.toString(), khatmaId: null);
    }
  }

  void _logStage(String stage, String? khatmaId) {
    if (kDebugMode) {
      debugPrint('[KhatmaCreation] stage=$stage khatmaId=${khatmaId ?? '-'}');
    }
  }

  void _requireAuthenticatedCreator(String createdBy) {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      throw const AuthenticationRequired();
    }
    if (email != createdBy) {
      throw const PermissionDenied();
    }
  }

  Future<Khatma> _loadKhatma(String khatmaId) async {
    final doc = await _khatmat.doc(khatmaId).get();
    if (!doc.exists) {
      throw InitializationFailed(
        'Created Khatma not found',
        khatmaId: khatmaId,
      );
    }
    return Khatma.fromMap({...doc.data()!, 'id': doc.id});
  }

  KhatmaCreationFailure _mapFunctionsException(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return const AuthenticationRequired();
      case 'permission-denied':
        return const PermissionDenied();
      case 'invalid-argument':
        return InitializationFailed(e.message ?? 'Invalid request');
      case 'failed-precondition':
        return InitializationFailed(e.message ?? 'Precondition failed');
      case 'unavailable':
      case 'deadline-exceeded':
        return NetworkError();
      default:
        return UnknownCreationError(
          '${e.code}: ${e.message}',
          khatmaId: null,
        );
    }
  }
}
