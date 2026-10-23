import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../services/app_services.dart';
import '../strings.dart';
import 'login_screen.dart';

class ForgotScreen extends StatefulWidget {
  const ForgotScreen({super.key});

  @override
  State<ForgotScreen> createState() => _ForgotScreenState();
}

class _ForgotScreenState extends State<ForgotScreen> {
  final _mobile = TextEditingController();
  final _newPass = TextEditingController();
  final _confirmPass = TextEditingController();

  bool _hideNewPass = true;
  bool _hideConfirmPass = true;
  bool _busy = false;

  @override
  void dispose() {
    _mobile.dispose();
    _newPass.dispose();
    _confirmPass.dispose();
    super.dispose();
  }

  Future<void> _handleUpdatePassword() async {
    final rawPhone = _mobile.text.trim();
    final cleanPhone = AuthService.normalizePhone(rawPhone);
    final newPass = _newPass.text;
    final confirmPass = _confirmPass.text;

    if (cleanPhone.length < 10) {
      toast('Enter valid 10-digit Mobile Number!');
      return;
    }
    if (newPass.isEmpty) {
      toast('Enter new password');
      return;
    }
    if (newPass.length < 6) {
      toast('Password must be at least 6 characters');
      return;
    }
    if (newPass != confirmPass) {
      toast('Passwords do not match');
      return;
    }

    if (!await Net.online()) {
      toast('Internet connection may not available');
      return;
    }

    setState(() => _busy = true);

    try {
      // 1. Check if user exists in the database
      final resolved = await AuthService.findEmailByPhone(cleanPhone);
      final stored = await AuthService.getStoredPassword(cleanPhone);

      if (resolved == null && stored == null) {
        toast('No account found for this Mobile Number.');
        return;
      }

      // 2. Directly update password for that mobile number
      await AuthService.updatePasswordDirectly(
        mobile: cleanPhone,
        newPassword: newPass,
      );

      toast('Password updated successfully! Please login.');

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
      appBar: AppBar(
        title: Text(s('forgetpass').replaceAll(RegExp(r'<[^>]+>'), '')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Image.asset('assets/images/djbs_logos.png', height: 110),
              ),
              const SizedBox(height: 20),
              Text(
                s('forgetpassword'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _mobile,
                keyboardType: TextInputType.phone,
                enabled: !_busy,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: InputDecoration(
                  labelText: s('mobile_num'),
                  prefixText: '+91 ',
                  prefixIcon: const Icon(Icons.phone_android),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPass,
                obscureText: _hideNewPass,
                enabled: !_busy,
                decoration: InputDecoration(
                  labelText: s('new_password'),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_hideNewPass ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _hideNewPass = !_hideNewPass),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPass,
                obscureText: _hideConfirmPass,
                enabled: !_busy,
                decoration: InputDecoration(
                  labelText: s('confirm_password'),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_hideConfirmPass ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _hideConfirmPass = !_hideConfirmPass),
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
                      onPressed: _handleUpdatePassword,
                      child: Text(s('update_password'), style: const TextStyle(fontSize: 16)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
