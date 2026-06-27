// Guardian Angel — "triage" Edge Function
//
// Proxies the Groq emergency-detection call so the API key NEVER ships in the
// app. The Flutter client calls THIS function with the public anon key; the
// Groq key lives only here as the GROQ_API_KEY secret.
//
// Behavior contract (kept identical to the old client-side AiService):
//   request : POST { "query": string, "lang"?: string }
//   response: { "id": string | null }   where id is one of VALID_IDS or null
//
// The client only calls this as a FALLBACK when local search finds no match,
// so this function is not on the hot path.

import { createClient } from "jsr:@supabase/supabase-js@2";

const GROQ_URL = "https://api.groq.com/openai/v1/chat/completions";
const MODEL = "llama-3.1-8b-instant";
const VALID_IDS = [
  "choking",
  "choking_infant",
  "cpr",
  "cpr_infant",
  "burns",
  "bleeding",
  "fractures",
  "seizures",
];

const SYSTEM_PROMPT = `You are an emergency triage assistant.
Given user input, respond with ONLY one of these exact IDs if it matches a medical emergency, or respond with ONLY the word "none" if it does not:
choking, choking_infant, cpr, cpr_infant, burns, bleeding, fractures, seizures

Rules:
- "infant" or "baby" or "newborn" → use the infant variant
- Respond with ONLY the ID or "none", nothing else
- If unsure, respond with "none"`;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ id: null, error: "method_not_allowed" }, 405);
  }

  const groqKey = Deno.env.get("GROQ_API_KEY");
  if (!groqKey) {
    // Misconfiguration — tell the client clearly so it can show a fallback.
    return json({ id: null, error: "ai_unconfigured" }, 503);
  }

  // ── Parse + sanitize input ──
  let query = "";
  let lang: string | null = null;
  try {
    const body = await req.json();
    query = (body?.query ?? "").toString().trim();
    lang = body?.lang ? body.lang.toString().slice(0, 8) : null;
  } catch (_) {
    return json({ id: null, error: "bad_request" }, 400);
  }
  if (!query) return json({ id: null });
  if (query.length > 500) query = query.slice(0, 500); // basic abuse guard

  // Analytics is anonymous for now (no user attribution) — also the most
  // privacy-preserving default. The admin client uses a service key: SERVICE_KEY
  // (the new secret key, sb_secret_...) is preferred; the legacy auto-injected
  // SUPABASE_SERVICE_ROLE_KEY is a fallback. On projects using the new API key
  // system the legacy key may be rejected, in which case set SERVICE_KEY.
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SERVICE_KEY") ??
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

  // ── Ask Groq ──
  const started = Date.now();
  let matched: string | null = null;
  try {
    const groqRes = await fetch(GROQ_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${groqKey}`,
      },
      body: JSON.stringify({
        model: MODEL,
        max_tokens: 20,
        temperature: 0.0,
        messages: [
          { role: "system", content: SYSTEM_PROMPT },
          { role: "user", content: query },
        ],
      }),
      signal: AbortSignal.timeout(8000),
    });
    if (groqRes.ok) {
      const data = await groqRes.json();
      const text = (data?.choices?.[0]?.message?.content ?? "")
        .toString()
        .trim()
        .toLowerCase();
      if (VALID_IDS.includes(text)) matched = text;
    }
  } catch (_) {
    return json({ id: null, error: "ai_upstream" }, 502);
  }
  const latency = Date.now() - started;

  // ── Best-effort, privacy-preserving analytics (service role bypasses RLS) ──
  // Raw text is stored ONLY when LOG_TRIAGE_INPUT === "true".
  try {
    if (!serviceKey) {
      console.error("triage analytics skipped: no service role key in env");
    } else {
      const admin = createClient(supabaseUrl, serviceKey, {
        auth: { persistSession: false },
      });
      const logInput = Deno.env.get("LOG_TRIAGE_INPUT") === "true";
      const { error: logErr } = await admin.from("ai_triage_logs").insert({
        matched_id: matched,
        query_length: query.length,
        lang,
        model: MODEL,
        latency_ms: latency,
        input_text: logInput ? query : null,
      });
      if (logErr) console.error("triage log insert failed:", logErr.message);
    }
  } catch (e) {
    // Never fail the request because analytics logging failed.
    console.error("triage log threw:", e instanceof Error ? e.message : e);
  }

  return json({ id: matched });
});
