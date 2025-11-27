import type { APIRoute } from "astro";
import { Resend } from "resend";

const { RESEND_API_KEY } = import.meta.env;
const resend = new Resend(RESEND_API_KEY);

export const POST: APIRoute = async ({ request }) => {
  const data = await request.formData();
  const email = data.get("email");
  const message = data.get("message");

  await resend.emails.send({
    from: "Site Contact Form <no-reply@yourdomain.com>",
    to: "you@yourdomain.com",
    subject: "New Contact Form Submission",
    html: `<p>Email: ${email}</p><p>Message: ${message}</p>`,
  });

  return new Response(JSON.stringify({ success: true }), { status: 200 });
};
