import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';

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

class AuthService {
  static const _phonePrefix = 'djbs_phone_to_email_';

  /// Normalizes a phone number by stripping all non-digits and removing leading country codes (+91, 91, 0)
  static String normalizePhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('91')) {
      digits = digits.substring(2);
    } else if (digits.length == 11 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return digits;
  }

  /// Determines whether the input is formatted like an email
  static bool isEmail(String input) {
    final trimmed = input.trim().toLowerCase();
    return trimmed.contains('@') && AppConst.emailPattern.hasMatch(trimmed);
  }

  /// Determines whether the input looks like a phone number
  static bool isPhone(String input) {
    if (input.contains('@')) return false;
    final digits = normalizePhone(input);
    return digits.length == 10;
  }

  /// Caches phone to email mapping locally on this device
  static Future<void> cacheLocal(String phone, String email) async {
    try {
      final clean = normalizePhone(phone);
      final lowerEmail = email.trim().toLowerCase();
      if (!lowerEmail.contains('@')) return;
      final prefs = await SharedPreferences.getInstance();
      if (clean.isNotEmpty) {
        await prefs.setString('$_phonePrefix$clean', lowerEmail);
      }
      if (phone.trim() != clean && phone.trim().isNotEmpty) {
        await prefs.setString('$_phonePrefix${phone.trim()}', lowerEmail);
      }
      debugPrint('[AuthService] Cached phone $clean -> $lowerEmail locally');
    } catch (e) {
      debugPrint('[AuthService] Local phone cache error: $e');
    }
  }

  /// Looks up phone to email mapping from local device storage
  static Future<String?> getLocalCachedEmail(String rawPhone) async {
    try {
      final clean = normalizePhone(rawPhone);
      final prefs = await SharedPreferences.getInstance();
      final candidates = [
        if (clean.isNotEmpty) clean,
        if (clean.length == 10) '+91$clean',
        if (clean.length == 10) '91$clean',
        if (clean.length == 10) '0$clean',
        rawPhone.trim(),
      ];
      for (final key in candidates) {
        if (key.isEmpty) continue;
        final cached = prefs.getString('$_phonePrefix$key');
        if (cached != null && cached.contains('@')) {
          return cached.trim().toLowerCase();
        }
      }
    } catch (e) {
      debugPrint('[AuthService] Local phone lookup error: $e');
    }
    return null;
  }

  /// Finds the registered email linked to the given phone number
  static Future<String?> findEmailByPhone(String rawPhone) async {
    final clean = normalizePhone(rawPhone);
    final digitsOnly = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty && digitsOnly.isEmpty) return null;

    // 0. Check local device cache first (instant and 100% offline-friendly)
    final localMatch = await getLocalCachedEmail(rawPhone);
    if (localMatch != null && localMatch.isNotEmpty) {
      debugPrint('[AuthService] Found email from local cache: $localMatch');
      return localMatch;
    }

    final candidates = <String>{
      if (clean.isNotEmpty) clean,
      if (digitsOnly.isNotEmpty) digitsOnly,
      if (clean.length == 10) '+91$clean',
      if (clean.length == 10) '91$clean',
      if (clean.length == 10) '0$clean',
      rawPhone.trim(),
    };

    // 1. Direct lookup in users_by_phone
    for (final key in candidates) {
      if (key.isEmpty) continue;
      try {
        final snap = await FirebaseDatabase.instance.ref('users_by_phone').child(key).get();
        if (snap.exists && snap.value != null) {
          final val = snap.value;
          if (val is String && val.contains('@')) {
            final email = val.trim().toLowerCase();
            await cacheLocal(clean, email);
            return email;
          } else if (val is Map) {
            final email = val['email']?.toString();
            if (email != null && email.contains('@')) {
              final em = email.trim().toLowerCase();
              await cacheLocal(clean, em);
              return em;
            }
          }
        }
      } catch (e) {
        debugPrint('[AuthService] Error querying users_by_phone/$key: $e');
      }
    }

    // 2. Query in 'users' collection
    try {
      final usersSnap = await FirebaseDatabase.instance.ref('users').get();
      if (usersSnap.exists && usersSnap.value is Map) {
        final usersMap = usersSnap.value as Map;
        for (final entry in usersMap.values) {
          if (entry is Map) {
            final userMobile = normalizePhone(entry['mobile']?.toString() ?? entry['mobileNumber']?.toString() ?? '');
            if (userMobile.isNotEmpty && (userMobile == clean || userMobile.endsWith(clean) || clean.endsWith(userMobile))) {
              final email = entry['email']?.toString();
              if (email != null && email.contains('@')) {
                final em = email.trim().toLowerCase();
                await cacheLocal(clean, em);
                await linkPhoneToEmail(phone: clean, email: em, uid: entry['uid']?.toString());
                return em;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[AuthService] Error querying users node: $e');
    }

    // 3. Search in 'donors' tree (donors/{city}/{group}/{id})
    try {
      final donorsSnap = await FirebaseDatabase.instance.ref('donors').get();
      if (donorsSnap.exists && donorsSnap.value is Map) {
        final citiesMap = donorsSnap.value as Map;
        for (final cityVal in citiesMap.values) {
          if (cityVal is! Map) continue;
          for (final groupVal in cityVal.values) {
            if (groupVal is! Map) continue;
            for (final donorVal in groupVal.values) {
              if (donorVal is! Map) continue;
              final donorPhone = normalizePhone(donorVal['mobileNumber']?.toString() ?? '');
              if (donorPhone.isNotEmpty && (donorPhone == clean || donorPhone.endsWith(clean) || clean.endsWith(donorPhone))) {
                final email = donorVal['email']?.toString();
                if (email != null && email.contains('@')) {
                  final em = email.trim().toLowerCase();
                  await cacheLocal(clean, em);
                  await linkPhoneToEmail(phone: clean, email: em);
                  return em;
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[AuthService] Error querying donors tree: $e');
    }

    return null;
  }

  /// Links a phone number to an email locally and in Firebase Realtime Database
  static Future<void> linkPhoneToEmail({
    required String phone,
    required String email,
    String? uid,
  }) async {
    final clean = normalizePhone(phone);
    if (clean.isEmpty || !email.contains('@')) return;
    final lowerEmail = email.trim().toLowerCase();

    // Cache locally immediately
    await cacheLocal(clean, lowerEmail);
    if (phone.trim() != clean) {
      await cacheLocal(phone.trim(), lowerEmail);
    }

    final data = {
      'email': lowerEmail,
      'mobile': clean,
      if (uid != null) 'uid': uid,
      'updatedAt': ServerValue.timestamp,
    };

    try {
      await FirebaseDatabase.instance.ref('users_by_phone').child(clean).set(data);
      if (phone.trim() != clean && phone.trim().isNotEmpty) {
        await FirebaseDatabase.instance.ref('users_by_phone').child(phone.trim()).set(data);
      }
      debugPrint('[AuthService] Successfully linked phone $clean in users_by_phone');
    } catch (e) {
      debugPrint('[AuthService] Could not write to users_by_phone (check Firebase Security Rules): $e');
    }
  }

  /// Saves full user details into local cache, users_by_phone, and users node
  static Future<void> saveUserRegistration({
    required User user,
    required String name,
    required String email,
    required String mobile,
    required String city,
    required String bloodGroup,
    required String aadhar,
  }) async {
    final clean = normalizePhone(mobile);
    final lowerEmail = email.trim().toLowerCase();

    // 1. Cache locally first
    await cacheLocal(clean, lowerEmail);
    await cacheLocal(mobile.trim(), lowerEmail);

    // 2. Link in users_by_phone
    try {
      await linkPhoneToEmail(phone: mobile, email: lowerEmail, uid: user.uid);
    } catch (e) {
      debugPrint('[AuthService] saveUserRegistration linkPhone error: $e');
    }

    // 3. Save to users node
    try {
      await FirebaseDatabase.instance.ref('users').child(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': lowerEmail,
        'mobile': mobile.trim(),
        'cleanMobile': clean,
        'city': city,
        'bloodGroup': bloodGroup,
        'aadhar': aadhar,
        'createdAt': ServerValue.timestamp,
      });
      debugPrint('[AuthService] Successfully saved to users/${user.uid}');
    } catch (e) {
      debugPrint('[AuthService] saveUserRegistration users node error: $e');
    }
  }

  /// When user logs in with email, auto-sync their phone mapping if found in donors/users
  static Future<void> syncUserMappingOnEmailLogin(User user) async {
    try {
      final email = user.email;
      if (email == null || email.isEmpty) return;
      final lowerEmail = email.trim().toLowerCase();

      // Check if user already exists under users/{user.uid}
      final userSnap = await FirebaseDatabase.instance.ref('users').child(user.uid).get();
      if (userSnap.exists && userSnap.value is Map) {
        final uMap = userSnap.value as Map;
        final mobile = uMap['mobile']?.toString() ?? uMap['mobileNumber']?.toString();
        if (mobile != null && mobile.isNotEmpty) {
          await cacheLocal(mobile, lowerEmail);
          await linkPhoneToEmail(phone: mobile, email: lowerEmail, uid: user.uid);
          return;
        }
      }

      // Search donors for matching email or name
      final donorsSnap = await FirebaseDatabase.instance.ref('donors').get();
      if (donorsSnap.exists && donorsSnap.value is Map) {
        final citiesMap = donorsSnap.value as Map;
        for (final cityVal in citiesMap.values) {
          if (cityVal is! Map) continue;
          for (final groupVal in cityVal.values) {
            if (groupVal is! Map) continue;
            for (final donorVal in groupVal.values) {
              if (donorVal is! Map) continue;
              final donorEmail = donorVal['email']?.toString();
              final donorName = donorVal['name']?.toString();
              final mobile = donorVal['mobileNumber']?.toString();
              if (mobile != null && mobile.isNotEmpty) {
                final matchEmail = donorEmail != null && donorEmail.toLowerCase() == lowerEmail;
                final matchName = donorName != null && user.displayName != null && donorName.toLowerCase() == user.displayName!.toLowerCase();
                if (matchEmail || matchName) {
                  await cacheLocal(mobile, lowerEmail);
                  await linkPhoneToEmail(phone: mobile, email: lowerEmail, uid: user.uid);
                  await FirebaseDatabase.instance.ref('users').child(user.uid).update({
                    'uid': user.uid,
                    'email': lowerEmail,
                    'mobile': mobile,
                    'cleanMobile': normalizePhone(mobile),
                    if (donorName != null) 'name': donorName,
                  });
                  return;
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[AuthService] syncUserMappingOnEmailLogin error: $e');
    }
  }
}
