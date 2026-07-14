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
  'users', 'customers', 'orders', 'products', 'inventory', 'production', 'service',
  'finance', 'hr', 'supply_ichki', 'supply_tashqi', 'reports', 'telegram', 'debts', 'targets',
  'leads', 'shipping', 'settings',
] as const;

export const VERBS = ['read', 'write', 'delete', 'approve', 'export'] as const;

export const WILDCARD_ALL = '*:*';

/**
 * Maxsus (super-admin darajasidagi) ruxsatlar — modul:verb matritsasidan tashqarida.
 * Avval faqat super-admin qila olardi; endi rolga ANIQ biriktirilsa, shu rol egasi ham qila oladi.
 * DIQQAT: oddiy "*"/"*:*" wildcard bularni bermaydi — aniq berilishi shart (yoki "system:*").
 * Backend bilan bir xil (app/core/permissions.py · SPECIAL_PERMISSIONS).
 */
export const SPECIAL_PERMISSIONS = [
  { key: 'system:roles',            label: 'Rollar va ruxsatlarni boshqarish',     danger: false },
  { key: 'system:grant_superadmin', label: 'Boshqaga super-admin huquqini berish', danger: true },
  { key: 'system:user_delete',      label: "Foydalanuvchini butunlay o'chirish",    danger: true },
  { key: 'system:user_password',    label: 'Foydalanuvchi parolini almashtirish',   danger: false },
  { key: 'system:user_avatar',      label: 'Foydalanuvchi rasmini boshqarish',      danger: false },
  { key: 'system:finance_override', label: 'Oylikdan ortiq avans berish',           danger: true },
  { key: 'system:order_override',   label: 'Buyurtma ID/sotuvchisini tahrirlash',   danger: false },
  { key: 'system:goals_manage',     label: 'Oylik maqsadlarni (sotuv/tushum) belgilash', danger: false },
] as const;

export const SYSTEM_WILDCARD = 'system:*';
export const SPECIAL_PERMISSION_KEYS: ReadonlySet<string> = new Set(
  SPECIAL_PERMISSIONS.map((p) => p.key),
);

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

/**
 * Maxsus (super-admin darajasidagi) ruxsatni tekshirish.
 * `hasPermission`'dan farqi: oddiy "*"/"*:*" wildcard YETMAYDI — aniq shu ruxsat
 * yoki "system:*" berilgan bo'lishi kerak (yoki haqiqiy super-admin).
 */
export function hasSpecialPermission(
  user: { is_superadmin?: boolean; roles?: { name: string; permissions?: any }[] } | null,
  perm: string,
): boolean {
  if (!user) return false;
  if (user.is_superadmin) return true;
  if ((user.roles || []).some((r) => r.name === 'super_admin')) return true;
  const perms = collectUserPermissions(user);
  return perms.has(perm) || perms.has(SYSTEM_WILDCARD);
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
      /** Maxsus (super-admin darajasidagi) ruxsat — "*" wildcard yetmaydi */
      canSpecial: (perm: string) => hasSpecialPermission(user, perm),
    };
  }, [user]);
}
