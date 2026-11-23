import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';

class SupabaseService {
  static SupabaseClient get _client => Supabase.instance.client;

  static Future<void> signUp(String email, String password) async {
    await _client.auth.signUp(email: email, password: password);
  }

  static Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  
static Future<String?> uploadImage(Uint8List bytes, {String contentType = 'image/jpeg'}) async {
  final user = _client.auth.currentUser;
  if (user == null) throw Exception('User not authenticated');
  final extension = contentType == 'image/png' ? 'png' : contentType == 'image/webp' ? 'webp' : 'jpg';
  final fileName = '${user.id}/${DateTime.now().microsecondsSinceEpoch}.$extension';
  try {
    
    final response = await _client.storage.from('items').uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(cacheControl: '3600', contentType: contentType),
        );
    
    if (response.isNotEmpty) {
      final publicUrl = _client.storage.from('items').getPublicUrl(fileName);
      
      return publicUrl;
    }
    throw Exception('Upload response was empty');
  } catch (e) {
   
    throw Exception('Failed to upload image: $e');
  }
}


  static Future<void> reportItem(Map<String, dynamic> data) =>
      ItemReportRepository(_client).reportItem(data);

  static Future<void> addComment(int itemId, String text) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    try {
      await _client.from('comments').insert({
        'item_id': itemId, 
        'user_id': user.id,
        'text': text,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  static Stream<List<Map<String, dynamic>>> getItemsStream(String filterType, String searchTerm) {
    return _client
        .from('items')
        .stream(primaryKey: ['id'])
        .order('timestamp', ascending: false)
        .limit(20)
        .map((data) => data.where((item) {
              final type = item['type']?.toString() ?? '';
              final name = item['name']?.toString() ?? '';
              final matchesType = filterType == 'all' || type == filterType;
              final matchesSearch = searchTerm.isEmpty || name.toLowerCase().contains(searchTerm.toLowerCase());
              return matchesType && matchesSearch;
            }).toList());
  }

  static Stream<List<Map<String, dynamic>>> getCommentsStream(int itemId) {
    return _client
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('item_id', itemId)
        .order('timestamp', ascending: false);
  }

  static Future<void> cacheItems(List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_items', jsonEncode(items));
  }

  static Future<List<Map<String, dynamic>>> loadCachedItems() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_items');
    if (cached == null) return [];
    try {
      final decoded = jsonDecode(cached);
      if (decoded is! List || decoded.any((item) => item is! Map<String, dynamic>)) {
        throw const FormatException('Invalid item cache');
      }
      return decoded.cast<Map<String, dynamic>>();
    } on FormatException {
      // Discard old Map.toString() caches and corrupt payloads.
      await prefs.remove('cached_items');
      return [];
    }
  }

  static Future<bool> isUserAuthenticated() async {
    return _client.auth.currentSession != null;
  }

  static Future<String?> getCurrentUserId() async {
    final user = _client.auth.currentUser;
    return user?.id;
  }
}

/// Creates the item and linked report in one database transaction.
class ItemReportRepository {
  final SupabaseClient _client;
  ItemReportRepository(this._client);

  Future<void> reportItem(Map<String, dynamic> data) async {
    if (_client.auth.currentUser == null) {
      throw Exception('User not authenticated');
    }
    try {
      // Ownership and timestamp are supplied by the database, not the caller.
      await _client.rpc('report_item', params: {
        'payload': {
          for (final key in [
            'type', 'name', 'description', 'category', 'location', 'photo_url',
          ])
            if (data.containsKey(key)) key: data[key],
        },
      });
    } catch (e) {
      throw Exception('Failed to report item: $e');
    }
  }
}
