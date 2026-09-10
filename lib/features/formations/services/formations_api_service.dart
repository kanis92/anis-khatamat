import '../../../core/api/anis_api_client.dart';

class FormationProgressResponse {
  final String pathId;
  final String? lastLessonId;
  final List<String> completedLessonIds;
  final DateTime lastAccessedAt;

  const FormationProgressResponse({
    required this.pathId,
    required this.lastLessonId,
    required this.completedLessonIds,
    required this.lastAccessedAt,
  });

  factory FormationProgressResponse.fromJson(Map<String, dynamic> json) {
    return FormationProgressResponse(
      pathId: json['pathId'] as String,
      lastLessonId: json['lastLessonId'] as String?,
      completedLessonIds: List<String>.from(json['completedLessonIds'] as List? ?? []),
      lastAccessedAt: DateTime.parse(json['lastAccessedAt'] as String),
    );
  }
}

/// Server-authoritative API service for Formation progress
class FormationsApiService {
  final AnisApiClient _client;

  FormationsApiService(this._client);

  /// Get all formation progress records for the authenticated user
  /// Returns empty list if no progress exists
  Future<List<FormationProgressResponse>> getAllProgress() async {
    final response = await _client.get('/v1/formations/progress');

    final data = response['data'] as List<dynamic>?;
    if (data == null || data.isEmpty) {
      return [];
    }

    return data
        .map((item) => FormationProgressResponse.fromJson(
              item as Map<String, dynamic>,
            ))
        .toList();
  }

  /// Get user's progress for a learning path
  /// Returns null if no progress exists yet
  Future<FormationProgressResponse?> getProgress(String pathId) async {
    final response = await _client.get('/v1/formations/$pathId/progress');

    if (response['data'] == null) {
      return null;
    }

    return FormationProgressResponse.fromJson(
      response['data'] as Map<String, dynamic>,
    );
  }

  /// Record that user opened a lesson
  Future<void> openLesson(String pathId, String lessonId) async {
    await _client.post(
      '/v1/formations/$pathId/lessons/$lessonId/open',
      body: {},
    );
  }

  /// Mark a lesson as completed
  Future<void> completeLesson(String pathId, String lessonId) async {
    await _client.post(
      '/v1/formations/$pathId/lessons/$lessonId/complete',
      body: {},
    );
  }
}
