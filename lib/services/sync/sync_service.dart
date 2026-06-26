import '../auth_service.dart';
import '../supabase_service.dart';

/// What can optionally sync to Supabase. Each maps to a table in
/// migration 0001 and a local store in lib/services/database_service.dart.
enum Syncable {
  userSettings,
  emergencyContacts,
  incidentLogs,
  learningProgress,
  quizProgress,
}

/// Offline-first cloud-sync scaffold — **Phase 1: structure only**.
///
/// The on-device SQLite DB + SharedPreferences remain the source of truth, so
/// every core emergency feature works with no internet. When the user is signed
/// in AND online, these syncables mirror to Supabase.
///
/// The push/pull + conflict-resolution logic is intentionally NOT implemented
/// yet — this only defines the contract so the data layer is ready without
/// overbuilding. Planned approach (Phase 1.1): last-write-wins on `updated_at`,
/// plus a one-time import of existing local data on first login.
class SyncService {
  SyncService._();

  /// True only when sync can run right now (Supabase ready + signed in).
  static bool get canSync => SupabaseService.isReady && AuthService.isSignedIn;

  // TODO(phase-1.1): push local rows changed since the last sync.
  //   static Future<void> pushLocal(Syncable s) async { ... }

  // TODO(phase-1.1): pull remote rows and merge (last-write-wins on updated_at).
  //   static Future<void> pullRemote(Syncable s) async { ... }

  // TODO(phase-1.1): one-time migration of existing local data into the account
  // the first time a user signs in.
  //   static Future<void> importLocalIntoAccount() async { ... }
}
