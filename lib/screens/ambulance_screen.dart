import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../main.dart';
import '../strings.dart';
import '../theme.dart';

class AmbulanceScreen extends StatefulWidget {
  const AmbulanceScreen({super.key});

  @override
  State<AmbulanceScreen> createState() => _AmbulanceScreenState();
}

class _AmbulanceScreenState extends State<AmbulanceScreen> {
  String _city = AppConst.cities.first;

  Future<void> _call() async {
    if (_city != 'Amreli') {
      toast('Sorry,Currently Our service is Unavailable for selected city');
      return;
    }
    await launchUrl(Uri.parse('tel:${AppConst.servicePhone}'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(s('ambulance'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Image.asset('assets/images/ambulance_128.png', height: 96),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _city,
              decoration: InputDecoration(labelText: s('select_city')),
              items: [
                for (final city in AppConst.cities)
                  DropdownMenuItem(value: city, child: Text(city)),
              ],
              onChanged: (value) => setState(() => _city = value ?? _city),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.callGreen),
              onPressed: _call,
              child: Text(s('call')),
            ),
          ],
        ),
      ),
    );
  }
}
