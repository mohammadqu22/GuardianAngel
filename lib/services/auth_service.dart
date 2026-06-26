import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Optional authentication.
///
/// The app is fully usable while signed out — emergency features NEVER require
/// an account. Auth exists only to unlock optional cloud sync (Phase 1.1). All
/// getters degrade safely when Supabase is unavailable.
class AuthService {
  AuthService._();

  static bool get isSignedIn =>
      SupabaseService.isReady &&
      SupabaseService.client.auth.currentUser != null;

  static User? get currentUser =>
      SupabaseService.isReady ? SupabaseService.client.auth.currentUser : null;

  /// Emits on sign-in / sign-out. Null when Supabase never initialized.
  static Stream<AuthState>? get onAuthStateChange => SupabaseService.isReady
      ? SupabaseService.client.auth.onAuthStateChange
      : null;

  static Future<AuthResponse> signInWithEmail(String email, String password) =>
      SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

  static Future<AuthResponse> signUpWithEmail(String email, String password) =>
      SupabaseService.client.auth.signUp(email: email, password: password);

  static Future<void> signOut() => SupabaseService.client.auth.signOut();
}
