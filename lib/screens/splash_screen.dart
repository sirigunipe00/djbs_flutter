import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'terms_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.startAtLogin});

  final bool startAtLogin;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => widget.startAtLogin ? const LoginScreen() : const TermsScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/djbs_logos.png',
          width: 140,
          height: 140,
        ),
      ),
    );
  }
}
