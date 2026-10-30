import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../main.dart';
import '../models/donor.dart';
import '../services/app_services.dart';
import '../strings.dart';
import '../theme.dart';
import '../utils/word_capitalization.dart';
import 'map_screen.dart';

class DonorListScreen extends StatefulWidget {
  const DonorListScreen({super.key, required this.city, required this.group});

  final String city;
  final String group;

  @override
  State<DonorListScreen> createState() => _DonorListScreenState();
}

class _DonorListScreenState extends State<DonorListScreen> {
  final _donors = <Donor>[];
  final _donorKeys = <String>[];
  bool _loading = true;

  bool get _isAdmin =>
      FirebaseAuth.instance.currentUser?.uid == AppConst.adminUid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!await Net.online()) {
      toast('Internet connection may not available');
    } else {
      toast('Please Wait...');
    }

    final ref = FirebaseDatabase.instance
        .ref('donors')
        .child(widget.city)
        .child(widget.group);

    try {
      final snapshot = await ref.get();

      if (snapshot.exists) {
        final value = snapshot.value;

        if (value is Map) {
          final donors = <Donor>[];
          final keys = <String>[];

          for (final entry in value.entries) {
            final donorValue = entry.value;

            if (donorValue is Map) {
              keys.add(entry.key.toString());
              donors.add(Donor.fromMap(donorValue));
            }
          }

          if (mounted) {
            setState(() {
              _donors
                ..clear()
                ..addAll(donors);
              _donorKeys
                ..clear()
                ..addAll(keys);
              _loading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _donors.clear();
            _donorKeys.clear();
            _loading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading donors: $e');

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _call(Donor donor) async {
    final uri = Uri.parse('tel:${donor.mobileNumber}');
    await launchUrl(uri);
  }

  Future<void> _deleteDonor(int index) async {
    if (index >= _donorKeys.length) return;
    final donor = _donors[index];
    final key = _donorKeys[index];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Donor'),
        content: Text('Are you sure you want to delete ${donor.name}?'),
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
          .ref('donors')
          .child(widget.city)
          .child(widget.group)
          .child(key)
          .remove();
      toast('Donor deleted successfully');
      _load();
    } catch (e) {
      toast('Error deleting: $e');
    }
  }

  void _showAddDonorDialog() {
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
                        Expanded(
                          child: Text(
                            'Add Donor (${widget.city} · ${widget.group})',
                            style: const TextStyle(
                              fontSize: 17,
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
                                  bloodGroup: widget.group,
                                  city: widget.city,
                                  lat: AppLocation.lat.toString(),
                                  lan: AppLocation.lng.toString(),
                                );

                                await FirebaseDatabase.instance
                                    .ref('donors')
                                    .child(widget.city)
                                    .child(widget.group)
                                    .push()
                                    .set(donor.toMap());

                                if (ctx.mounted) Navigator.pop(ctx);
                                toast('Donor record added successfully!');
                                _load();
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
        title: Text('${widget.city} · ${widget.group}'),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, size: 26),
              tooltip: 'Add Donor',
              onPressed: _showAddDonorDialog,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _loading && _donors.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _donors.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'No Donors Found',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                              if (_isAdmin) ...[
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E5BB8),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add First Donor'),
                                  onPressed: _showAddDonorDialog,
                                ),
                              ],
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _donors.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final donor = _donors[index];
                            return ListTile(
                              title: Text(
                                donor.name,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(donor.mobileNumber),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.call, color: AppColors.callGreen),
                                    onPressed: () => _call(donor),
                                  ),
                                  if (_isAdmin)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      tooltip: 'Delete Donor',
                                      onPressed: () => _deleteDonor(index),
                                    ),
                                ],
                              ),
                              onTap: () => _call(donor),
                            );
                          },
                        ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E5BB8),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.map, size: 20),
                label: Text(
                  s('map_btn'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MapScreen(donors: List.of(_donors)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
