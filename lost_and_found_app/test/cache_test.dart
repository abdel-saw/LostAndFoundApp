import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lost_and_found_app/services/supabase_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('cache round-trips Unicode, quotes, nulls and nested fields as JSON', () async {
    final items = <Map<String, dynamic>>[
      {'id': 7, 'name': 'Clé "bleue"', 'description': "L'objet\nperdu",
       'photo_url': null, 'extra': {'found': true}},
    ];
    await SupabaseService.cacheItems(items);
    final prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString('cached_items')!), items);
    expect(await SupabaseService.loadCachedItems(), items);
  });

  test('missing cache returns an empty list', () async {
    expect(await SupabaseService.loadCachedItems(), isEmpty);
  });

  for (final corrupt in ['[{id: 1}]', '{}', '[1]', 'null']) {
    test('invalid cache is discarded: $corrupt', () async {
      SharedPreferences.setMockInitialValues({'cached_items': corrupt});
      expect(await SupabaseService.loadCachedItems(), isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('cached_items'), isFalse);
    });
  }
}
