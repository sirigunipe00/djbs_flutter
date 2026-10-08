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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _city,
              decoration: InputDecoration(labelText: s('select_city')),
              items: [
                for (final city in AppConst.cities)
                  DropdownMenuItem(value: city, child: Text(city)),
              ],
              onChanged: (value) => setState(() => _city = value ?? _city),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _group,
              decoration: InputDecoration(labelText: s('b_group')),
              items: [
                for (final group in AppConst.groups)
                  DropdownMenuItem(value: group, child: Text(group)),
              ],
              onChanged: (value) => setState(() => _group = value ?? _group),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _search, child: Text(s('need_blood'))),
          ],
        ),
      ),
    );
  }
}
