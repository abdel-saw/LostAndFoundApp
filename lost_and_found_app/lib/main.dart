// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_wrapper.dart';
import 'config/supabase_config.dart';

import 'screens/report_item_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = SupabaseConfig.fromEnvironment();
  config.validate();
  await Supabase.initialize(url: config.url, anonKey: config.anonKey);
  runApp(MaterialApp(
    title: 'LostAndFound',
    initialRoute: '/',
    routes: {
      '/': (context) => AuthWrapper(),
      '/report': (context) => ReportItemScreen(),
    },
  ));
}

