import type { APIRoute } from "astro";
import { Resend } from "resend";

if (!import.meta.env.RESEND_API_KEY) {
  console.error("Missing RESEND_API_KEY in environment variables.");
  throw new Error("RESEND_API_KEY is required");
}

const resend = new Resend(import.meta.env.RESEND_API_KEY);

export const POST: APIRoute = async (context) => {
  const { request } = context;
  const form = await request.formData();
  const name = form.get("name");
  const email = form.get("email");
  const phone_number = form.get("phone_number");
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
    await resend.emails.send({
      from: "sontra.dev <no-reply@contactsontra.dev>",
      to: "erickalvarez.official@gmail.com",
      subject: `New contact from ${name || "visitor"}`,
      html: `<p><strong>From:</strong> ${name} &lt;${email}&gt;</p><p><strong>Phone Number:</strong> ${phone_number}</p><p>${message}</p>`,
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
