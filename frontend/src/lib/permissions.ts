/**
 * Permission tizimi — backend bilan bir xil format.
 *
 * QO'SHIB BORISH:
 *   - Yangi modul: MODULES ro'yxatiga qo'shing
 *   - Yangi verb: VERBS ro'yxatiga qo'shing
 *   - Komponentda: const { can } = usePermissions(); {can('users:write') && <Btn/>}
 *   - Yoki: <Can perm="users:write"><Btn/></Can>
 *
 * WILDCARD'LAR:
 *   - "*"          — barchasi (super-admin)
 *   - "module:*"   — modul ichidagi hamma amal
 *   - "*:verb"     — barcha modullarning shu verb'i
 */
import { useMemo } from 'react';
import { useAuthStore } from '@/stores/auth';

export const MODULES = [
  'users', 'customers', 'orders', 'products', 'service',
  'finance', 'hr', 'supply', 'reports', 'telegram', 'settings',
] as const;

export const VERBS = ['read', 'write', 'delete', 'approve', 'export'] as const;

export const WILDCARD_ALL = '*:*';

export type Module = typeof MODULES[number];
export type Verb = typeof VERBS[number];

/** Foydalanuvchining ruxsatlarini barcha rollardan yig'ish. */
export function collectUserPermissions(user: {
  is_superadmin?: boolean;
  roles?: { name: string; permissions?: any }[];
} | null): Set<string> {
  const set = new Set<string>();
  if (!user) return set;
  for (const role of user.roles || []) {
    const data: any = role.permissions || {};
    const items = Array.isArray(data) ? data : data.permissions;
    if (!items) continue;
    for (const p of items) {
      if (typeof p === 'string') set.add(p);
    }
  }
  return set;
}

/** Foydalanuvchi belgilangan ruxsatga ega-yo'qligini tekshirish. */
export function hasPermission(
  user: { is_superadmin?: boolean; roles?: { name: string; permissions?: any }[] } | null,
  perm: string,
): boolean {
  if (!user) return false;
  if (user.is_superadmin) return true;
  if ((user.roles || []).some((r) => r.name === 'super_admin')) return true;

  const perms = collectUserPermissions(user);
  if (perms.size === 0) return false;

  if (perms.has(perm)) return true;
  if (perms.has('*') || perms.has(WILDCARD_ALL)) return true;

  if (!perm.includes(':')) return false;
  const [module, verb] = perm.split(':', 2);
  if (perms.has(`${module}:*`)) return true;
  if (perms.has(`*:${verb}`)) return true;
  return false;
}

/** Modulda kamida bitta ruxsat bormi (sidebar/sahifa ko'rinishi uchun). */
export function hasModuleAccess(
  user: { is_superadmin?: boolean; roles?: { name: string; permissions?: any }[] } | null,
  module: string,
): boolean {
  return VERBS.some((v) => hasPermission(user, `${module}:${v}`));
}

/** React hook — auth store'dan user oladi va helper'lar qaytaradi. */
export function usePermissions() {
  const user = useAuthStore((s) => s.user);

  return useMemo(() => {
    const isSuperadmin =
      !!user?.is_superadmin || (user?.roles ?? []).some((r) => r.name === 'super_admin');
    const all = collectUserPermissions(user);

    return {
      user,
      isSuperadmin,
      all,
      /** Bitta ruxsatni tekshirish */
      can: (perm: string) => hasPermission(user, perm),
      /** Kamida bittasi yetadi */
      canAny: (...perms: string[]) => perms.some((p) => hasPermission(user, p)),
      /** Barchasi majburiy */
      canAll: (...perms: string[]) => perms.every((p) => hasPermission(user, p)),
      /** Modulga umuman kirish bormi (kamida bitta verb) */
      canModule: (module: string) => hasModuleAccess(user, module),
    };
  }, [user]);
}
