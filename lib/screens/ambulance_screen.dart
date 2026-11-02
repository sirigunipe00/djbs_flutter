import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../main.dart';
import '../strings.dart';
import '../theme.dart';

class AmbulanceItem {

  const AmbulanceItem({
    required this.id,
    required this.city,
    required this.name,
    required this.mobile,
    this.notes,
  });

  factory AmbulanceItem.fromMap(String id, Map<dynamic, dynamic> map) {
    return AmbulanceItem(
      id: id,
      city: map['city']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Ambulance Service',
      mobile: map['mobile']?.toString() ?? '',
      notes: map['notes']?.toString(),
    );
  }
  final String id;
  final String city;
  final String name;
  final String mobile;
  final String? notes;

  Map<String, dynamic> toMap() => {
    'name': name,
    'mobile': mobile,
    'city': city,
    if (notes != null && notes!.isNotEmpty) 'notes': notes,
    'updatedAt': ServerValue.timestamp,
  };
}

class AmbulanceScreen extends StatefulWidget {
  const AmbulanceScreen({super.key});

  @override
  State<AmbulanceScreen> createState() => _AmbulanceScreenState();
}

class _AmbulanceScreenState extends State<AmbulanceScreen> {
  String _city = AppConst.cities.first;
  List<AmbulanceItem> _ambulances = [];
  bool _hasSearched = false;
  bool _loading = false;

  bool get _isAdmin {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && user.uid == AppConst.adminUid;
  }

  Future<void> _find() async {
    if (_city == 'NONE') {
      toast(s('select_city'));
      setState(() {
        _ambulances = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() => _loading = true);

    try {
      final snap = await FirebaseDatabase.instance.ref('ambulances').child(_city).get();
      final list = <AmbulanceItem>[];

      if (snap.exists && snap.value is Map) {
        final map = snap.value as Map;
        for (final entry in map.entries) {
          if (entry.value is Map) {
            list.add(AmbulanceItem.fromMap(entry.key.toString(), entry.value as Map));
          }
        }
      }

      // By default for all cities, include the DJBS Foundation Ambulance number (+919904651119)
      final hasDefault = list.any((item) =>
          item.mobile.replaceAll(RegExp(r'\D'), '').contains('9904651119'));
      if (!hasDefault && _city != 'NONE') {
        list.insert(
          0,
          AmbulanceItem(
            id: 'default_$_city',
            city: _city,
            name: 'DJBS Foundation Ambulance',
            mobile: '+919904651119',
            notes: '24x7 Emergency Service',
          ),
        );
      }

      if (mounted) {
        setState(() {
          _ambulances = list;
          _hasSearched = true;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[AmbulanceScreen] fetch error: $e');
      if (mounted) {
        setState(() {
          _hasSearched = true;
          _loading = false;
        });
      }
    }
  }

  Future<void> _call(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.isEmpty) {
      toast('No phone number available');
      return;
    }
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      toast('Could not open phone dialer');
    }
  }

  Future<void> _deleteAmbulance(AmbulanceItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Ambulance Service'),
        content: Text('Are you sure you want to delete "${item.name}" from ${item.city}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseDatabase.instance
          .ref('ambulances')
          .child(item.city)
          .child(item.id)
          .remove();
      toast('Ambulance deleted successfully');
      _find();
    } catch (e) {
      toast('Error deleting: $e');
    }
  }

  void _showAddOrEditDialog({AmbulanceItem? existing, String? initialCity}) {
    final availableCities = AppConst.cities.where((c) => c != 'NONE').toList();
    String dialogCity = existing?.city ?? initialCity ?? (availableCities.contains(_city) ? _city : availableCities.first);
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final mobileCtrl = TextEditingController(text: existing?.mobile ?? '');
    // final notesCtrl = TextEditingController(text: existing?.notes ?? '');
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
                            Icons.airport_shuttle_rounded,
                            color: Color(0xFFDC2626),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            existing == null ? 'Add Ambulance Service' : 'Edit Ambulance Service',
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

                    // Service / Provider Name
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Service / Provider Name',
                        hintText: 'e.g. DJBS Emergency Ambulance / Red Cross',
                        prefixIcon: Icon(Icons.business_rounded, color: Color(0xFF1E5BB8)),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Mobile / Phone
                    TextField(
                      controller: mobileCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Mobile / Phone Number',
                        hintText: 'e.g. +919904651119 or 02792-223034',
                        prefixIcon: Icon(Icons.phone_rounded, color: Color(0xFF1E5BB8)),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Notes (Optional)
                    // TextField(
                    //   controller: notesCtrl,
                    //   decoration: const InputDecoration(
                    //     labelText: 'Notes / Facilities (Optional)',
                    //     hintText: 'e.g. 24x7 Service, Oxygen / ICU Available',
                    //     prefixIcon: Icon(Icons.notes_rounded, color: Color(0xFF1E5BB8)),
                    //     border: OutlineInputBorder(),
                    //   ),
                    // ),
                    const SizedBox(height: 20),

                    // Save Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E5BB8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: saving
                          ? null
                          : () async {
                              final name = nameCtrl.text.trim();
                              final mobile = mobileCtrl.text.trim();
                              // final notes = notesCtrl.text.trim();

                              if (name.isEmpty) {
                                toast('Please enter Service / Provider Name');
                                return;
                              }
                              if (mobile.isEmpty) {
                                toast('Please enter Mobile / Phone number');
                                return;
                              }

                              setModalState(() => saving = true);

                              try {
                                final ref = FirebaseDatabase.instance.ref('ambulances');
                                final data = {
                                  'name': name,
                                  'mobile': mobile,
                                  'city': dialogCity,
                                  // if (notes.isNotEmpty) 'notes': notes,
                                  'updatedAt': ServerValue.timestamp,
                                };

                                if (existing != null) {
                                  // If city changed, remove old and add to new
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
                                toast('Ambulance saved successfully!');

                                // Auto select this city and refresh
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(s('ambulance')),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, size: 26),
              tooltip: 'Add Ambulance',
              onPressed: () => _showAddOrEditDialog(
                initialCity: _city != 'NONE' ? _city : null,
              ),
            ),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF1E5BB8),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add Ambulance',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              onPressed: () => _showAddOrEditDialog(
                initialCity: _city != 'NONE' ? _city : null,
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // Top Filter Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F4F6),
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        'assets/images/ambulance_128.png',
                        height: 60,
                        width: 60,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // City Dropdown
                  DropdownButtonFormField<String>(
                    value: _city,
                    decoration: InputDecoration(
                      labelText: s('select_city'),
                      prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF1E5BB8)),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1E5BB8), width: 1.8),
                      ),
                    ),
                    items: [
                      for (final city in AppConst.cities)
                        DropdownMenuItem(
                          value: city,
                          child: Text(
                            city,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: city == 'NONE' ? FontWeight.normal : FontWeight.w600,
                              color: city == 'NONE' ? Colors.grey : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _city = value ?? _city;
                        _hasSearched = false;
                        _ambulances = [];
                      });
                    },
                  ),
                  const SizedBox(height: 10),

