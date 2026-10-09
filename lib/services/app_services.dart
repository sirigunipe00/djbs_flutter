import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocation {
  static double lat = 0;
  static double lng = 0;

  static Future<String?> refresh() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      await Geolocator.openLocationSettings();
      return 'Please Turn on Location';
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return 'Location permission denied';
    }
    final position = await Geolocator.getCurrentPosition();
    lat = position.latitude;
    lng = position.longitude;
    return null;
  }
}

class Net {
  static Future<bool> online() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }
}

class Prefs {
  static const agreedKey = 'isFirstRun';

  static Future<bool> hasAgreed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(agreedKey) ?? false;
  }

  static Future<void> setAgreed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(agreedKey, true);
  }
}

class ProfileStore {
  static DatabaseReference get _profiles =>
      FirebaseDatabase.instance.ref('profile');

  static Future<String?> imageUrl(String? displayName) async {
    if (displayName == null || displayName.isEmpty) return null;
    final snap = await _profiles.child('$displayName/imageUrl').get();
    final value = snap.value?.toString();
    if (value == null || value.isEmpty || value == 'null') return null;
    return value;
  }

  static Future<String> upload(User user, File file) async {
    final ext = file.path.split('.').last;
    final ref = FirebaseStorage.instance.ref('uploads/${user.email}.$ext');
    await ref.putFile(file);
    final url = await ref.getDownloadURL();
    final name = (user.displayName == null || user.displayName!.trim().isEmpty)
        ? 'No Name'
        : user.displayName!;
    await _profiles.child(name).set({'name': name, 'imageUrl': url});
    await user.updatePhotoURL(url);
    return url;
  }
}
