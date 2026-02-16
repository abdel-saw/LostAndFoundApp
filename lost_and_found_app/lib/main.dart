// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_wrapper.dart';

import 'screens/report_item_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://swzwhgldjzrebvkytrbe.supabase.co', // Replace with your Supabase URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN3endoZ2xkanpyZWJ2a3l0cmJlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg2NTI3NTIsImV4cCI6MjA2NDIyODc1Mn0.tcxAPdq0SP7SBsowo_eEHjsEEfG-2e_SKIzFoBeE0l0', 
  );
  runApp(MaterialApp(
    title: 'LostAndFound',
    initialRoute: '/',
    routes: {
      '/': (context) => AuthWrapper(),
      '/report': (context) => ReportItemScreen(),
    },
  ));
}

