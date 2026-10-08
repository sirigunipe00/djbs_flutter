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

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    if (_user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goLogin());
      return;
    }
    _loadPhoto();
  }

  Future<void> _loadPhoto() async {
    final url = await ProfileStore.imageUrl(_user?.displayName);
    if (mounted) setState(() => _photoUrl = url);
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
    final user = _user;
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
          const SizedBox(height: 16),
          Text(user?.displayName ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(user?.email ?? '', textAlign: TextAlign.center),
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
