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

  /// Extracts strictly the 10-digit mobile number, stripping any .v$timestamp or domain suffix
  static String extract10DigitPhone(String? input) {
    if (input == null || input.isEmpty) return '';
    String clean = input.trim();
    if (clean.contains('@')) {
      clean = clean.split('@').first;
    }
    if (clean.contains('.')) {
      clean = clean.split('.').first;
    }
    var digits = normalizePhone(clean);
    if (digits.length > 10) {
      digits = digits.substring(0, 10);
    }
    return digits;
  }

  /// Finds user's full name from SharedPreferences, users_by_phone, users, or donors
  static Future<String?> findUserName(String mobile) async {
    final clean = extract10DigitPhone(mobile);
    if (clean.isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('djbs_name_$clean');
    if (cached != null && cached.isNotEmpty && cached != 'null') {
      return cached;
    }

    // 1. Check users_by_phone
    try {
      final snap = await FirebaseDatabase.instance.ref('users_by_phone').child(clean).get();
      if (snap.exists && snap.value is Map) {
        final val = snap.value as Map;
        final name = val['name']?.toString();
        if (name != null && name.isNotEmpty && name != 'null') {
          await prefs.setString('djbs_name_$clean', name);
          return name;
        }
      }
    } catch (_) {}

    // 2. Check users node (only if authenticated)
    if (FirebaseAuth.instance.currentUser != null) {
      try {
        final usersSnap = await FirebaseDatabase.instance.ref('users').get();
        if (usersSnap.exists && usersSnap.value is Map) {
          for (final entry in (usersSnap.value as Map).values) {
            if (entry is Map) {
              final uPhone = extract10DigitPhone(entry['mobile']?.toString() ?? entry['cleanMobile']?.toString() ?? '');
              if (uPhone == clean) {
                final name = entry['name']?.toString();
                if (name != null && name.isNotEmpty && name != 'null') {
                  await prefs.setString('djbs_name_$clean', name);
                  await FirebaseDatabase.instance.ref('users_by_phone').child(clean).update({'name': name});
                  return name;
                }
              }
            }
          }
        }
      } catch (_) {}
    }

    // 3. Search donors tree
    try {
      final donorsSnap = await FirebaseDatabase.instance.ref('donors').get();
      if (donorsSnap.exists && donorsSnap.value is Map) {
        for (final cityVal in (donorsSnap.value as Map).values) {
          if (cityVal is! Map) continue;
          for (final groupVal in cityVal.values) {
            if (groupVal is! Map) continue;
            for (final donorVal in groupVal.values) {
              if (donorVal is! Map) continue;
              final dPhone = extract10DigitPhone(donorVal['mobileNumber']?.toString() ?? '');
              if (dPhone == clean) {
                final name = donorVal['name']?.toString();
                if (name != null && name.isNotEmpty && name != 'null') {
                  await prefs.setString('djbs_name_$clean', name);
                  await FirebaseDatabase.instance.ref('users_by_phone').child(clean).update({'name': name});
                  return name;
                }
              }
            }
          }
        }
      }
    } catch (_) {}

    return null;
  }

  /// Formats a 10-digit mobile number into the internal synthetic account email
  static String phoneToEmail(String phone) {
    final clean = normalizePhone(phone);
    return '$clean@djbs.app';
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

  /// Checks whether an account exists for the given mobile number in users_by_phone or donors
  static Future<bool> accountExists(String mobile) async {
    final clean = extract10DigitPhone(mobile);
    if (clean.length < 10) return false;

    // 1. Direct lookup in users_by_phone
    try {
      final snap = await FirebaseDatabase.instance.ref('users_by_phone').child(clean).get();
      if (snap.exists && snap.value != null) {
        if (snap.value is Map) {
          final map = snap.value as Map;
          if (map.isNotEmpty) return true;
        } else if (snap.value.toString().isNotEmpty) {
          return true;
        }
      }
    } catch (e) {
      debugPrint('[AuthService] accountExists users_by_phone error: $e');
    }

    final rawClean = normalizePhone(mobile);
    if (rawClean.isNotEmpty && rawClean != clean) {
      try {
        final snap = await FirebaseDatabase.instance.ref('users_by_phone').child(rawClean).get();
        if (snap.exists && snap.value != null) return true;
      } catch (_) {}
    }

    // 2. Search in donors tree
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
              final dPhone = extract10DigitPhone(donorVal['mobileNumber']?.toString() ?? '');
              if (dPhone == clean) {
                return true;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[AuthService] accountExists donors error: $e');
    }

    return false;
  }

  /// Finds the registered email linked to the given phone number
  static Future<String?> findEmailByPhone(String rawPhone) async {
    final clean = normalizePhone(rawPhone);
    final digitsOnly = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty && digitsOnly.isEmpty) return null;

    final candidates = <String>{
      if (clean.isNotEmpty) clean,
      if (digitsOnly.isNotEmpty) digitsOnly,
      if (clean.length == 10) '+91$clean',
      if (clean.length == 10) '91$clean',
      if (clean.length == 10) '0$clean',
      rawPhone.trim(),
    };

    // 1. Direct lookup in users_by_phone (authoritative server source)
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

    // 2. Check local device cache
    final localMatch = await getLocalCachedEmail(rawPhone);
    if (localMatch != null && localMatch.isNotEmpty) {
      debugPrint('[AuthService] Found email from local cache: $localMatch');
      return localMatch;
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

    // 4. Query in 'users' collection (only if authenticated)
    if (FirebaseAuth.instance.currentUser != null) {
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
    }

    return null;
  }

  /// Links a phone number to an email locally and in Firebase Realtime Database
  static Future<void> linkPhoneToEmail({
    required String phone,
    required String email,
    String? uid,
    String? password,
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
      if (password != null && password.isNotEmpty) 'pass': password,
      'updatedAt': ServerValue.timestamp,
    };

    try {
      await FirebaseDatabase.instance.ref('users_by_phone').child(clean).update(data);
      if (phone.trim() != clean && phone.trim().isNotEmpty) {
        await FirebaseDatabase.instance.ref('users_by_phone').child(phone.trim()).update(data);
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
    String aadhar = '',
    String? password,
  }) async {
    final clean = normalizePhone(mobile);
    final lowerEmail = email.trim().toLowerCase();

    // 1. Cache locally first
    await cacheLocal(clean, lowerEmail);
    await cacheLocal(mobile.trim(), lowerEmail);

    // 2. Link in users_by_phone
    try {
      await linkPhoneToEmail(phone: mobile, email: lowerEmail, uid: user.uid, password: password);
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
        if (password != null && password.isNotEmpty) 'pass': password,
        'createdAt': ServerValue.timestamp,
      });
      debugPrint('[AuthService] Successfully saved to users/${user.uid}');
    } catch (e) {
      debugPrint('[AuthService] saveUserRegistration users node error: $e');
    }
  }

  /// Generates the internal deterministic token for synthetic accounts
  static String authSecretFor(String mobile) {
    final clean = normalizePhone(mobile);
    return 'Djbs@2026_$clean';
  }

  /// Retrieves the stored password for a mobile number from users_by_phone or users
  static Future<String?> getStoredPassword(String rawPhone) async {
    final clean = normalizePhone(rawPhone);
    if (clean.isEmpty) return null;

    try {
      final snap = await FirebaseDatabase.instance.ref('users_by_phone').child(clean).get();
      if (snap.exists && snap.value is Map) {
        final val = snap.value as Map;
        final pass = val['pass']?.toString();
        if (pass != null && pass.isNotEmpty) return pass;
      }
    } catch (e) {
      debugPrint('[AuthService] Error reading password from users_by_phone: $e');
    }

    // Only query 'users' collection if authenticated
    if (FirebaseAuth.instance.currentUser != null) {
      try {
        final usersSnap = await FirebaseDatabase.instance.ref('users').get();
        if (usersSnap.exists && usersSnap.value is Map) {
          final usersMap = usersSnap.value as Map;
          for (final entry in usersMap.values) {
            if (entry is Map) {
              final userMobile = normalizePhone(entry['mobile']?.toString() ?? entry['cleanMobile']?.toString() ?? '');
              if (userMobile == clean) {
                final pass = entry['pass']?.toString();
                if (pass != null && pass.isNotEmpty) return pass;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[AuthService] Error reading password from users node: $e');
      }
    }
    return null;
  }

  /// Directly updates password in users_by_phone, users, and Firebase Auth
  static Future<bool> updatePasswordDirectly({
    required String mobile,
    required String newPassword,
  }) async {
    final clean = extract10DigitPhone(mobile);
    if (clean.length < 10) return false;
    final syntheticEmail = phoneToEmail(clean);

    // 0. Fetch existing stored pass and email before updating
    String? oldPass;
    String? currentEmail;
    try {
      final snap = await FirebaseDatabase.instance.ref('users_by_phone').child(clean).get();
      if (snap.exists && snap.value is Map) {
        final val = snap.value as Map;
        oldPass = val['pass']?.toString();
        currentEmail = val['email']?.toString();
      }
    } catch (e) {
      debugPrint('[AuthService] error reading oldPass before update: $e');
    }

    // 1. Update in Firebase Auth:
    final current = FirebaseAuth.instance.currentUser;
    if (current != null) {
      // User is logged in (e.g. Settings screen)
      try {
        await current.updatePassword(newPassword);
        debugPrint('[AuthService] Successfully updated password on current logged-in user');
      } catch (e) {
        debugPrint('[AuthService] current.updatePassword error: $e');
      }
    } else {
      // User is not logged in (e.g. Forgot Password screen)
      // Sign in to the existing account using old password and update it to the new password
      final emailsToTry = <String>{
        syntheticEmail,
        if (currentEmail != null && currentEmail.isNotEmpty) currentEmail,
      };

      bool updatedInAuth = false;
      for (final em in emailsToTry) {
        if (oldPass != null && oldPass.isNotEmpty) {
          try {
            final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: em,
              password: oldPass,
            );
            await cred.user?.updatePassword(newPassword);
            updatedInAuth = true;
            debugPrint('[AuthService] Successfully updated Firebase Auth password for $em');
            await FirebaseAuth.instance.signOut();
            break;
          } catch (e) {
            debugPrint('[AuthService] signIn with oldPass failed for $em: $e');
          }
        }
      }

      // If existing account did not exist yet in Firebase Auth, create it once with the canonical synthetic email
      if (!updatedInAuth) {
        try {
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: syntheticEmail,
            password: newPassword,
          );
          await FirebaseAuth.instance.signOut();
          debugPrint('[AuthService] Created account $syntheticEmail in Firebase Auth with new password');
        } catch (e) {
          debugPrint('[AuthService] createUser for $syntheticEmail: $e');
        }
      }
    }

    // 2. Update in users_by_phone
    try {
      await FirebaseDatabase.instance.ref('users_by_phone').child(clean).update({
        'pass': newPassword,
        'mobile': clean,
        'email': syntheticEmail,
        'updatedAt': ServerValue.timestamp,
      });
      await cacheLocal(clean, syntheticEmail);
      debugPrint('[AuthService] Successfully updated pass in users_by_phone/$clean to $newPassword');
    } catch (e) {
      debugPrint('[AuthService] users_by_phone update error: $e');
    }

    // 3. Find UID and update in users node
    try {
      final snap = await FirebaseDatabase.instance.ref('users_by_phone').child(clean).get();
      String? uid;
      if (snap.exists && snap.value is Map) {
        uid = (snap.value as Map)['uid']?.toString();
      }
      if (uid != null && uid.isNotEmpty) {
        await FirebaseDatabase.instance.ref('users').child(uid).update({
          'pass': newPassword,
          'email': syntheticEmail,
          'updatedAt': ServerValue.timestamp,
        });
      } else if (FirebaseAuth.instance.currentUser != null) {
        // Query users by mobile only if authenticated
        final usersSnap = await FirebaseDatabase.instance.ref('users').get();
        if (usersSnap.exists && usersSnap.value is Map) {
          for (final entry in (usersSnap.value as Map).entries) {
            if (entry.value is Map) {
              final uMobile = normalizePhone(entry.value['mobile']?.toString() ?? entry.value['cleanMobile']?.toString() ?? '');
              if (uMobile == clean) {
                await FirebaseDatabase.instance.ref('users').child(entry.key.toString()).update({
                  'pass': newPassword,
                  'email': syntheticEmail,
                  'updatedAt': ServerValue.timestamp,
                });
                break;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[AuthService] users node password update error: $e');
    }

    return true;
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
