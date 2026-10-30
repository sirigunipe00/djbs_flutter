import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../main.dart';
import '../strings.dart';

class BloodBankInfo {
  final String id;
  final String city;
  final String name;
  final String address;
  final String phone;
  final String? dialNumber;
  final bool isCustom;

  const BloodBankInfo({
    required this.id,
    required this.city,
    required this.name,
    required this.address,
    required this.phone,
    this.dialNumber,
    this.isCustom = false,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'address': address,
    'phone': phone,
    'city': city,
    'updatedAt': ServerValue.timestamp,
  };

  factory BloodBankInfo.fromMap(String id, String city, Map<dynamic, dynamic> map) {
    final phone = map['phone']?.toString() ?? '';
    String? dialNumber;
    if (phone.isNotEmpty) {
      final match = RegExp(r'(\+?\d[\d\s-]{5,}\d)').firstMatch(phone);
      if (match != null) {
        dialNumber = match.group(0)?.replaceAll(RegExp(r'[\s-]'), '');
      }
    }
    return BloodBankInfo(
      id: id,
      city: city,
      name: map['name']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      phone: phone,
      dialNumber: dialNumber,
      isCustom: true,
    );
  }
}

class BankScreen extends StatefulWidget {
  const BankScreen({super.key});

  @override
  State<BankScreen> createState() => _BankScreenState();
}

class _BankScreenState extends State<BankScreen> {
  String _city = AppConst.cities.first;
  List<BloodBankInfo> _banks = [];
  bool _hasSearched = false;
  bool _loading = false;

  bool get _isAdmin {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && user.uid == AppConst.adminUid;
  }

