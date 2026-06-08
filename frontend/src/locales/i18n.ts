import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';

import uz from './uz.json';
import ru from './ru.json';
import en from './en.json';

// Modul tarjimalari: src/locales/modules/{namespace}.{uz|ru|en}.json
// Har bir fayl o'z namespace'i ostida avtomatik ulanadi: t('sales.xxx') va h.k.
const moduleFiles = import.meta.glob('./modules/*.json', { eager: true }) as Record<
  string,
  { default: Record<string, unknown> }
>;

const base: Record<'uz' | 'ru' | 'en', Record<string, unknown>> = {
  uz: { ...uz },
  ru: { ...ru },
  en: { ...en },
};

for (const [path, mod] of Object.entries(moduleFiles)) {
  const m = path.match(/\/([\w-]+)\.(uz|ru|en)\.json$/);
  if (!m) continue;
  const [, ns, lang] = m;
  base[lang as 'uz' | 'ru' | 'en'][ns] = mod.default ?? mod;
}

// Boshlang'ich tilni saqlangan UI sozlamasidan (nur-ui) o'qiymiz, bo'lmasa 'uz'.
function initialLng(): string {
  try {
    const raw = localStorage.getItem('nur-ui');
    const loc = raw ? JSON.parse(raw)?.state?.locale : null;
    if (loc === 'uz' || loc === 'ru' || loc === 'en') return loc;
  } catch {
    /* ignore */
  }
  return 'uz';
}

i18n
  .use(initReactI18next)
  .init({
    resources: {
      uz: { translation: base.uz },
      ru: { translation: base.ru },
      en: { translation: base.en },
    },
    lng: initialLng(),
    fallbackLng: 'uz',
    interpolation: { escapeValue: false },
  });

export default i18n;

