import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class AuthWrapper extends StatefulWidget {
  final Widget? child;
  const AuthWrapper({super.key, this.child});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final Stream<AuthState> _authChanges;

  @override
  void initState() {
    super.initState();
    _authChanges = Supabase.instance.client.auth.onAuthStateChange;
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<AuthState>(
    stream: _authChanges,
    builder: (context, snapshot) {
      if (Supabase.instance.client.auth.currentSession == null) {
        return LoginScreen();
      }
      return widget.child ?? const HomeScreen();
    },
  );
}
