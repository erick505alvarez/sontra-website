// Src/pages/api/demo-call.ts
import type { APIRoute } from "astro";

const N8N_DEMO_CALL_WEBHOOK = import.meta.env.N8N_DEMO_CALL_WEBHOOK;

// Minimum time (ms) a human would take to fill the form
const MIN_SUBMISSION_TIME = 2000;
// Minimum interactions expected from a human
const MIN_INTERACTIONS = 3;

// Helper to create JSON responses
function jsonResponse(data: Record<string, unknown>, status: number): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

export const POST: APIRoute = async ({ request }) => {
  try {
    const body = await request.json();

    // Extract bot detection signals
    const timing = typeof body._timing === "number" ? body._timing : 0;
    const interactions =
      typeof body._interactions === "number" ? body._interactions : 0;

    // Honeypot check - bots often fill hidden fields
    if (body.website) {
      // Return fake success to not alert bots
      console.warn("Bot detected: honeypot filled");
      return jsonResponse({ success: true }, 200);
    }

    // Timing check - submissions faster than MIN_SUBMISSION_TIME are suspicious
    if (timing > 0 && timing < MIN_SUBMISSION_TIME) {
      // Return fake success to not alert bots
      console.warn(`Bot detected: fast submission (${timing}ms)`);
      return jsonResponse({ success: true }, 200);
    }

    // Interaction check - too few interactions suggests automation
    if (interactions < MIN_INTERACTIONS) {
      // Return fake success to not alert bots
      console.warn(`Bot detected: low interactions (${interactions})`);
      return jsonResponse({ success: true }, 200);
    }

    const { first_name, email, phone } = body;

    // Validate first_name
    if (
      !first_name ||
      typeof first_name !== "string" ||
      first_name.trim().length < 2
    ) {
      return jsonResponse(
        { success: false, error: "Valid name required" },
        400
      );
    }

    // Additional name validation - must contain only letters, spaces, hyphens, apostrophes
    const nameRegex = /^[a-zA-Z\s'-]+$/;
    if (!nameRegex.test(first_name.trim())) {
      return jsonResponse(
        { success: false, error: "Valid name required" },
        400
      );
    }

    // Validate email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!email || typeof email !== "string" || !emailRegex.test(email)) {
      return jsonResponse(
        { success: false, error: "Valid email required" },
        400
      );
    }

    // Validate phone
    const phoneStr = typeof phone === "string" ? phone : "";
    const phoneDigits = phoneStr.replace(/\D/g, "");
    if (phoneDigits.length < 10 || phoneDigits.length > 11) {
      return jsonResponse(
        { success: false, error: "Valid phone required" },
        400
      );
    }

    // Check webhook URL is configured
    if (!N8N_DEMO_CALL_WEBHOOK) {
      console.error("N8N_DEMO_CALL_WEBHOOK not configured");
      return jsonResponse(
        { success: false, error: "Server configuration error" },
        500
      );
    }

    // Forward to n8n
    const n8nResponse = await fetch(N8N_DEMO_CALL_WEBHOOK, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        first_name: first_name.trim(),
        email: email.trim().toLowerCase(),
        phone: phoneDigits,
      }),
    });

    if (!n8nResponse.ok) {
      const errorText = await n8nResponse.text();
      console.error("n8n request failed:", errorText);
      throw new Error("n8n request failed");
    }

    const result = await n8nResponse.json();
    return jsonResponse({ success: true, ...result }, 200);
  } catch (error) {
    console.error("Demo call error:", error);
    return jsonResponse({ success: false, error: "Something went wrong" }, 500);
  }
};
