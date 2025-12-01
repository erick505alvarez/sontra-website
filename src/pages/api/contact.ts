import type { APIRoute } from "astro";
import { Resend } from "resend";

const resend = new Resend(process.env.RESEND_API_KEY || "");

export const POST: APIRoute = async ({ request }) => {
  const form = await request.formData();
  const name = form.get("name");
  const email = form.get("email");
  const message = form.get("message");

  // Prevent bots
  const honeypot = form.get("honeypot");
  if (honeypot) {
    return new Response("Bot detected", { status: 400 });
  }

  if (!email || !message) {
    return new Response(
      JSON.stringify({ success: false, error: "Missing fields." }),
      { status: 400 }
    );
  }

  try {
    await resend.emails.send({
      from: "Site <no-reply@yourdomain.com>",
      to: "you@yourdomain.com",
      subject: `New contact from ${name || "visitor"}`,
      html: `<p><strong>From:</strong> ${name} &lt;${email}&gt;</p><p>${message}</p>`,
    });

    // Redirect to booking page after successful submission
    return new Response(null, {
      status: 302,
      headers: {
        Location: "/booking",
      },
    });
  } catch (err: any) {
    return new Response(
      JSON.stringify({ success: false, error: err.message }),
      { status: 500 }
    );
  }
};
