import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../main.dart';
import '../models/donor.dart';
import '../services/app_services.dart';
import '../strings.dart';
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
    ref.onChildAdded.listen((event) {
      final value = event.snapshot.value;
      if (value is! Map) return;
      final donor = Donor.fromMap(value);
      if (!mounted) return;
      setState(() => _donors.add(donor));
    }, onError: (_) {
      if (mounted) setState(() => _loading = false);
    });
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _call(Donor donor) async {
    final uri = Uri.parse('tel:${donor.mobileNumber}');
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.city} · ${widget.group}')),
      body: Column(
        children: [
          if (_isAdmin)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(s('aadhar'), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          Expanded(
            child: _loading && _donors.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    itemCount: _donors.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final donor = _donors[index];
                      return ListTile(
                        title: Text(donor.name),
                        subtitle: Text(
                          _isAdmin
                              ? '${donor.mobileNumber}\n${donor.adhar}'
                              : donor.mobileNumber,
                        ),
                        trailing: const Icon(Icons.call),
                        onTap: () => _call(donor),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MapScreen(donors: List.of(_donors)),
                  ),
                );
              },
              child: Text(s('map_btn')),
            ),
          ),
        ],
      ),
    );
  }
}
