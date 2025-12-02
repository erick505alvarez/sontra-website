interface ImportMetaEnv {
  readonly RESEND_API_KEY: string;
  readonly RESEND_EMAIL_DOMAIN: string;
  readonly TARGET_INBOX: string;
  // More env variables...
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
