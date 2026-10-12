/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_BASE_URL: string;
  // Second-brand overrides, see src/lib/brand.ts
  readonly VITE_BRAND_APP_NAME?: string;
  readonly VITE_BRAND_COMPANY?: string;
  readonly VITE_BRAND_INITIAL?: string;
  readonly VITE_BRAND_LOGO?: string;
  readonly VITE_BRAND_EMAIL?: string;
  readonly VITE_BRAND_PHONE?: string;
  readonly VITE_BRAND_SITE?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
