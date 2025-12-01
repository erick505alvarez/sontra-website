import { defineMiddleware } from "astro:middleware";

// Very simple in-memory rate limiter
const requests = new Map<string, { count: number; time: number }>();

const LIMIT = 100;

export const onRequest = defineMiddleware(async (context, next) => {
  const { request } = context;
  const ip =
    request.headers.get("x-forwarded-for") ||
    request.headers.get("cf-connecting-ip") ||
    "local";

  const now = Date.now();
  const record = requests.get(ip) || { count: 0, time: now };

  if (now - record.time < 60_000) {
    // Within 1 minute window
    record.count++;

    if (record.count > LIMIT) {
      return new Response("Too many requests", { status: 429 });
    }
  } else {
    // Reset window
    record.count = 1;
    record.time = now;
  }

  requests.set(ip, record);

  return next();
});

export default { onRequest };
