import 'dart:convert';

import 'package:flutter/services.dart';

/// Thrown when no protocol asset could be loaded for an emergency id.
class ProtocolLoadException implements Exception {}

/// Thrown when a protocol asset exists but its JSON is malformed or has no steps.
class ProtocolFormatException implements Exception {}

/// Loads the emergency protocol JSON bundled under assets/data/.
///
/// Shared by the emergency step flow and the learning flow so both apply the
/// same locale fallback: try `assets/data/{locale}/{id}.json` first, then the
/// English file at `assets/data/{id}.json`.
class ProtocolLoader {
  ProtocolLoader._();

  static Future<Map<String, dynamic>> load(
    String emergencyId,
    String localeCode, {
    AssetBundle? bundle,
  }) async {
    final assets = bundle ?? rootBundle;
    String? data;

    if (localeCode != 'en') {
      try {
        data = await assets.loadString(
          'assets/data/$localeCode/$emergencyId.json',
        );
      } catch (_) {
        // locale file missing — fall back to English below
      }
    }

    try {
      data ??= await assets.loadString('assets/data/$emergencyId.json');
    } catch (_) {
      throw ProtocolLoadException();
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      throw ProtocolFormatException();
    }

    final steps = json['steps'];
    if (steps is! List || steps.isEmpty) {
      throw ProtocolFormatException();
    }
    return json;
  }
}
