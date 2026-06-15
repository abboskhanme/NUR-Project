import { useEffect, useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import toast from 'react-hot-toast';
import {
  X, Check, ShieldCheck, Sparkles,
  Users, ShoppingCart, Package, Warehouse, Wrench, Wallet,
  UserSquare2, Truck, BarChart3, Settings, Send, UserCog, Coins, PackageOpen,
} from 'lucide-react';
import type { LucideIcon } from 'lucide-react';
import { api } from '@/api/client';
import { MODULES, VERBS, type Module, type Verb } from '@/lib/permissions';

export interface RoleRow {
  id: string;
  name: string;
  description?: string | null;
  permissions?: Record<string, any>;
}

const MODULE_ICONS: Record<Module, LucideIcon> = {
  users: UserCog,
  customers: Users,
  orders: ShoppingCart,
  products: Package,
  inventory: Warehouse,
  service: Wrench,
  finance: Wallet,
  hr: UserSquare2,
  supply: Truck,
  reports: BarChart3,
  telegram: Send,
  debts: Coins,
  shipping: PackageOpen,
  settings: Settings,
};

/** Saqlangan permissions ro'yxatini matritsa holatiga ochish. */
function parsePermissions(raw: any): { full: boolean; set: Set<string> } {
  const items: string[] = Array.isArray(raw) ? raw : raw?.permissions ?? [];
  const set = new Set<string>();
  let full = false;
  for (const p of items) {
    if (typeof p !== 'string') continue;
    if (p === '*' || p === '*:*') { full = true; continue; }
    const [m, v] = p.split(':');
    if (m && v === '*') { VERBS.forEach((vb) => set.add(`${m}:${vb}`)); continue; }
    if (m === '*' && v) { MODULES.forEach((mod) => set.add(`${mod}:${v}`)); continue; }
    if (m && v) set.add(p);
  }
  return { full, set };
}

/** Matritsa holatini ixcham permissions ro'yxatiga yig'ish. */
function serializePermissions(full: boolean, set: Set<string>): string[] {
  if (full) return ['*'];
  const out: string[] = [];
  for (const m of MODULES) {
    const checked = VERBS.filter((v) => set.has(`${m}:${v}`));
    if (checked.length === 0) continue;
    if (checked.length === VERBS.length) out.push(`${m}:*`);
    else checked.forEach((v) => out.push(`${m}:${v}`));
  }
  return out;
}

export default function RoleModal({
  role, onClose, onSaved,
}: {
  role: RoleRow | null; // null => create
  onClose: () => void;
  onSaved: () => void;
}) {
  const { t } = useTranslation();
  const isCreate = role === null;
  const isSuperAdminRole = role?.name === 'super_admin';

  const [name, setName] = useState(role?.name ?? '');
  const [description, setDescription] = useState(role?.description ?? '');
  const [saving, setSaving] = useState(false);

  const initial = useMemo(() => parsePermissions(role?.permissions), [role]);
  const [full, setFull] = useState(isSuperAdminRole || initial.full);
  const [perms, setPerms] = useState<Set<string>>(initial.set);

  const moduleLabels: Record<Module, string> = {
    users: t('nav.users', { defaultValue: 'Foydalanuvchilar' }),
    customers: t('nav.customers'),
    orders: t('nav.sales'),
    products: t('nav.products'),
    inventory: t('nav.warehouse', { defaultValue: 'Ombor' }),
    service: t('nav.service'),
    finance: t('nav.finance'),
    hr: t('nav.hr'),
    supply: t('nav.supply'),
    reports: t('nav.reports'),
    telegram: 'Telegram',
    debts: t('nav.debts', { defaultValue: 'Qarzlar' }),
    shipping: t('nav.shipping', { defaultValue: 'Yuk chiqarish' }),
    settings: t('nav.settings'),
  };

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  function toggle(m: Module, v: Verb) {
    setPerms((prev) => {
      const next = new Set(prev);
      const key = `${m}:${v}`;
      if (next.has(key)) {
        next.delete(key);
      } else {
        next.add(key);
        if (v !== 'read') next.add(`${m}:read`);
      }
      return next;
    });
  }

  function setRow(m: Module, mode: 'none' | 'view' | 'full') {
    setPerms((prev) => {
      const next = new Set(prev);
      VERBS.forEach((v) => next.delete(`${m}:${v}`));
      if (mode === 'view') next.add(`${m}:read`);
      if (mode === 'full') VERBS.forEach((v) => next.add(`${m}:${v}`));
      return next;
    });
  }

  function rowMode(m: Module): 'none' | 'view' | 'full' | 'custom' {
    const checked = VERBS.filter((v) => perms.has(`${m}:${v}`));
    if (checked.length === 0) return 'none';
    if (checked.length === VERBS.length) return 'full';
    if (checked.length === 1 && checked[0] === 'read') return 'view';
    return 'custom';
  }

  const activeModules = MODULES.filter((m) => VERBS.some((v) => perms.has(`${m}:${v}`))).length;

  async function save() {
    if (name.trim().length < 2) {
      toast.error(t('users.roles.nameMinLength'));
      return;
    }
    setSaving(true);
    const payload = {
      name: name.trim(),
      description: description.trim() || null,
      permissions: { permissions: serializePermissions(full, perms) },
    };
    try {
      if (isCreate) {
        await api.post('/users/roles', payload);
        toast.success(t('users.roles.createdSuccess'));
      } else {
        await api.patch(`/users/roles/${role!.id}`, payload);
        toast.success(t('common.updated'));
      }
      onSaved();
      onClose();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || t('common.error'));
    } finally {
      setSaving(false);
    }
  }

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/45 backdrop-blur-[2px] p-4 role-modal-backdrop"
      onClick={onClose}
    >
      <style>{`
        @keyframes roleModalFade { from { opacity: 0 } to { opacity: 1 } }
        @keyframes roleModalPop {
          from { opacity: 0; transform: translateY(10px) scale(.985) }
          to   { opacity: 1; transform: translateY(0) scale(1) }
        }
        .role-modal-backdrop { animation: roleModalFade .16s ease-out }
        .role-modal-panel { animation: roleModalPop .2s cubic-bezier(.16,1,.3,1) }
      `}</style>

      <div
        className="role-modal-panel bg-card rounded-xl shadow-2xl w-full max-w-3xl max-h-[92vh] flex flex-col overflow-hidden"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-black/5 shrink-0">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-lg bg-primary/10 text-primary flex items-center justify-center">
              <ShieldCheck size={18} />
            </div>
            <div>
              <h3 className="font-semibold leading-tight">
                {isCreate ? t('users.roles.newTitle') : t('users.roles.editTitle')}
              </h3>
              <p className="text-xs text-ink-soft">
                {full || isSuperAdminRole
                  ? t('perm.allEnabled', { defaultValue: "Barcha modullar — to'liq ruxsat" })
                  : t('perm.activeCount', {
                      defaultValue: '{{count}} ta modulga ruxsat berilgan',
                      count: activeModules,
                    })}
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-2 rounded-lg text-ink/40 hover:text-ink hover:bg-black/5 transition-colors"
          >
            <X size={18} />
          </button>
        </div>

        {/* Body */}
        <div className="px-6 py-5 space-y-5 overflow-y-auto">
          {/* Name / Description */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="label">{t('users.roles.nameLabel')}</label>
              <input
                className="input"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder={t('users.roles.namePlaceholder')}
                disabled={isSuperAdminRole}
              />
              <p className="text-[11px] text-ink-soft mt-1">
                {t('users.roles.nameHint')}
              </p>
            </div>
            <div>
              <label className="label">{t('users.roles.descLabel')}</label>
              <input
                className="input"
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder={t('users.roles.descPlaceholder')}
              />
            </div>
          </div>

          {/* Full access switch */}
          <div className="flex items-center justify-between gap-4 rounded-xl border border-black/[0.06] bg-black/[0.02] px-4 py-3.5">
            <div className="flex items-center gap-3 min-w-0">
              <div className="w-8 h-8 rounded-lg bg-warning/15 text-warning flex items-center justify-center shrink-0">
                <Sparkles size={16} />
              </div>
              <div className="min-w-0">
                <div className="text-sm font-medium">
                  {t('perm.fullAccess', { defaultValue: "Barcha modullarga to'liq ruxsat" })}
                </div>
                <div className="text-xs text-ink-soft truncate">
                  {isSuperAdminRole
                    ? t('perm.superAdminNote', {
                        defaultValue: "super_admin har doim to'liq ruxsatga ega.",
                      })
                    : t('perm.fullAccessHint', {
                        defaultValue: 'Yoqilsa, quyidagi matritsa inobatga olinmaydi.',
                      })}
                </div>
              </div>
            </div>
            <button
              type="button"
              role="switch"
              aria-checked={full}
              disabled={isSuperAdminRole}
              onClick={() => setFull((f) => !f)}
              className={
                'relative w-11 h-6 rounded-full shrink-0 transition-colors duration-200 ' +
                (full ? 'bg-primary' : 'bg-black/15 hover:bg-black/20') +
                (isSuperAdminRole ? ' opacity-60 cursor-not-allowed' : '')
              }
            >
              <span
                className={
                  'absolute top-0.5 left-0.5 w-5 h-5 rounded-full bg-white shadow-sm transition-transform duration-200 ' +
                  (full ? 'translate-x-5' : 'translate-x-0')
                }
              />
            </button>
          </div>

          {/* Matrix or full-access banner */}
          {full || isSuperAdminRole ? (
            <div className="flex items-center gap-3 rounded-xl bg-success/10 text-success px-4 py-3.5 text-sm font-medium">
              <Check size={16} strokeWidth={3} />
              {t('perm.allEnabledLong', {
                defaultValue: 'Barcha modullar uchun barcha amallar yoqilgan.',
              })}
            </div>
          ) : (
            <div className="rounded-xl border border-black/[0.06] overflow-hidden">
              <div className="overflow-x-auto">
                <table className="w-full text-sm border-separate border-spacing-0">
                  <thead>
                    <tr className="bg-black/[0.025]">
                      <th className="text-left text-[11px] font-semibold uppercase tracking-wider text-ink/40 py-2.5 pl-4 pr-2">
                        {t('perm.module', { defaultValue: 'Modul' })}
                      </th>
                      <th className="text-left text-[11px] font-semibold uppercase tracking-wider text-ink/40 py-2.5 px-2">
                        {t('perm.quick', { defaultValue: 'Tezkor tanlov' })}
                      </th>
                      {VERBS.map((v) => (
                        <th
                          key={v}
                          className="text-center text-[11px] font-semibold uppercase tracking-wider text-ink/40 py-2.5 px-1.5 whitespace-nowrap"
                        >
                          {t(`perm.verbs.${v}`, { defaultValue: v })}
                        </th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {MODULES.map((m, idx) => {
                      const mode = rowMode(m);
                      const Icon = MODULE_ICONS[m];
                      const rowActive = mode !== 'none';
                      return (
                        <tr
                          key={m}
                          className={
                            'group transition-colors duration-150 hover:bg-primary/[0.03] ' +
                            (idx !== MODULES.length - 1 ? '[&>td]:border-b [&>td]:border-black/[0.05]' : '')
                          }
                        >
                          {/* Module name */}
                          <td className="py-2 pl-4 pr-2 whitespace-nowrap">
                            <div className="flex items-center gap-2.5">
                              <div
                                className={
                                  'w-7 h-7 rounded-lg flex items-center justify-center transition-colors duration-200 ' +
                                  (rowActive
                                    ? 'bg-primary/10 text-primary'
                                    : 'bg-black/[0.04] text-ink/35')
                                }
                              >
                                <Icon size={14} />
                              </div>
                              <span
                                className={
                                  'font-medium transition-colors duration-200 ' +
                                  (rowActive ? 'text-ink' : 'text-ink/45')
                                }
                              >
                                {moduleLabels[m]}
                              </span>
                            </div>
                          </td>

                          {/* Segmented control */}
                          <td className="py-2 px-2 whitespace-nowrap">
                            <div className="inline-flex rounded-lg bg-black/[0.05] p-0.5">
                              {([
                                ['none', t('perm.none', { defaultValue: "Yo'q" })],
                                ['view', t('perm.view', { defaultValue: "Ko'rish" })],
                                ['full', t('perm.full', { defaultValue: "To'liq" })],
                              ] as const).map(([key, label]) => (
                                <button
                                  key={key}
                                  type="button"
                                  onClick={() => setRow(m, key)}
                                  className={
                                    'px-2.5 py-1 rounded-[7px] text-[11px] font-medium transition-all duration-150 ' +
                                    (mode === key
                                      ? 'bg-white text-ink shadow-sm'
                                      : 'text-ink/45 hover:text-ink/75')
                                  }
                                >
                                  {label}
                                </button>
                              ))}
                            </div>
                          </td>

                          {/* Verb checkboxes */}
                          {VERBS.map((v) => {
                            const on = perms.has(`${m}:${v}`);
                            return (
                              <td key={v} className="py-2 px-1.5 text-center">
                                <button
                                  type="button"
                                  aria-pressed={on}
                                  onClick={() => toggle(m, v)}
                                  className={
                                    'inline-flex items-center justify-center w-[22px] h-[22px] rounded-md border align-middle transition-all duration-150 ' +
                                    (on
                                      ? 'bg-primary border-primary text-white shadow-sm'
                                      : 'bg-white border-black/15 text-transparent hover:border-primary/60 hover:bg-primary/5')
                                  }
                                >
                                  <Check
                                    size={13}
                                    strokeWidth={3.5}
                                    className={
                                      'transition-all duration-150 ' +
                                      (on ? 'scale-100 opacity-100' : 'scale-50 opacity-0')
                                    }
                                  />
                                </button>
                              </td>
                            );
                          })}
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
              <div className="px-4 py-2.5 bg-black/[0.02] border-t border-black/[0.05]">
                <p className="text-[11px] text-ink-soft">
                  {t('perm.hint', {
                    defaultValue:
                      "Modul belgilanmagan bo'lsa — u rol egasiga menyuda ko'rinmaydi va API yopiq bo'ladi.",
                  })}
                </p>
              </div>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="px-6 py-4 border-t border-black/5 flex justify-end gap-2 shrink-0 bg-black/[0.015]">
          <button
            onClick={onClose}
            className="px-4 py-2 text-sm font-medium rounded-button border border-black/10 text-ink/70 hover:bg-black/5 hover:text-ink transition-colors"
          >
            {t('actions.cancel')}
          </button>
          <button
            onClick={save}
            disabled={saving}
            className="btn-primary disabled:opacity-50 transition-opacity"
          >
            {saving ? t('users.roles.saving') : t('actions.save')}
          </button>
        </div>
      </div>
    </div>
  );
}
