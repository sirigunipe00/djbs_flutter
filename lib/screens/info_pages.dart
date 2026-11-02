import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants.dart';
import '../main.dart';
import '../strings.dart';
import '../theme.dart';

class EyePage extends StatelessWidget {
  const EyePage({super.key});

  Widget _buildCallButton() {
    return ElevatedButton.icon(
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
      onPressed: () => launchUrl(Uri.parse('tel:${AppConst.servicePhone}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/eye.jpeg',
              height: 260,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Primary Call Button moved upward for immediate visibility & action
        // _buildCallButton(),
        // const SizedBox(height: 16),
        _heading(s('abteye')),
        _body(s('abteye2')),
        _heading(s('abteye3')),
        _body(s('abteye4')),
        _heading(s('abteye5')),
        _body(s('abteye6')),
        _heading(s('abteye7')),
        _body(s('abteye8')),
        const SizedBox(height: 16),
        // Secondary Call Button at the bottom
        _buildCallButton(),
        const SizedBox(height: 32),
      ],
    );
  }
}

class NdfPage extends StatelessWidget {
  const NdfPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _heading(s('ndf1')),
        _body(s('ndf2')),
        _heading(s('ndf3')),
        _body(s('ndf4')),
        _heading(s('ndf5')),
        _body(s('ndf6')),
        _heading(s('ndf7')),
        _body(s('ndf8')),
        _heading(s('ndf9')),
        _body(s('ndf10')),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: () => _confirmPay(context), child: Text(s('donate_online'))),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () => launchUrl(
            Uri.parse(AppConst.ndfHistory),
            mode: LaunchMode.externalApplication,
          ),
          child: Text(s('payment_history')),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Future<void> _confirmPay(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Redirecting to Web page'),
        content: Text(s('redirect')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('ok')),
        ],
      ),
    );
    if (ok == true) {
      await launchUrl(Uri.parse(AppConst.ndfHome), mode: LaunchMode.externalApplication);
    }
  }
}

class DeadChamberItem {

  const DeadChamberItem({
    required this.id,
    required this.city,
    required this.name,
    required this.mobile,
    this.notes,
  });

  factory DeadChamberItem.fromMap(String id, Map<dynamic, dynamic> map) {
    return DeadChamberItem(
      id: id,
      city: map['city']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Dead Chamber Facility',
      mobile: map['mobile']?.toString() ?? '',
      // notes: map['notes']?.toString(),
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
    // if (notes != null && notes!.isNotEmpty) 'notes': notes,
    'updatedAt': ServerValue.timestamp,
  };
}

class MorguePage extends StatefulWidget {
  const MorguePage({super.key});

