
// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:lost_and_found_app/services/supabase_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSignUp = false;

  Future<void> _authenticate() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter email and password')));
      return;
    }

    try {
      if (_isSignUp) {
        await SupabaseService.signUp(email, password);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign-up successful! Please sign in.')));
        setState(() => _isSignUp = false);
      } else {
        await SupabaseService.signIn(email, password);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Signed in successfully')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE6E6FA), 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            
            Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  Text(
                    'LostAndFound',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFAEC6CF), 
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Share what you find, Recover what you lost',
                    style: TextStyle(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF808080), 
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            Container(
              constraints: BoxConstraints(maxWidth: 400),
              padding: EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                color: Color(0xFFFFF5F5), 
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_isSignUp ? 'Sign Up' : 'Sign In', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      SizedBox(height: 20),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                        obscureText: true,
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _authenticate,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                          backgroundColor: Color(0xFFC1E1C1), 
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(_isSignUp ? 'Sign Up' : 'Sign In', style: TextStyle(fontSize: 16)),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _isSignUp = !_isSignUp),
                        child: Text(_isSignUp ? 'Already have an account? Sign In' : 'Don\'t have an account? Sign Up'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}