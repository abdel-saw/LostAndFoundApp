import 'package:flutter_test/flutter_test.dart';
import 'package:lost_and_found_app/config/supabase_config.dart';

void main() {
  test('missing configuration fails with an actionable message', () {
    expect(() => const SupabaseConfig(url: '', anonKey: '').validate(),
        throwsA(isA<StateError>()));
  });
  test('non-HTTP URLs are rejected', () {
    expect(() => const SupabaseConfig(url: 'file:///tmp/db', anonKey: 'fixture').validate(),
        throwsA(isA<StateError>()));
  });
  test('explicit local and hosted URLs are accepted', () {
    const SupabaseConfig(url: 'http://localhost:54321', anonKey: 'fixture').validate();
    const SupabaseConfig(url: 'https://example.supabase.co', anonKey: 'fixture').validate();
  });
}
