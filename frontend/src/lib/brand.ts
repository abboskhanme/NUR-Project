// Brand shown in the UI. The defaults are NUR's; a second instance of the
// system (docker-compose.brand2.yml) overrides them at build time through
// VITE_BRAND_* build args. An empty value falls back to the default.

const env = import.meta.env;

const appName = env.VITE_BRAND_APP_NAME || 'NUR Project';

export const BRAND = {
  /** Product name: login page, sidebar, browser tab. */
  appName,
  /** Company name: top bar, dashboard, receipt, legal pages. */
  company: env.VITE_BRAND_COMPANY || 'NUR TECHNO GROUP',
  /** Letter in the square logo badge. */
  initial: (env.VITE_BRAND_INITIAL || appName.trim()[0] || 'N').toUpperCase(),
  /** Receipt logo under /public; "none" prints the company name instead. */
  logo: env.VITE_BRAND_LOGO || '/nur-logo.jpg',
  email: env.VITE_BRAND_EMAIL || 'info@nurtechnogroup.uz',
  phone: env.VITE_BRAND_PHONE || '+998 97 666 26 75',
  site: env.VITE_BRAND_SITE || 'www.nurtechnogroup.uz',
};
