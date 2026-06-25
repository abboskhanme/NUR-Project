import { create } from 'zustand';
import { persist } from 'zustand/middleware';

/**
 * Harakatsizlik PIN-qulfi holati.
 *
 * `locked` localStorage'da saqlanadi — shu sabab sahifa yangilansa ham (refresh)
 * qulf saqlanib qoladi, ya'ni qulfni faqat to'g'ri PIN bilan ochish mumkin.
 */
interface PinLockState {
  locked: boolean;
  lock: () => void;
  unlock: () => void;
}

export const usePinLockStore = create<PinLockState>()(
  persist(
    (set) => ({
      locked: false,
      lock: () => set({ locked: true }),
      unlock: () => set({ locked: false }),
    }),
    { name: 'nur-pinlock' },
  ),
);
