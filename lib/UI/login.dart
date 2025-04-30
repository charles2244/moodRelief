import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../logic/controller/user_controller.dart'; // ✅ Import for random number generation

class FingerprintLoginScreen extends StatefulWidget {
  @override
  _FingerprintLoginScreenState createState() => _FingerprintLoginScreenState();
}

class _FingerprintLoginScreenState extends State<FingerprintLoginScreen> {
  final LocalAuthentication localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    try {
      bool didAuthenticate = await localAuth.authenticate(
        localizedReason: 'Please scan your fingerprint to continue',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );

      if (didAuthenticate) {
        final prefs = await SharedPreferences.getInstance();
        int? userId = prefs.getInt('user_id');

        if (userId == null) {
          userId = 100000 + Random().nextInt(900000); // ✅ Generate random 6-digit user ID
          await prefs.setInt('user_id', userId);
          await UserController().saveAUserData(userId);
          print('New user ID generated: $userId');
        } else {
          print('Existing user ID: $userId');
        }

        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      print('Authentication error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF7EF),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
