import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Strings extends ChangeNotifier {
  static final Strings instance = Strings._();
  Strings._();

  static const _prefKey = 'app_lang';
  String lang = 'en';
  final Map<String, Map<String, String>> _data = {};

  Future<void> load() async {
    for (final code in const ['en', 'hi', 'gu']) {
      final raw = await rootBundle.loadString('assets/l10n/$code.json');
      _data[code] = Map<String, String>.from(json.decode(raw) as Map);
    }
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved == 'hi' || saved == 'gu' || saved == 'en') {
      lang = saved!;
    }
    notifyListeners();
  }

  String t(String key) {
    final value = _data[lang]?[key] ?? _data['en']?[key];
    if (value == null || value.isEmpty) return key;
    return value;
  }

  Future<void> setLang(String code) async {
    lang = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, code);
    notifyListeners();
  }
}

String s(String key) => Strings.instance.t(key);
