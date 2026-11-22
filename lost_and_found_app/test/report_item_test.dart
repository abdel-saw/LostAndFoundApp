import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lost_and_found_app/services/supabase_service.dart';

void main() {
  late SupabaseClient client;
  late List<http.Request> requests;
  var failItem = false;
  var failReport = false;
  const userId = '11111111-1111-4111-8111-111111111111';
  final data = <String, dynamic>{
    'name': 'Keys', 'type': 'lost', 'user_id': userId,
    'timestamp': '2026-01-01T12:00:00Z',
  };

  setUp(() {
    requests = [];
    failItem = false;
    failReport = false;
    client = SupabaseClient('https://example.test', 'fixture-anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        if (request.url.path == '/auth/v1/token') {
          return http.Response(jsonEncode({
            'access_token': 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMTExMTExMS0xMTExLTQxMTEtODExMS0xMTExMTExMTExMTEiLCJleHAiOjQxMDI0NDQ4MDB9.c2lnbmF0dXJl', 'refresh_token': 'fixture-refresh',
            'token_type': 'bearer', 'expires_in': 3600,
            'user': {'id': userId, 'app_metadata': {}, 'user_metadata': {},
              'aud': 'authenticated', 'created_at': '2026-01-01T00:00:00Z'},
          }), 200, headers: {'content-type': 'application/json'});
        }
        requests.add(request);
        if (request.url.path == '/rest/v1/items') {
          return http.Response(jsonEncode(failItem
            ? {'message': 'item denied', 'code': '42501'}
            : {'id': 42, ...data}), failItem ? 403 : 201,
            headers: {'content-type': 'application/json'});
        }
        if (request.url.path == '/rest/v1/user_reports') {
          return http.Response(failReport
            ? '{"message":"report denied","code":"42501"}' : '',
            failReport ? 403 : 201, headers: {'content-type': 'application/json'});
        }
        throw StateError('Unexpected fixture request: ${request.url}');
      }));
  });
  tearDown(() async => client.dispose());

  Future<void> signIn() => client.auth.signInWithPassword(
      email: 'fixture@example.test', password: 'fixture-password').then((_) {});

  test('one submission creates one item and exactly one linked report', () async {
    await signIn();
    await ItemReportRepository(client).reportItem(data);
    expect(requests.map((r) => r.url.path),
      ['/rest/v1/items', '/rest/v1/user_reports']);
    expect(requests.every((r) => r.method == 'POST'), isTrue);
    expect(jsonDecode(requests.last.body), {
      'user_id': userId, 'item_id': 42, 'type': 'lost',
      'timestamp': data['timestamp'],
    });
  });

  test('signed-out submission makes no writes', () async {
    await expectLater(ItemReportRepository(client).reportItem(data), throwsException);
    expect(requests, isEmpty);
  });

  test('failed item creation does not write a report', () async {
    await signIn();
    failItem = true;
    await expectLater(ItemReportRepository(client).reportItem(data), throwsException);
    expect(requests.map((r) => r.url.path), ['/rest/v1/items']);
  });

  test('report creation failure is propagated without retrying writes', () async {
    await signIn();
    failReport = true;
    await expectLater(ItemReportRepository(client).reportItem(data), throwsException);
    expect(requests.length, 2);
  });
}
