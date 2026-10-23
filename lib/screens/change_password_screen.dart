import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../services/app_services.dart';
import '../strings.dart';
import 'login_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _newPass = TextEditingController();
  final _confirmPass = TextEditingController();

  bool _hideNew = true;
  bool _hideConfirm = true;
  bool _busy = false;

  @override
  void dispose() {
    _newPass.dispose();
    _confirmPass.dispose();
    super.dispose();
  }

  Future<void> _change() async {
    final newPass = _newPass.text;
    final confirmPass = _confirmPass.text;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      toast('Please login to continue');
      return;
    }

    if (newPass.isEmpty) {
      toast('Enter new password');
      return;
    }
    if (newPass.length < 6) {
      toast('New password must be at least 6 characters');
      return;
    }
    if (newPass != confirmPass) {
      toast('New passwords do not match');
      return;
    }

    setState(() => _busy = true);
    try {
      // 1. Get clean 10-digit mobile number
      final mobile = AuthService.extract10DigitPhone(user.phoneNumber ?? user.email ?? '');

      // 2. Directly update password in Realtime Database under users_by_phone and users
      if (mobile.isNotEmpty) {
        await AuthService.updatePasswordDirectly(
          mobile: mobile,
          newPassword: newPass,
        );
      }

      // 3. Update password in Firebase Auth
      try {
        await user.updatePassword(newPass);
      } catch (authError) {
        debugPrint('[ChangePassword] Auth update warning: $authError');
      }

      toast('Password Updated Successfully! Please login with your new password.');
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (e) {
      toast('Failed to update password: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(s('change_password'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Enter your new password below to update your account.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _newPass,
                obscureText: _hideNew,
                enabled: !_busy,
                decoration: InputDecoration(
                  labelText: s('new_password'),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_hideNew ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _hideNew = !_hideNew),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPass,
                obscureText: _hideConfirm,
                enabled: !_busy,
                decoration: InputDecoration(
                  labelText: s('confirm_password'),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_hideConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _hideConfirm = !_hideConfirm),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              _busy
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _change,
                      child: Text(s('change_password'), style: const TextStyle(fontSize: 16)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
