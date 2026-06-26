import 'supabase_service.dart';

/// Thrown when the AI triage proxy cannot be reached (no internet, Supabase not
/// initialized, timeout, or upstream error). Callers should treat this as
/// "AI unavailable" and show an offline fallback — distinct from a successful
/// call that simply found no match (which returns null).
class TriageUnreachable implements Exception {
  const TriageUnreachable();
}

/// Emergency detection via the Supabase `triage` Edge Function.
///
/// The Groq API key is NOT in the app — the function holds it server-side and
/// this client only talks to Supabase. The contract is unchanged from the old
/// direct-to-Groq implementation: returns a valid protocol id, or null when
/// there is no confident match. Network/availability failures throw
/// [TriageUnreachable] so the UI can show a clear offline message.
class AiService {
  AiService._();

  static const _validIds = [
    'choking',
    'choking_infant',
    'cpr',
    'cpr_infant',
    'burns',
    'bleeding',
    'fractures',
    'seizures',
  ];

  /// Returns a protocol id when the proxy confidently matches one, else null.
  /// Throws [TriageUnreachable] when the proxy can't be reached.
  static Future<String?> detectEmergency(
    String userInput, {
    String? lang,
  }) async {
    final query = userInput.trim();
    if (query.isEmpty) return null;

    // Offline-first: if Supabase never initialized there is no point trying.
    if (!SupabaseService.isReady) throw const TriageUnreachable();

    final dynamic data;
    try {
      final res = await SupabaseService.client.functions
          .invoke(
            'triage',
            body: {'query': query, if (lang != null) 'lang': lang},
          )
          .timeout(const Duration(seconds: 8));
      data = res.data;
    } catch (e, stack) {
      assert(() {
        // ignore: avoid_print
        print('AI triage unreachable: $e');
        // ignore: avoid_print
        print('AI triage stack: $stack');
        return true;
      }());
      throw const TriageUnreachable();
    }

    final id = (data is Map ? data['id'] : null)
        ?.toString()
        .trim()
        .toLowerCase();
    if (id == null || !_validIds.contains(id)) return null;
    return id;
  }
}
