import { create } from 'zustand';
import { persist } from 'zustand/middleware';

import i18n from '@/locales/i18n';

interface UIState {
  locale: 'uz' | 'ru' | 'en';
  sidebarCollapsed: boolean;
  setLocale: (l: UIState['locale']) => void;
  toggleSidebar: () => void;
}

export const useUIStore = create<UIState>()(
  persist(
    (set) => ({
      locale: 'uz',
      sidebarCollapsed: false,
      setLocale: (locale) => {
        set({ locale });
        i18n.changeLanguage(locale);
      },
      toggleSidebar: () => set((s) => ({ sidebarCollapsed: !s.sidebarCollapsed })),
    }),
    {
      name: 'nur-ui',
      onRehydrateStorage: () => (state) => {
        // Saqlangan tilni qayta yuklashda i18next bilan moslab qo'yamiz
        if (state?.locale) i18n.changeLanguage(state.locale);
      },
    },
  ),
);