  static void showAddOrEditDialog(
    BuildContext context, {
    DeadChamberItem? existing,
    String? initialCity,
    VoidCallback? onSaved,
  }) {
    final availableCities = AppConst.cities.where((c) => c != 'NONE').toList();
    String dialogCity = existing?.city ?? initialCity ?? availableCities.first;
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
                            color: const Color(0xFFE3EDFB),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            color: Color(0xFF1E5BB8),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            existing == null ? 'Add Dead Chamber' : 'Edit Dead Chamber',
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

                    // Facility / Service Name
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Facility / Center Name',
                        hintText: 'e.g. DJBS Dead Body Chamber',
                        prefixIcon: Icon(Icons.business_rounded, color: Color(0xFF1E5BB8)),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Mobile / Phone Number
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

                    // // Notes / Details (Optional)
                    // TextField(
                    //   controller: notesCtrl,
                    //   decoration: const InputDecoration(
                    //     labelText: 'Notes / Address (Optional)',
                    //     hintText: 'e.g. Available 24x7 / Near Civil Hospital',
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: saving
                          ? null
                          : () async {
                              final name = nameCtrl.text.trim();
                              final mobile = mobileCtrl.text.trim();
                              // final notes = notesCtrl.text.trim();

                              if (name.isEmpty) {
                                toast('Please enter facility name');
                                return;
                              }
                              if (mobile.isEmpty) {
                                toast('Please enter mobile / phone number');
                                return;
                              }

                              setModalState(() => saving = true);

                              try {
                                final ref = FirebaseDatabase.instance.ref('dead_chambers');
                                final data = {
                                  'name': name,
                                  'mobile': mobile,
                                  'city': dialogCity,
                                  // if (notes.isNotEmpty) 'notes': notes,
                                  'updatedAt': ServerValue.timestamp,
                                };

                                if (existing != null) {
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
                                toast('Dead Chamber saved successfully!');
                                onSaved?.call();
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
  State<MorguePage> createState() => _MorguePageState();
}

class _MorguePageState extends State<MorguePage> {
  String? _city;
  List<DeadChamberItem> _facilities = [];
  bool _loading = false;
  bool _hasSearched = false;

  bool get _isAdmin {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && user.uid == AppConst.adminUid;
  }

  @override
  void initState() {
    super.initState();
    // Default to Amreli
    _city = 'Amreli';
    _loadFacilities('Amreli');
  }

  Future<void> _loadFacilities(String city) async {
    if (city == 'NONE') {
      setState(() {
        _facilities = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _hasSearched = true;
    });

    try {
      final snap = await FirebaseDatabase.instance.ref('dead_chambers').child(city).get();
      final list = <DeadChamberItem>[];

      if (snap.exists && snap.value is Map) {
        final map = snap.value as Map;
        for (final entry in map.entries) {
          if (entry.value is Map) {
            list.add(DeadChamberItem.fromMap(entry.key.toString(), entry.value as Map));
          }
        }
      }

      // Default for Amreli if none in database yet
      if (city == 'Amreli') {
        final hasAmreli = list.any((item) =>
            item.mobile.replaceAll(RegExp(r'\D'), '').contains('9904651119'));
        if (!hasAmreli) {
          list.insert(
            0,
            const DeadChamberItem(
              id: 'default_amreli',
              city: 'Amreli',
              name: 'DJBS Foundation Dead Chamber',
              mobile: '+919904651119',
              // notes: '24x7 Facility Available',
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _facilities = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _call(String? number) async {
    final numToCall = (number != null && number.isNotEmpty) ? number : AppConst.servicePhone;
    final uri = Uri.parse('tel:$numToCall');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      toast('Could not open phone dialer');
    }
  }

  Future<void> _deleteFacility(DeadChamberItem item) async {
    if (item.id.startsWith('default_')) {
      toast('Default facility cannot be deleted');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Dead Chamber'),
        content: Text('Are you sure you want to delete ${item.name}?'),
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
          .ref('dead_chambers')
          .child(item.city)
          .child(item.id)
          .remove();
      toast('Dead Chamber deleted successfully');
      if (_city != null) _loadFacilities(_city!);
    } catch (e) {
      toast('Error deleting: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final districts = AppConst.cities.where((c) => c != 'NONE').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card with Chamber Icon & Title
          Card(
            elevation: 0,
            color: const Color(0xFFF4F7FC),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3EDFB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.asset(
                          'assets/images/ic_card_chamber.png',
                          height: 32,
                          width: 32,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.inventory_2_outlined,
                            color: Color(0xFF1E5BB8),
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          s('morgue'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Intro text
                  Text(
                    s('morgue_intro'),
                    style: const TextStyle(
                      fontSize: 14.5,
                      height: 1.5,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Instruction text
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF1E5BB8)),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          s('morgue_instruction'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.45,
                            color: Color(0xFF1E5BB8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Please Note / Disclaimer Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFD97706),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s('morgue_note'),
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Admin Add Button
          if (_isAdmin) ...[
            const SizedBox(height: 14),
            InkWell(
              onTap: () => MorguePage.showAddOrEditDialog(
                context,
                initialCity: _city,
                onSaved: () {
                  if (_city != null) _loadFacilities(_city!);
                },
              ),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline_rounded, color: Color(0xFF1E5BB8), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Add Dead Chamber (Admin)',
                      style: TextStyle(
                        color: Color(0xFF1E5BB8),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 18),

          // District Label
          Text(
            s('district_label'),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),

          // District Dropdown
          DropdownButtonFormField<String>(
            value: _city,
            hint: Text(
              s('select_your_district'),
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 15),
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.location_city_outlined, color: Color(0xFF1E5BB8)),
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
              for (final city in districts)
                DropdownMenuItem(
                  value: city,
                  child: Text(city, style: const TextStyle(fontSize: 15)),
                ),
            ],
            onChanged: (value) {
              setState(() => _city = value);
              if (value != null) _loadFacilities(value);
            },
          ),

          const SizedBox(height: 16),

          // Loading Indicator
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          // Results
          else if (_hasSearched && _city != null) ...[
            if (_facilities.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row( 
                  children: [
                    Text(
                      '${_facilities.length} ${s('morgue')} ($_city)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E5BB8),
                      ),
                    ),
                    const Spacer(),
                    if (_isAdmin)
                      InkWell(
                        onTap: () => MorguePage.showAddOrEditDialog(
                          context,
                          initialCity: _city,
                          onSaved: () {
                            if (_city != null) _loadFacilities(_city!);
                          },
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
              for (int i = 0; i < _facilities.length; i++)
                _buildFacilityCard(_facilities[i], i + 1),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF64748B), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s('facility_unavailable_msg'),
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],

          // Primary Contact Helpline Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.callGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 1,
            ),
            icon: const Icon(Icons.phone_in_talk, size: 20),
            label: Text(
              s('contact_facility'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onPressed: () => _call(null),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFacilityCard(DeadChamberItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3EDFB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: Color(0xFF1E5BB8),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
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
            // if (item.notes != null && item.notes!.isNotEmpty) ...[
            //   const SizedBox(height: 8),
            //   Text(
            //     item.notes!,
            //     style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            //   ),
            // ],
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
                      item.mobile,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E5BB8),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => _call(item.mobile),
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
            if (_isAdmin) ...[
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
                    onPressed: () => MorguePage.showAddOrEditDialog(
                      context,
                      existing: item,
                      onSaved: () {
                        if (_city != null) _loadFacilities(_city!);
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (!item.id.startsWith('default_'))
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.delete_outline, size: 14),
                      label: const Text('Delete', style: TextStyle(fontSize: 12)),
                      onPressed: () => _deleteFacility(item),
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

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // Future<void> _contact() async {
  //   final uri = Uri.parse(
  //     'mailto:${AppConst.developerEmail}?subject=${Uri.encodeComponent(AppConst.developerName)}',
  //   );
  //   final opened = await launchUrl(uri);
  //   if (!opened) {
  //     await launchUrl(Uri.parse('tel:${AppConst.developerPhone}'));
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(s('about_us'))),
      body: Center(
        child:  Image.asset('assets/images/djbs_logos.png', height: 180),
        
      )
      // Column(
      //   mainAxisAlignment: MainAxisAlignment.center,
      //   children: [
      //     const Spacer(),
      //     Image.asset('assets/images/djbs_logos.png', height: 180),
          // const Spacer(),
          // Padding(
          //   padding: const EdgeInsets.only(bottom: 16),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       Text('${s('design')} : ', style: const TextStyle(color: AppColors.termGray)),
          //       GestureDetector(
          //         onTap: _contact,
          //         child: Text(
          //           s('jatinsoft'),
          //           style: const TextStyle(
          //             color: AppColors.googleBlue,
          //             fontWeight: FontWeight.bold,
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
      //   ],
      // ),
    );
  }
}

Widget _heading(String text) {
  return Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 4),
    child: Text(
      text,
      style: const TextStyle(color: AppColors.fbBlue, fontSize: 22, fontWeight: FontWeight.w600),
    ),
  );
}

Widget _body(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 16, height: 1.35)),
  );
}
