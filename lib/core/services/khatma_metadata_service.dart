import 'package:flutter/foundation.dart';

import '../api/anis_api_client.dart';
import '../api/api_exception.dart';
import '../models/khatma.dart';
import '../utils/auth_diag.dart';

/// Mise à jour serveur du titre / objectifs d'une Khatma (créateur uniquement).
class KhatmaMetadataService {
  KhatmaMetadataService({AnisApiClient? apiClient})
      : _apiClient = apiClient ?? AnisApiClient();

  final AnisApiClient _apiClient;

  /// Retourne la khatma avec titre/objectifs à jour (réponse API, sans relecture Firestore).
  Future<Khatma> updateMetadata({
    required Khatma current,
    required String title,
    String? objectives,
  }) async {
    await AuthDiag.logContext('updateKhatmaMetadata', refreshToken: true);

    final trimmedTitle = title.trim();
    final trimmedObjectives = objectives?.trim();

    final body = <String, dynamic>{
      'title': trimmedTitle,
      'objectives':
          trimmedObjectives == null || trimmedObjectives.isEmpty
              ? null
              : trimmedObjectives,
    };

    try {
      final response = await _apiClient.post(
        '/khatmat/${current.id}/metadata',
        body: body,
      );
      final data = response['data'] as Map<String, dynamic>?;
      if (data?['success'] != true || data?['title'] is! String) {
        throw ApiException(
          code: ApiErrorCode.internal,
          message: 'Unexpected API response',
        );
      }

      final apiTitle = data!['title'] as String;
      final apiObjectives = data.containsKey('objectives')
          ? data['objectives'] as String?
          : current.objectives;

      return current.copyWith(
        title: apiTitle,
        objectives: apiObjectives,
      );
    } on ApiException catch (e) {
      debugPrint(
        '[KhatmaMetadata] API error code=${e.code} status=${e.statusCode} '
        'requestId=${e.requestId} msg=${e.message}',
      );
      rethrow;
    }
  }
}
