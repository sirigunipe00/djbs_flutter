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

        for (final entry in value.entries) {
          final donorValue = entry.value;

          if (donorValue is Map) {
            donors.add(Donor.fromMap(donorValue));
          }
        }

        if (mounted) {
          setState(() {
            _donors
              ..clear()
              ..addAll(donors);
            _loading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.city} · ${widget.group}')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _loading && _donors.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _donors.isEmpty
                      ? const Center(
                          child: Text(
                            'No Donors Found',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
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
                              trailing: IconButton(
                                icon: const Icon(Icons.call, color: AppColors.callGreen),
                                onPressed: () => _call(donor),
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
