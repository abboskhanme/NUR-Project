import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';

import uz from './uz.json';
import ru from './ru.json';
import en from './en.json';

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
      uz: { translation: uz },
      ru: { translation: ru },
      en: { translation: en },
    },
    lng: initialLng(),
    fallbackLng: 'uz',
    interpolation: { escapeValue: false },
  });

export default i18n;
