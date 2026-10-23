import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../main.dart';
import '../services/app_services.dart';
import '../strings.dart';
import 'change_password_screen.dart';
import 'delete_account_screen.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _photoUrl;
  bool _busy = false;
  String _userName = '';
  String _userMobile = '';

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    if (_user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goLogin());
      return;
    }
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _user;
    if (user == null) return;
    final url = await ProfileStore.imageUrl(user.displayName);
    if (mounted) setState(() => _photoUrl = url);

    final phone = AuthService.extract10DigitPhone(user.email ?? user.phoneNumber ?? '');
    String name = user.displayName ?? '';
    if ((name.isEmpty || name == 'No Name') && phone.isNotEmpty) {
      final fetched = await AuthService.findUserName(phone);
      if (fetched != null && fetched.isNotEmpty) {
        name = fetched;
        try { await user.updateDisplayName(fetched); } catch (_) {}
      }
    }
    if (mounted) {
      setState(() {
        _userName = name;
        _userMobile = phone;
      });
    }
  }

  Future<void> _pick() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    final user = _user;
    if (picked == null || user == null) return;
    setState(() => _busy = true);
    try {
      final url = await ProfileStore.upload(user, File(picked.path));
      if (mounted) setState(() => _photoUrl = url);
      toast('Upload successful');
    } catch (e) {
      toast(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _goLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(s('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pick,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundImage: _photoUrl == null
                        ? const AssetImage('assets/images/user_ic.png') as ImageProvider
                        : CachedNetworkImageProvider(_photoUrl!),
                  ),
                  if (_busy) const CircularProgressIndicator(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (_userName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${s('fullName')}: ',
                    style: const TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    _userName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          if (_userMobile.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${s('mobile_num')}: ',
                    style: const TextStyle(fontSize: 15, color: Colors.black54),
                  ),
                  Text(
                    '+91 $_userMobile',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              );
            },
            child: Text(s('change_password')),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              _goLogin();
            },
            child: Text(s('logout_1')),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DeleteAccountScreen()),
              );
            },
            child: Text(s('delete_acc_btn')),
          ),
        ],
      ),
    );
  }
}
