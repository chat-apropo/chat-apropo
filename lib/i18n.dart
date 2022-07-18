import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Set<String> i18nKeys = {};
Map<String, Map<String, String>> i18nFileMap = {};
Map<String, String>? i18nMap = {};

// Function applied to keys
String simplifyKey(String key) {
  return key.replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
}

/// Loads json files into assets/i18n
Future i18nLoad() async {
  var assets = await rootBundle.loadString('AssetManifest.json');
  var assetsMap = json.decode(assets);
  // Filter only *.json files inside i18n directory
  List i18nfiles = assetsMap.keys.where((key) => key.contains('i18n/') && key.endsWith(".json")).toList();
  for (var i18nfile in i18nfiles) {
    debugPrint("Loading i18n file: $i18nfile");
    final file = await rootBundle.loadString(i18nfile);
    final Map<String, dynamic> map = json.decode(file);
    try {
      var stringMap = map.cast<String, String>();
      // Simplify keys
      stringMap = stringMap.map((key, value) => MapEntry(simplifyKey(key), value));

      final fileKey = i18nfile.split("/").last.split(".").first;
      i18nFileMap[fileKey] = stringMap;

    } catch (e) {
      debugPrint("No translation found. Need to add: $i18nfile");
      debugPrint(e.toString());
      continue;
    }
  }
}

void i18nSetLanguage(String isoCode) {
  debugPrint("Setting language to $isoCode");
  i18nMap = i18nFileMap[isoCode];
}

extension Translation on String {
  String get i18n {
    i18nKeys.add(toLowerCase());
    return i18nMap?[simplifyKey(this)] ?? this;
  }
}
