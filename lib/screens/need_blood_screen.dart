import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../main.dart';
import '../models/donor.dart';
import '../services/app_services.dart';
import '../strings.dart';
import '../utils/word_capitalization.dart';
import 'donor_list_screen.dart';

class NeedBloodScreen extends StatefulWidget {
  const NeedBloodScreen({super.key});

  @override
  State<NeedBloodScreen> createState() => _NeedBloodScreenState();
}

class _NeedBloodScreenState extends State<NeedBloodScreen> {
  String _city = AppConst.cities.first;
  String _group = AppConst.groups.first;

  bool get _isAdmin {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && user.uid == AppConst.adminUid;
  }

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

  void _showAddDonorDialog({String? initialCity, String? initialGroup}) {
    final availableCities = AppConst.cities.where((c) => c != 'NONE').toList();
    final availableGroups = AppConst.groups.where((g) => g != 'NONE').toList();

    String dialogCity = initialCity ?? (availableCities.contains(_city) ? _city : availableCities.first);
    String dialogGroup = initialGroup ?? (availableGroups.contains(_group) ? _group : availableGroups.first);

    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.bloodtype_rounded,
                            color: Color(0xFFDC2626),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Add Blood Donor',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // City Dropdown
                    DropdownButtonFormField<String>(
                      value: dialogCity,
                      decoration: const InputDecoration(
                        labelText: 'City / District',
                        prefixIcon: Icon(Icons.location_city_rounded, color: Color(0xFF1E5BB8)),
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final c in availableCities)
                          DropdownMenuItem(value: c, child: Text(c)),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => dialogCity = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Blood Group Dropdown
                    DropdownButtonFormField<String>(
                      value: dialogGroup,
                      decoration: const InputDecoration(
                        labelText: 'Blood Group',
                        prefixIcon: Icon(Icons.bloodtype_outlined, color: Color(0xFFD32F2F)),
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final g in availableGroups)
                          DropdownMenuItem(value: g, child: Text(g)),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => dialogGroup = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Full Name
                    TextField(
                      controller: nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: const [WordCapitalizationFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'Donor Full Name',
                        hintText: 'e.g. Ramesh Patel',
                        prefixIcon: Icon(Icons.person_outline_rounded, color: Color(0xFF1E5BB8)),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Mobile Number
                    TextField(
                      controller: mobileCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number',
                        hintText: 'e.g. 9876543210',
                        prefixIcon: Icon(Icons.phone_rounded, color: Color(0xFF1E5BB8)),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E5BB8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: saving
                          ? null
                          : () async {
                              final name = nameCtrl.text.trim();
                              final mobile = mobileCtrl.text.trim();

                              if (name.isEmpty) {
                                toast("Name can't be empty!");
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

                              setModalState(() => saving = true);

                              try {
                                await AppLocation.refresh();
                                final donor = Donor(
                                  name: name,
                                  mobileNumber: mobile,
                                  bloodGroup: dialogGroup,
                                  city: dialogCity,
                                  lat: AppLocation.lat.toString(),
                                  lan: AppLocation.lng.toString(),
                                );

                                await FirebaseDatabase.instance
                                    .ref('donors')
                                    .child(dialogCity)
                                    .child(dialogGroup)
                                    .push()
                                    .set(donor.toMap());

                                if (ctx.mounted) Navigator.pop(ctx);
                                toast('Donor record added successfully!');

                                // Auto select in search filter
                                setState(() {
                                  _city = dialogCity;
                                  _group = dialogGroup;
                                });
                              } catch (e) {
                                setModalState(() => saving = false);
                                toast('Error saving: $e');
                              }
                            },
                      child: saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Save to Database',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(s('need_blood')),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, size: 26),
              tooltip: 'Add Donor',
              onPressed: () => _showAddDonorDialog(
                initialCity: _city != 'NONE' ? _city : null,
                initialGroup: _group != 'NONE' ? _group : null,
              ),
            ),
        ],
      ),
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

              // Admin Add Donor Button directly on screen
              if (_isAdmin) ...[
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E5BB8),
                    side: const BorderSide(color: Color(0xFF1E5BB8), width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                  label: const Text(
                    'Add Donor (Admin)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  onPressed: () => _showAddDonorDialog(
                    initialCity: _city != 'NONE' ? _city : null,
                    initialGroup: _group != 'NONE' ? _group : null,
                  ),
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
