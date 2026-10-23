import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../main.dart';
import '../models/donor.dart';
import '../services/app_services.dart';
import '../strings.dart';
import '../utils/word_capitalization.dart';

class DonorFormScreen extends StatefulWidget {
  const DonorFormScreen({super.key});

  @override
  State<DonorFormScreen> createState() => _DonorFormScreenState();
}

class _DonorFormScreenState extends State<DonorFormScreen> {
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  String _city = AppConst.cities.first;
  String _group = AppConst.groups.first;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final mobile = _mobile.text.trim();
    if (name.isEmpty) {
      toast("Name can't be empty!");
      return;
    }
    if (name.length < 8) {
      toast('Enter Full Name!');
      return;
    }
    if (_city == 'NONE') {
      toast('Select City!');
      return;
    }
    if (_group == 'NONE') {
      toast('Select Blood Group!');
      return;
    }
    if (mobile.isEmpty) {
      toast('Enter Mobile Number!');
      return;
    }
    if (mobile.length < 10) {
      toast('Enter Valid Mobile Number!');
      return;
    }

    setState(() => _busy = true);
    try {
      await AppLocation.refresh();
      final donor = Donor(
        name: name,
        mobileNumber: mobile,
        bloodGroup: _group,
        city: _city,
        lat: AppLocation.lat.toString(),
        lan: AppLocation.lng.toString(),
      );
      await FirebaseDatabase.instance
          .ref('donors')
          .child(_city)
          .child(_group)
          .push()
          .set(donor.toMap());
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      toast(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(s('add_user'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            inputFormatters: const [WordCapitalizationFormatter()],
            decoration: InputDecoration(labelText: s('fullName')),
          ),
          TextField(
            controller: _mobile,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: s('mobile_num')),
          ),
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
          const SizedBox(height: 20),
          _busy
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
    );
  }
}
