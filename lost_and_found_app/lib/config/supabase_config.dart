class SupabaseConfig {
  final String url;
  final String anonKey;
  const SupabaseConfig({required this.url, required this.anonKey});

  factory SupabaseConfig.fromEnvironment() => const SupabaseConfig(
        url: String.fromEnvironment('SUPABASE_URL'),
        anonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
      );

  void validate() {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasAuthority ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        anonKey.trim().isEmpty) {
      throw StateError(
        'Pass SUPABASE_URL and SUPABASE_ANON_KEY using --dart-define.',
      );
    }
  }
}
