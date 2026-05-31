import { create } from 'zustand';
import { persist } from 'zustand/middleware';

export interface User {
  id: string;
  email: string;
  full_name: string;
  phone?: string | null;
  avatar_url?: string | null;
  position?: string | null;
  locale: string;
  theme: string;
  is_active: boolean;
  is_superadmin: boolean;
  roles: { id: string; name: string; description?: string | null; permissions: Record<string, any> }[];
}

interface AuthState {
  user: User | null;
  accessToken: string | null;
  refreshToken: string | null;
  setAuth: (user: User, access: string, refresh: string) => void;
  setTokens: (access: string, refresh: string) => void;
  setUser: (u: User) => void;
  logout: () => void;
  hasRole: (...roleNames: string[]) => boolean;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      user: null,
      accessToken: null,
      refreshToken: null,
      setAuth: (user, access, refresh) =>
        set({ user, accessToken: access, refreshToken: refresh }),
      setTokens: (access, refresh) => set({ accessToken: access, refreshToken: refresh }),
      setUser: (u) => set({ user: u }),
      logout: () => set({ user: null, accessToken: null, refreshToken: null }),
      hasRole: (...names) => {
        const u = get().user;
        if (!u) return false;
        if (u.is_superadmin) return true;
        const own = new Set(u.roles.map((r) => r.name));
        return names.some((n) => own.has(n));
      },
    }),
    { name: 'nur-auth' },
  ),
);
