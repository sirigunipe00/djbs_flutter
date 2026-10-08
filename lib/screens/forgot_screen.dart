import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../main.dart';
import '../strings.dart';
import 'login_screen.dart';

class ForgotScreen extends StatefulWidget {
  const ForgotScreen({super.key});

  @override
  State<ForgotScreen> createState() => _ForgotScreenState();
}

class _ForgotScreenState extends State<ForgotScreen> {
  final _email = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      toast('Enter Email Address !');
      return;
    }
    if (!AppConst.emailPattern.hasMatch(email)) {
      toast('Enter Valid Email Address!');
      _email.clear();
      return;
    }
    setState(() => _busy = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      toast('We have sent you instructions to reset your password!');
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (_) {
      toast('Something went wrong.Please check Email is Registred!');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(s('forgetpass').replaceAll(RegExp(r'<[^>]+>'), ''))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Image.asset('assets/images/djbs_logos.png', height: 120),
            const SizedBox(height: 16),
            Text(s('forgetpassword'), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              enabled: !_busy,
              decoration: InputDecoration(labelText: s('Email')),
            ),
            const SizedBox(height: 24),
            _busy
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _reset,
                    child: Text(s('btn_reset')),
                  ),
          ],
        ),
      ),
    );
  }
}
