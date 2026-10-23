import 'package:djbs_foundation/theme.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';
import '../main.dart';
import '../strings.dart';


class AmbulanceScreen extends StatefulWidget {
  const AmbulanceScreen({super.key});

  @override
  State<AmbulanceScreen> createState() => _AmbulanceScreenState();
}

class _AmbulanceScreenState extends State<AmbulanceScreen> {
  String _city = AppConst.cities.first;

  Future<void> _call() async {
    if (_city == 'NONE') {
      toast(s('select_city'));
      return;
    }
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/images/ambulance_128.png',
                    height: 80,
                    width: 80,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
              const SizedBox(height: 120),
              // Call button placed right below the selector (moved upward)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.callGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.phone_in_talk, size: 22),
                label: Text(
                  s('call'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: _call,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
