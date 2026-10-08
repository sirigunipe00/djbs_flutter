import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../main.dart';
import '../strings.dart';
import 'login_screen.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _mobile = TextEditingController();
  String _city = AppConst.cities.first;
  String _group = AppConst.groups.first;

  @override
  void dispose() {
    _mobile.dispose();
    super.dispose();
  }

  Future<void> _requestDelete() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final body = 'Please Delete My Account\n\nFull Name : ${user.displayName ?? ''}'
        '\nCity : $_city\n Blood Group : $_group\nEmail : ${user.email ?? ''}\nMobile : ${_mobile.text}';
    final send = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Email'),
        content: const Text(
          'Press ok to continue sending email for Complete Delete your Account and data',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ok')),
        ],
      ),
    );
    if (send != true || !mounted) return;
    final mail = Uri.parse(
      'mailto:${AppConst.foundationEmail}?subject=${Uri.encodeComponent('Account Delete Request')}&body=${Uri.encodeComponent(body)}',
    );
    await launchUrl(mail);
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Your Account'),
        content: const Text('Are you sure you want to delete your account ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await user.delete();
      toast('Your account has been deleted Successfully.');
    } catch (_) {
      toast('Please login and try again!');
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: Text(s('Delete_User'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(user?.displayName ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(user?.email ?? ''),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _city,
            decoration: InputDecoration(labelText: s('select_city')),
            items: [
              for (final city in AppConst.cities)
                DropdownMenuItem(value: city, child: Text(city)),
            ],
            onChanged: (value) => setState(() => _city = value ?? _city),
          ),
          DropdownButtonFormField<String>(
            initialValue: _group,
            decoration: InputDecoration(labelText: s('b_group')),
            items: [
              for (final group in AppConst.groups)
                DropdownMenuItem(value: group, child: Text(group)),
            ],
            onChanged: (value) => setState(() => _group = value ?? _group),
          ),
          TextField(
            controller: _mobile,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: s('mobile_num')),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: _requestDelete,
            child: Text(s('delete_acc_btn')),
          ),
        ],
      ),
    );
  }
}
