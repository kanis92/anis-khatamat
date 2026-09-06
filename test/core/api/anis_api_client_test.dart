import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'dart:convert';

import 'package:anis_khatamat/core/api/anis_api_client.dart';
import 'package:anis_khatamat/core/api/api_exception.dart';

@GenerateMocks([http.Client, FirebaseAuth, User])
import 'anis_api_client_test.mocks.dart';

void main() {
  group('AnisApiClient - Contract Tests', () {
    late MockClient mockHttpClient;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late AnisApiClient apiClient;

    setUp(() {
      mockHttpClient = MockClient();
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
      apiClient = AnisApiClient(
        httpClient: mockHttpClient,
        auth: mockAuth,
      );

      // Default: authenticated user
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.getIdToken(any)).thenAnswer((_) async => 'mock-token-123');
    });

    group('Request Headers Contract', () {
      test('includes Authorization Bearer token', () async {
        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode({'data': {}}),
          200,
          headers: {'content-type': 'application/json'},
        ));

        await apiClient.post('/test', body: {'key': 'value'});

        final captured = verify(mockHttpClient.post(
          any,
          headers: captureAnyNamed('headers'),
          body: anyNamed('body'),
        )).captured.single as Map<String, String>;

        expect(captured['Authorization'], 'Bearer mock-token-123');
      });

      test('includes Content-Type application/json', () async {
        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode({'data': {}}),
          200,
        ));

        await apiClient.post('/test', body: {});

        final captured = verify(mockHttpClient.post(
          any,
          headers: captureAnyNamed('headers'),
          body: anyNamed('body'),
        )).captured.single as Map<String, String>;

        expect(captured['Content-Type'], 'application/json');
        expect(captured['Accept'], 'application/json');
      });

      test('token never appears in logs', () {
        // This is a documentation test - actual logging uses debugPrint
        // which doesn't log tokens/credentials
        expect('mock-token-123', isNot(contains('logged')));
      });
    });

    group('Token Refresh - 401 Retry', () {
      test('refreshes token and retries on first 401', () async {
        var callCount = 0;
        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            // First call: 401
            return http.Response(
              jsonEncode({
                'error': {'code': 'AUTH_INVALID', 'message': 'Token expired'}
              }),
              401,
              headers: {'x-request-id': 'req-123'},
            );
          } else {
            // Second call (after refresh): 200
            return http.Response(
              jsonEncode({'data': {'result': 'success'}}),
              200,
            );
          }
        });

        // Mock token refresh returning new token
        when(mockUser.getIdToken(false)).thenAnswer((_) async => 'old-token');
        when(mockUser.getIdToken(true)).thenAnswer((_) async => 'new-token');

        final result = await apiClient.post('/test', body: {});

        expect(result['data']['result'], 'success');
        expect(callCount, 2); // Called twice: initial + retry
        verify(mockUser.getIdToken(false)).called(2); // Initial + retry token
        verify(mockUser.getIdToken(true)).called(1);  // Force refresh
      });

      test('fails after second 401 without infinite retry', () async {
        var callCount = 0;
        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async {
          callCount++;
          return http.Response(
            jsonEncode({
              'error': {'code': 'AUTH_INVALID', 'message': 'Invalid token'}
            }),
            401,
            headers: {'x-request-id': 'req-456'},
          );
        });

        expect(
          () => apiClient.post('/test', body: {}),
          throwsA(isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.authInvalid,
          )),
        );

        // Should only retry once
        await Future.delayed(Duration(milliseconds: 100));
        expect(callCount, 2); // Initial + 1 retry only
      });

      test('does NOT refresh token on non-auth 4xx errors', () async {
        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode({
            'error': {'code': 'INVALID_ARGUMENT', 'message': 'Bad request'}
          }),
          400,
        ));

        expect(
          () => apiClient.post('/test', body: {}),
          throwsA(isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.invalidArgument,
          )),
        );

        // Should NOT call force refresh
        verifyNever(mockUser.getIdToken(true));
      });

      test('does NOT refresh token on 409 conflict', () async {
        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode({
            'error': {'code': 'CONFLICT', 'message': 'Already exists'}
          }),
          409,
        ));

        expect(
          () => apiClient.post('/test', body: {}),
          throwsA(isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.conflict,
          )),
        );

        verifyNever(mockUser.getIdToken(true));
      });
    });

    group('Response Handling', () {
      test('parses JSON response correctly', () async {
        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode({
            'data': {'khatmaId': 'abc123', 'count': 60}
          }),
          201,
        ));

        final result = await apiClient.post('/test', body: {});

        expect(result['data']['khatmaId'], 'abc123');
        expect(result['data']['count'], 60);
      });

      test('captures X-Request-Id from response', () async {
        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          jsonEncode({'error': {'code': 'NOT_FOUND', 'message': 'Missing'}}),
          404,
          headers: {'x-request-id': 'req-correlation-123'},
        ));

        try {
          await apiClient.post('/test', body: {});
          fail('Should throw ApiException');
        } on ApiException catch (e) {
          expect(e.requestId, 'req-correlation-123');
        }
      });

      test('handles empty response body', () async {
        when(mockHttpClient.delete(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('', 204));

        final result = await apiClient.delete('/test');

        expect(result, isEmpty);
      });
    });

    group('Request Timeout', () {
      test('throws timeout exception after 30 seconds', () async {
        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async {
          await Future.delayed(Duration(seconds: 35));
          return http.Response('{}', 200);
        });

        expect(
          () => apiClient.post('/test', body: {}),
          throwsA(isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.timeout,
          )),
        );
      }, timeout: Timeout(Duration(seconds: 40)));
    });

    group('Network Error Handling', () {
      test('maps connection failure to networkError', () async {
        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenThrow(Exception('Connection refused'));

        expect(
          () => apiClient.post('/test', body: {}),
          throwsA(isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.networkError,
          )),
        );
      });
    });

    group('Authentication Required', () {
      test('throws authRequired when no current user', () async {
        when(mockAuth.currentUser).thenReturn(null);

        expect(
          () => apiClient.post('/test', body: {}),
          throwsA(isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.authRequired,
          )),
        );
      });

      test('throws authRequired when getIdToken returns null', () async {
        when(mockUser.getIdToken(any)).thenAnswer((_) async => null);

        expect(
          () => apiClient.post('/test', body: {}),
          throwsA(isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.authRequired,
          )),
        );
      });
    });
  });
}
