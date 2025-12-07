// Scripts/check-env.js
import { access } from "node:fs";

const requiredSecrets = [
  "RESEND_API_KEY",
  "RESEND_EMAIL_DOMAIN",
  "TARGET_INBOX",
];

const missing = requiredSecrets.filter((key) => !process.env[key]);

if (missing.length > 0) {
  console.error(`
  ❌ CRITICAL ERROR: STARTUP FAILED
  ---------------------------------
  The following required environment variables are missing:
  ${missing.map((key) => `   - ${key}`).join("\n")}
  
  The application cannot start without these secrets.
  `);
  process.exit(1); // Exit with error code to crash the container
}

console.log("✅ All required secrets are present. Starting Server...");
