import 'package:flutter/material.dart';

import '../constants.dart';
import '../main.dart';
import '../strings.dart';
import 'donor_list_screen.dart';

class NeedBloodScreen extends StatefulWidget {
  const NeedBloodScreen({super.key});

  @override
  State<NeedBloodScreen> createState() => _NeedBloodScreenState();
}

class _NeedBloodScreenState extends State<NeedBloodScreen> {
  String _city = AppConst.cities.first;
  String _group = AppConst.groups.first;

  void _search() {
    if (_city == 'NONE') {
      toast('Select City !');
      return;
    }
    if (_group == 'NONE') {
      toast('Select Blood Group !');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DonorListScreen(city: _city, group: _group),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(s('need_blood'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _city,
                decoration: InputDecoration(
                  labelText: s('select_city'),
                  prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF1E5BB8)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E5BB8), width: 1.8),
                  ),
                ),
                items: [
                  for (final city in AppConst.cities)
                    DropdownMenuItem(value: city, child: Text(city)),
                ],
                onChanged: (value) => setState(() => _city = value ?? _city),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _group,
                decoration: InputDecoration(
                  labelText: s('b_group'),
                  prefixIcon: const Icon(Icons.bloodtype_outlined, color: Color(0xFFD32F2F)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E5BB8), width: 1.8),
                  ),
                ),
                items: [
                  for (final group in AppConst.groups)
                    DropdownMenuItem(value: group, child: Text(group)),
                ],
                onChanged: (value) => setState(() => _group = value ?? _group),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E5BB8),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.search, size: 22),
                label: Text(
                  s('need_blood'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: _search,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
