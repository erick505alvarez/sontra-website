// Src/pages/api/demo-call.ts
import type { APIRoute } from "astro";

const N8N_DEMO_CALL_WEBHOOK = import.meta.env.N8N_DEMO_CALL_WEBHOOK;

export const POST: APIRoute = async ({ request }) => {
  try {
    const body = await request.json();

    // Honeypot check
    if (body.website) {
      return new Response(
        JSON.stringify({ success: false, error: "Bot detected" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const { first_name, email, phone } = body;

    // Validate first_name
    if (
      !first_name ||
      typeof first_name !== "string" ||
      first_name.trim().length < 2
    ) {
      return new Response(
        JSON.stringify({ success: false, error: "Valid name required" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Validate email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!email || typeof email !== "string" || !emailRegex.test(email)) {
      return new Response(
        JSON.stringify({ success: false, error: "Valid email required" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Validate phone
    const phoneStr = typeof phone === "string" ? phone : "";
    const phoneDigits = phoneStr.replace(/\D/g, "");
    if (phoneDigits.length < 10 || phoneDigits.length > 11) {
      return new Response(
        JSON.stringify({ success: false, error: "Valid phone required" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Check webhook URL is configured
    if (!N8N_DEMO_CALL_WEBHOOK) {
      console.error("N8N_WEBHOOK_URL not configured");
      return new Response(
        JSON.stringify({ success: false, error: "Server configuration error" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    // Forward to n8n
    const n8nResponse = await fetch(N8N_DEMO_CALL_WEBHOOK, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        first_name: first_name.trim(),
        email: email.trim().toLowerCase(),
        phone: phoneStr,
      }),
    });

    if (!n8nResponse.ok) {
      const errorText = await n8nResponse.text();
      console.error("n8n request failed:", errorText);
      throw new Error("n8n request failed");
    }

    const result = await n8nResponse.json();
    return new Response(JSON.stringify({ success: true, ...result }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Demo call error:", error);
    return new Response(
      JSON.stringify({ success: false, error: "Something went wrong" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
};
