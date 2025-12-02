interface ImportMetaEnv {
  readonly RESEND_API_KEY: string;
  // More env variables...
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
