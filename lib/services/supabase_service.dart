import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

/// Thin wrapper around Supabase initialization.
///
/// Startup stays **offline-first**: if init fails (no network, bad config) the
/// app keeps working and online-only features degrade gracefully. Always guard
/// online calls with [isReady] (or let [AiService] surface a clear fallback).
class SupabaseService {
  SupabaseService._();

  static bool _ready = false;

  /// True once Supabase has initialized successfully this session.
  static bool get isReady => _ready;

  /// Initializes Supabase. Never throws — failures leave [isReady] false so the
  /// rest of the app continues to work without a backend.
  static Future<void> init() async {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.publishableKey,
      );
      _ready = true;
    } catch (e) {
      _ready = false;
      assert(() {
        // ignore: avoid_print
        print('Supabase init failed (continuing offline): $e');
        return true;
      }());
    }
  }

  /// The shared client. Only access after confirming [isReady].
  static SupabaseClient get client => Supabase.instance.client;
}