  Future<void> _find() async {
    if (_city == 'NONE') {
      toast('Select City !');
      setState(() {
        _banks = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() => _loading = true);

    final list = <BloodBankInfo>[];

    // 1. Load built-in localized blood banks
    final key = AppConst.bankKeys[_city];
    if (key != null) {
      final raw = s(key);
      list.addAll(_parseBanks(raw));
    }

    // 2. Load custom blood banks from Firebase RTDB (/blood_banks/{city})
    try {
      final snap = await FirebaseDatabase.instance
          .ref('blood_banks')
          .child(_city)
          .get();

      if (snap.exists && snap.value is Map) {
        final map = snap.value as Map;
        for (final entry in map.entries) {
          if (entry.value is Map) {
            list.add(BloodBankInfo.fromMap(
              entry.key.toString(),
              _city,
              entry.value as Map,
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading blood banks from Firebase: $e');
    }

    if (mounted) {
      setState(() {
        _banks = list;
        _hasSearched = true;
        _loading = false;
      });

      if (list.isEmpty) {
        toast('No Data Found !');
      }
    }
  }

  List<BloodBankInfo> _parseBanks(String raw) {
    if (raw.trim().isEmpty) return [];

    final rawEntries = raw.split('\n');
    final list = <BloodBankInfo>[];

    for (int idx = 0; idx < rawEntries.length; idx++) {
      final entry = rawEntries[idx];
      final text = entry.replaceAll(r'\n', '\n').trim();
      if (text.isEmpty) continue;

      final lines = text
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      if (lines.isEmpty) continue;

      final name = lines.first;
      String phone = '';
      final addressLines = <String>[];

      for (int i = 1; i < lines.length; i++) {
        final line = lines[i];
        final lower = line.toLowerCase();
        if (lower.startsWith('phone') ||
            lower.startsWith('ph.') ||
            lower.startsWith('ph:') ||
            lower.startsWith('tel') ||
            lower.contains('phone :') ||
            lower.contains('phone:') ||
            line.contains('ફોન') ||
            line.contains('फोन')) {
          phone = line;
        } else {
          addressLines.add(line);
        }
      }

      // Extract dialable phone number if available
      String? dialNumber;
      if (phone.isNotEmpty) {
        final match = RegExp(r'(\+?\d[\d\s-]{5,}\d)').firstMatch(phone);
        if (match != null) {
          dialNumber = match.group(0)?.replaceAll(RegExp(r'[\s-]'), '');
        }
      }

      list.add(BloodBankInfo(
        id: 'builtin_$idx',
        city: _city,
        name: name,
        address: addressLines.join('\n'),
        phone: phone,
        dialNumber: dialNumber,
        isCustom: false,
      ));
    }

    if (list.isEmpty) {
      list.add(BloodBankInfo(
        id: 'builtin_0',
        city: _city,
        name: _city,
        address: raw.replaceAll(r'\n', '\n').trim(),
        phone: '',
        isCustom: false,
      ));
    }

    return list;
  }

  Future<void> _call(String? number) async {
    if (number == null || number.isEmpty) {
      toast('No phone number available');
      return;
    }
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      toast('Could not open phone dialer');
    }
  }

  Future<void> _deleteBank(BloodBankInfo bank) async {
    if (!bank.isCustom) {
      toast('Default blood bank cannot be deleted');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Blood Bank'),
        content: Text('Are you sure you want to delete ${bank.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseDatabase.instance
          .ref('blood_banks')
          .child(bank.city)
          .child(bank.id)
          .remove();
      toast('Blood Bank deleted successfully');
      _find();
    } catch (e) {
      toast('Error deleting: $e');
    }
  }

  void _showAddOrEditDialog({BloodBankInfo? existing, String? initialCity}) {
    final availableCities = AppConst.cities.where((c) => c != 'NONE').toList();
    String dialogCity = existing?.city ?? initialCity ?? (availableCities.contains(_city) ? _city : availableCities.first);
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
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
                            Icons.local_hospital_rounded,
                            color: Color(0xFFDC2626),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            existing == null ? 'Add Blood Bank' : 'Edit Blood Bank',
                            style: const TextStyle(
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
                        labelText: 'District / City',
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

                    // Blood Bank Name
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Blood Bank Name',
                        hintText: 'e.g. Red Cross Blood Bank',
                        prefixIcon: Icon(Icons.local_hospital_outlined, color: Color(0xFF1E5BB8)),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Address
                    TextField(
                      controller: addressCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        hintText: 'e.g. Opp. Civil Hospital, Station Road',
                        prefixIcon: Icon(Icons.location_on_outlined, color: Color(0xFF1E5BB8)),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Mobile / Phone Number
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Mobile / Phone Number',
                        hintText: 'e.g. 02692-259596 or +919904651119',
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
                              final address = addressCtrl.text.trim();
                              final phone = phoneCtrl.text.trim();

                              if (name.isEmpty) {
                                toast('Please enter Blood Bank name');
                                return;
                              }
                              if (phone.isEmpty) {
                                toast('Please enter Mobile / Phone number');
                                return;
                              }

                              setModalState(() => saving = true);

                              try {
                                final ref = FirebaseDatabase.instance.ref('blood_banks');
                                final data = {
                                  'name': name,
                                  'address': address,
                                  'phone': phone,
                                  'city': dialogCity,
                                  'updatedAt': ServerValue.timestamp,
                                };

                                if (existing != null && existing.isCustom) {
                                  if (existing.city != dialogCity) {
                                    await ref.child(existing.city).child(existing.id).remove();
                                    await ref.child(dialogCity).push().set(data);
                                  } else {
                                    await ref.child(dialogCity).child(existing.id).update(data);
                                  }
                                } else {
                                  await ref.child(dialogCity).push().set(data);
                                }

                                if (ctx.mounted) Navigator.pop(ctx);
                                toast('Blood Bank saved successfully!');

                                setState(() => _city = dialogCity);
                                _find();
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
        title: Text(s('find_blood_bank')),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, size: 26),
              tooltip: 'Add Blood Bank',
              onPressed: () => _showAddOrEditDialog(
                initialCity: _city != 'NONE' ? _city : null,
              ),
            ),
        ],
      ),
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
              onChanged: (value) {
                setState(() {
                  _city = value ?? _city;
                  _hasSearched = false;
                  _banks = [];
                });
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _find,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(s('address_btn')),
            ),

            // Admin Add Button directly accessible under Find
            if (_isAdmin) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1E5BB8),
                  side: const BorderSide(color: Color(0xFF1E5BB8), width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: const Text(
                  'Add Blood Bank (Admin)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: () => _showAddOrEditDialog(
                  initialCity: _city != 'NONE' ? _city : null,
                ),
              ),
            ],

            const SizedBox(height: 16),
            if (_hasSearched && _banks.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Text(
                      '${_banks.length} ${s('find_blood_bank')} ($_city)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E5BB8),
                      ),
                    ),
                    const Spacer(),
                    if (_isAdmin)
                      InkWell(
                        onTap: () => _showAddOrEditDialog(
                          initialCity: _city != 'NONE' ? _city : null,
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.add, size: 16, color: Color(0xFF1E5BB8)),
                            SizedBox(width: 4),
                            Text(
                              'Add New',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E5BB8),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (_hasSearched)
              Expanded(
                child: _banks.isEmpty
                    ? Center(
                        child: Text(
                          'No Data Found for $_city',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _banks.length,
                        itemBuilder: (context, index) {
                          final bank = _banks[index];
                          return _buildBankContainer(bank, index + 1);
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankContainer(BloodBankInfo bank, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bank Name & Icon
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    color: Color(0xFFDC2626),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    bank.name,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      height: 1.3,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#$index',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),

            // Address
            if (bank.address.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      bank.address,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.45,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Phone
            if (bank.phone.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.phone_in_talk_rounded,
                      size: 16,
                      color: Color(0xFF1E5BB8),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bank.phone,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E5BB8),
                        ),
                      ),
                    ),
                    if (bank.dialNumber != null && bank.dialNumber!.isNotEmpty)
                      InkWell(
                        onTap: () => _call(bank.dialNumber),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.call, size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Call',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],

            // Admin Edit & Delete Options (for custom banks)
            if (_isAdmin && bank.isCustom) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1E5BB8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.edit, size: 14),
                    label: const Text('Edit', style: TextStyle(fontSize: 12)),
                    onPressed: () => _showAddOrEditDialog(
                      existing: bank,
                    ),
                  ),
                  const SizedBox(width: 6),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.delete_outline, size: 14),
                    label: const Text('Delete', style: TextStyle(fontSize: 12)),
                    onPressed: () => _deleteBank(bank),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