                  // Find Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E5BB8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 1,
                    ),
                    icon: const Icon(Icons.search, size: 20),
                    label: Text(
                      s('address_btn'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _loading ? null : _find,
                  ),
                ],
              ),
            ),

            // Results count badge
            if (_hasSearched && _ambulances.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E7FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.airport_shuttle_rounded,
                            size: 15,
                            color: Color(0xFF3730A3),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_ambulances.length} Ambulance Services in $_city',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3730A3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Content List
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFE2E8F0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.airport_shuttle_outlined,
                  size: 48,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select City & Find Ambulance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose your district above and tap Find to see available emergency ambulance contacts.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B), height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    if (_ambulances.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.car_crash_outlined,
                  size: 44,
                  color: Color(0xFFDC2626),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'No Ambulance service listed for $_city',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Please contact the DJBS main helpline or national emergency service 108.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.callGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.phone_in_talk, size: 18),
                label: const Text('Call Main Helpline (Amreli)'),
                onPressed: () => _call(AppConst.servicePhone),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 80),
      itemCount: _ambulances.length,
      itemBuilder: (context, index) {
        final item = _ambulances[index];
        return _buildAmbulanceCard(item, index + 1);
      },
    );
  }

  Widget _buildAmbulanceCard(AmbulanceItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
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
            // Header Row: Icon + Name + Admin Actions
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
                    Icons.airport_shuttle_rounded,
                    color: Color(0xFFDC2626),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(
                            item.city,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_isAdmin && !item.id.startsWith('default_')) ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF1E5BB8)),
                    tooltip: 'Edit',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _showAddOrEditDialog(existing: item),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    tooltip: 'Delete',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _deleteAmbulance(item),
                  ),
                ],
              ],
            ),

            // Notes / Facilities if available
            // if (item.notes != null && item.notes!.isNotEmpty) ...[
            //   const SizedBox(height: 8),
            //   Container(
            //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            //     decoration: BoxDecoration(
            //       color: const Color(0xFFF0FDF4),
            //       borderRadius: BorderRadius.circular(6),
            //       border: Border.all(color: const Color(0xFFBBF7D0)),
            //     ),
            //     child: Row(
            //       mainAxisSize: MainAxisSize.min,
            //       children: [
            //         const Icon(Icons.info_outline, size: 13, color: Color(0xFF16A34A)),
            //         const SizedBox(width: 5),
            //         Flexible(
            //           child: Text(
            //             item.notes!,
            //             style: const TextStyle(
            //               fontSize: 12,
            //               color: Color(0xFF15803D),
            //               fontWeight: FontWeight.w600,
            //             ),
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ],

            const SizedBox(height: 10),

            // Contact & Call Action
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
                      item.mobile,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E5BB8),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => _call(item.mobile),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.call, size: 13, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Call',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
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
        ),
      ),
    );
  }
}
