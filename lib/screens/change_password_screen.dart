import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../strings.dart';
import 'login_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPass = TextEditingController();
  final _newPass = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _oldPass.dispose();
    _newPass.dispose();
    super.dispose();
  }

  Future<void> _change() async {
    final oldPass = _oldPass.text;
    final newPass = _newPass.text;
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null) return;
    if (oldPass.isEmpty) {
      toast('Enter old password');
      return;
    }
    if (newPass.isEmpty) {
      toast('Enter new password');
      return;
    }
    setState(() => _busy = true);
    try {
      final credential = EmailAuthProvider.credential(email: email, password: oldPass);
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPass);
      toast('Password Updated, Login with your new password');
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        toast('Wrong old Password');
      } else {
        toast('Please try again !');
      }
      _oldPass.clear();
      _newPass.clear();
    } catch (_) {
      toast('Please try again !');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(s('change_password'))),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _oldPass,
              obscureText: true,
              enabled: !_busy,
              decoration: const InputDecoration(labelText: 'Old Password'),
            ),
            TextField(
              controller: _newPass,
              obscureText: true,
              enabled: !_busy,
              decoration: const InputDecoration(labelText: 'New Password'),
            ),
            const SizedBox(height: 24),
            _busy
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _change, child: Text(s('change_password'))),
          ],
        ),
      ),
    );
  }
}
