/// Public Supabase project config — safe to ship in the client.
///
/// The anon key is *designed* to live in the app: every table is protected by
/// Row-Level Security, so it grants no data access on its own. The service-role
/// key, the Groq key, and the database password are NEVER placed here (the Groq
/// key lives only as a Supabase Edge Function secret).
///
/// Project: guardianangel-dev (org: GuardianAngel Dev).
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://vmnfflondnqrkfkgddzo.supabase.co';

  /// Modern publishable key (sb_publishable_...). Safe to commit and ship: it
  /// grants no data access on its own because every table is RLS-protected.
  static const String publishableKey =
      'sb_publishable_Zeo3JS7Qvk1PVP2kdrUIpQ_j4Lu81ny';
}
