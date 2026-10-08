import 'package:flutter/material.dart';

import '../constants.dart';
import '../main.dart';
import '../strings.dart';

class BankScreen extends StatefulWidget {
  const BankScreen({super.key});

  @override
  State<BankScreen> createState() => _BankScreenState();
}

class _BankScreenState extends State<BankScreen> {
  String _city = AppConst.cities.first;
  String? _address;

  void _find() {
    if (_city == 'NONE') {
      toast('Select City !');
      return;
    }
    final key = AppConst.bankKeys[_city];
    if (key == null) {
      setState(() => _address = null);
      toast('Searching for Data... !');
      toast('No Data Found !');
      return;
    }
    setState(() => _address = s(key));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(s('find_blood_bank'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            ElevatedButton(onPressed: _find, child: Text(s('address_btn'))),
            const SizedBox(height: 16),
            if (_address != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Text(_address!, style: const TextStyle(fontSize: 16, height: 1.4)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
