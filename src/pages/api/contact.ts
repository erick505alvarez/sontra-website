import type { APIRoute } from "astro";
import { Resend } from "resend";

if (!import.meta.env.RESEND_API_KEY) {
  console.error("Missing RESEND_API_KEY in environment variables.");
  throw new Error("RESEND_API_KEY is required");
}
if (!import.meta.env.RESEND_EMAIL_DOMAIN) {
  throw new Error("RESEND_EMAIL_DOMAIN is required");
}
const resend = new Resend(import.meta.env.RESEND_API_KEY);
const resend_domain = import.meta.env.RESEND_EMAIL_DOMAIN;
const target_inbox = import.meta.env.TARGET_INBOX;

export const POST: APIRoute = async (context) => {
  const { request } = context;
  const form = await request.formData();
  const name = form.get("name"); // Required
  const business_name = form.get("business_name");
  const phone_number = form.get("phone_number"); // Required
  const email = form.get("email");
  const message = form.get("message");

  // Prevent bots
  const honeypot = form.get("honeypot");
  if (honeypot) {
    return new Response("Bot detected", { status: 400 });
  }

  if (!name || !phone_number) {
    return new Response(
      JSON.stringify({ success: false, error: "Missing fields." }),
      { status: 400 }
    );
  }

  try {
    const response = await resend.emails.send({
      from: `sontra.dev <no-reply@${resend_domain}>`,
      to: `${target_inbox}`,
      subject: `New contact from ${name || "visitor"}`,
      html: `<p><strong>From:</strong> ${name} &lt;${email}&gt;</p>
      <p><strong>Business Name:</strong> ${business_name}</p>
      <p><strong>Phone Number:</strong> ${phone_number}</p>
      <p>${message}</p>`,
    });

    const { error } = response;
    if (error?.statusCode === 401 || error?.statusCode === 403) {
      console.error(
        `Authentication error ${error.statusCode}: ${error.message}`
      );
    }

    // Redirect to booking page after successful submission
    return new Response(null, {
      status: 302,
      headers: {
        Location: "/booking",
      },
    });
  } catch (err: any) {
    console.error(`Failed to send email: ${err}`);
    return new Response(
      JSON.stringify({ success: false, error: err.message }),
      { status: 500 }
    );
  }
};
