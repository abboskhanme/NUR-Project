import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import toast from 'react-hot-toast';
import { X, Target } from 'lucide-react';

import { api } from '@/api/client';
import { formatNumberInput, parseNumberInput } from '@/lib/format';
import type { MonthlyGoal } from '@/features/dashboard/types';

/**
 * Joriy oy maqsadini belgilash/yangilash — sotuv soni va tushum (UZS).
 * Faqat `system:goals_manage` ruxsatli foydalanuvchiga ko'rinadi.
 */
export default function GoalModal({
  goal, onClose, onSaved,
}: {
  goal: MonthlyGoal | null;
  onClose: () => void;
  onSaved: () => void;
}) {
  const { t } = useTranslation();
  const [orders, setOrders] = useState(
    goal?.target_orders != null ? formatNumberInput(goal.target_orders) : '');
  const [revenue, setRevenue] = useState(
    goal?.target_revenue_uzs != null ? formatNumberInput(goal.target_revenue_uzs) : '');
  const [saving, setSaving] = useState(false);

  async function submit() {
    setSaving(true);
    try {
      await api.put('/goals/current', {
        target_orders: orders.trim() === '' ? null : parseNumberInput(orders),
        target_revenue_uzs: revenue.trim() === '' ? null : parseNumberInput(revenue),
      });
      toast.success(t('dashboard.goal.saved'));
      onSaved();
      onClose();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || t('common.error'));
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div className="bg-card rounded-lg shadow-xl w-full max-w-md" onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-4 border-b border-black/5">
          <h3 className="font-semibold text-base flex items-center gap-2">
            <Target size={18} className="text-primary" /> {t('dashboard.goal.modalTitle')}
          </h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5 text-ink/50"><X size={18} /></button>
        </div>

        <div className="px-5 py-4 space-y-3">
          <p className="text-xs text-ink-soft">{t('dashboard.goal.modalHint')}</p>
          <div>
            <label className="text-xs text-ink-soft">{t('dashboard.goal.orders')}</label>
            <input
              type="text" inputMode="numeric" className="input w-full mt-1 text-right tabular-nums"
              placeholder="0" value={orders}
              onChange={(e) => setOrders(formatNumberInput(e.target.value))}
            />
          </div>
          <div>
            <label className="text-xs text-ink-soft">{t('dashboard.goal.revenueUzs')}</label>
            <div className="relative mt-1">
              <input
                type="text" inputMode="numeric" className="input w-full text-right tabular-nums pr-12"
                placeholder="0" value={revenue}
                onChange={(e) => setRevenue(formatNumberInput(e.target.value))}
              />
              <span className="absolute right-3 top-1/2 -translate-y-1/2 text-xs text-ink-soft pointer-events-none">so'm</span>
            </div>
          </div>
        </div>

        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2">
          <button onClick={onClose} className="px-3 py-1.5 text-sm rounded-button border border-black/10 hover:bg-black/5">
            {t('actions.cancel')}
          </button>
          <button onClick={submit} disabled={saving}
                  className="px-4 py-1.5 text-sm rounded-button font-medium bg-primary text-white hover:bg-primary/90 disabled:opacity-50">
            {saving ? t('common.saving', { defaultValue: 'Saqlanyapti…' }) : t('actions.save', { defaultValue: 'Saqlash' })}
          </button>
        </div>
      </div>
    </div>
  );
}
