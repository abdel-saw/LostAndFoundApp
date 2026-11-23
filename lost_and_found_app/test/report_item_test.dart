import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lost_and_found_app/services/supabase_service.dart';

void main() {
  late SupabaseClient client;
  late List<http.Request> requests;
  var failReport = false;
  const userId = '11111111-1111-4111-8111-111111111111';
  final data = <String, dynamic>{
    'name': 'Keys', 'type': 'lost', 'user_id': userId,
    'timestamp': '2026-01-01T12:00:00Z',
  };

  setUp(() {
    requests = [];
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
          }), 200, request: request, headers: {'content-type': 'application/json'});
        }
        requests.add(request);
        if (request.url.path == '/rest/v1/rpc/report_item') {
          return http.Response(failReport
            ? '{"message":"report denied","code":"42501"}' : '42',
            failReport ? 403 : 200, request: request,
            headers: {'content-type': 'application/json'});
        }
        throw StateError('Unexpected fixture request: ${request.url}');
      }));
  });
  tearDown(() async => client.dispose());

  Future<void> signIn() => client.auth.signInWithPassword(
      email: 'fixture@example.test', password: 'fixture-password').then((_) {});

  test('one submission makes one atomic RPC without client identity or time', () async {
    await signIn();
    await ItemReportRepository(client).reportItem(data);
    expect(requests.map((r) => r.url.path), ['/rest/v1/rpc/report_item']);
    expect(requests.single.method, 'POST');
    expect(jsonDecode(requests.single.body), {
      'payload': {'name': 'Keys', 'type': 'lost'},
    });
  });

  test('signed-out submission makes no writes', () async {
    await expectLater(ItemReportRepository(client).reportItem(data), throwsException);
    expect(requests, isEmpty);
  });

  test('RPC failure is propagated without falling back to separate writes', () async {
    await signIn();
    failReport = true;
    await expectLater(ItemReportRepository(client).reportItem(data), throwsException);
    expect(requests.map((r) => r.url.path), ['/rest/v1/rpc/report_item']);
  });
}
