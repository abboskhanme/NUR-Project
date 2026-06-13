import { useMemo, useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import toast from 'react-hot-toast';
import { Plus, Boxes, PackageCheck, PackageX, Search, Trash2, Pencil } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import BalanceCard from '@/components/ui/BalanceCard';
import EmptyState from '@/components/ui/EmptyState';
import ConfirmModal from '@/components/ui/ConfirmModal';
import { formatDate } from '@/lib/format';
import { usePermissions } from '@/lib/permissions';
import AddUnitsModal from '@/features/warehouse/AddUnitsModal';
import EditUnitModal from '@/features/warehouse/EditUnitModal';

interface SummaryRow {
  product_id: string; model: string | null; kvm: number | null;
  available: number; reserved: number; sold: number; total: number;
}
interface Summary {
  rows: SummaryRow[]; total_available: number; total_reserved: number; total_sold: number;
}
interface Unit {
  id: string; unique_id: string; status: string; added_date: string; notes?: string | null;
  product_id: string;
  model: string | null; kvm: number | null; order_code?: string | null; customer_name?: string | null;
}

const STATUS_STYLE: Record<string, string> = {
  available: 'bg-success/10 text-success',
  reserved: 'bg-warning/10 text-warning',
  sold: 'bg-black/5 text-ink-soft',
};

export default function WarehousePage() {
  const { t } = useTranslation();
  const qc = useQueryClient();
  const { can } = usePermissions();
  const [status, setStatus] = useState('');
  const [search, setSearch] = useState('');
  const [adding, setAdding] = useState(false);
  const [editUnit, setEditUnit] = useState<Unit | null>(null);
  const [deleteUnit, setDeleteUnit] = useState<Unit | null>(null);

  const summaryQ = useQuery<Summary>({
    queryKey: ['wh-summary'],
    queryFn: () => api.get('/inventory/summary').then((r) => r.data),
  });
  const unitsQ = useQuery<Unit[]>({
    queryKey: ['wh-units', status, search],
    queryFn: () => api.get('/inventory/units', {
      params: { status: status || undefined, search: search.trim() || undefined },
    }).then((r) => r.data),
  });

  const s = summaryQ.data;
  const units = unitsQ.data ?? [];

  const statusLabel = useMemo(() => ({
    available: t('warehouse.status.available'),
    reserved: t('warehouse.status.reserved'),
    sold: t('warehouse.status.sold'),
  } as Record<string, string>), [t]);

  function refresh() {
    qc.invalidateQueries({ queryKey: ['wh-summary'] });
    qc.invalidateQueries({ queryKey: ['wh-units'] });
  }

  async function confirmDelete() {
    if (!deleteUnit) return;
    try {
      await api.delete(`/inventory/units/${deleteUnit.id}`);
      toast.success(t('common.deleted'));
      refresh();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || t('common.error'));
    } finally {
      setDeleteUnit(null);
    }
  }

  const STATUS_FILTERS = ['', 'available', 'reserved', 'sold'] as const;

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-2xl font-bold">{t('warehouse.title')}</h1>
          <p className="text-sm text-ink-soft">{t('warehouse.subtitle')}</p>
        </div>
        {can('inventory:write') && (
          <button className="btn-primary" onClick={() => setAdding(true)}>
            <Plus size={16} /> {t('warehouse.addBtn')}
          </button>
        )}
      </div>

      {/* KPI */}
      <div className="grid grid-cols-3 gap-3">
        <BalanceCard title={t('warehouse.status.available')} accent="success"
          value={String(s?.total_available ?? 0)} icon={<PackageCheck size={18} />} />
        <BalanceCard title={t('warehouse.status.reserved')} accent="warning"
          value={String(s?.total_reserved ?? 0)} icon={<Boxes size={18} />} />
        <BalanceCard title={t('warehouse.status.sold')} accent="primary"
          value={String(s?.total_sold ?? 0)} icon={<PackageX size={18} />} />
      </div>

      {/* Model + kvm bo'yicha sanoq */}
      <Card title={t('warehouse.byModel')}>
        {!s || s.rows.length === 0 ? (
          <div className="text-sm text-ink-soft">{t('warehouse.emptyModels')}</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="text-left text-ink-soft border-b border-black/5">
                <tr>
                  <th className="py-2 pr-3">{t('warehouse.col.model')}</th>
                  <th className="py-2 pr-3">{t('warehouse.col.kvm')}</th>
                  <th className="py-2 pr-3 text-right">{t('warehouse.status.available')}</th>
                  <th className="py-2 pr-3 text-right">{t('warehouse.status.reserved')}</th>
                  <th className="py-2 pr-3 text-right">{t('warehouse.status.sold')}</th>
                  <th className="py-2 pr-3 text-right">{t('warehouse.col.total')}</th>
                </tr>
              </thead>
              <tbody>
                {s.rows.map((r) => (
                  <tr key={r.product_id} className="border-b border-black/5">
                    <td className="py-2 pr-3 font-medium">{r.model ?? '—'}</td>
                    <td className="py-2 pr-3">{r.kvm ? `${r.kvm} kvm` : '—'}</td>
                    <td className="py-2 pr-3 text-right font-semibold text-success">{r.available}</td>
                    <td className="py-2 pr-3 text-right text-warning">{r.reserved}</td>
                    <td className="py-2 pr-3 text-right text-ink-soft">{r.sold}</td>
                    <td className="py-2 pr-3 text-right">{r.total}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      {/* Birliklar ro'yxati */}
      <Card title={t('warehouse.units')}>
        <div className="flex flex-wrap gap-3 mb-4 items-center justify-between">
          <div className="flex flex-wrap gap-1.5">
            {STATUS_FILTERS.map((k) => (
              <button key={k} onClick={() => setStatus(k)}
                className={`px-3 py-1.5 rounded-button text-sm font-medium transition ${
                  status === k ? 'bg-primary text-white' : 'bg-black/5 text-ink-soft hover:bg-black/10'}`}>
                {k === '' ? t('warehouse.filterAll') : statusLabel[k]}
              </button>
            ))}
          </div>
          <div className="relative">
            <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-ink-soft" />
            <input className="input pl-9 w-52" placeholder={t('warehouse.searchId')}
                   value={search} onChange={(e) => setSearch(e.target.value)} />
          </div>
        </div>

        {unitsQ.isLoading ? (
          <div className="space-y-2">
            {Array.from({ length: 5 }).map((_, i) => <div key={i} className="h-10 rounded-button bg-black/5 animate-pulse" />)}
          </div>
        ) : units.length === 0 ? (
          <EmptyState title={t('warehouse.emptyUnits')} description={t('warehouse.emptyUnitsDesc')} />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="text-left text-ink-soft border-b border-black/5">
                <tr>
                  <th className="py-2 pr-3">{t('warehouse.col.id')}</th>
                  <th className="py-2 pr-3">{t('warehouse.col.model')}</th>
                  <th className="py-2 pr-3">{t('warehouse.col.kvm')}</th>
                  <th className="py-2 pr-3">{t('warehouse.col.status')}</th>
                  <th className="py-2 pr-3">{t('warehouse.col.added')}</th>
                  <th className="py-2 pr-3">{t('warehouse.col.order')}</th>
                  <th className="py-2 pr-3"></th>
                </tr>
              </thead>
              <tbody>
                {units.map((u) => (
                  <tr key={u.id} className="border-b border-black/5 hover:bg-black/5">
                    <td className="py-2 pr-3 font-mono font-medium">{u.unique_id}</td>
                    <td className="py-2 pr-3">{u.model ?? '—'}</td>
                    <td className="py-2 pr-3">{u.kvm ? `${u.kvm} kvm` : '—'}</td>
                    <td className="py-2 pr-3">
                      <span className={`badge ${STATUS_STYLE[u.status] ?? ''}`}>{statusLabel[u.status] ?? u.status}</span>
                    </td>
                    <td className="py-2 pr-3 whitespace-nowrap">{formatDate(u.added_date)}</td>
                    <td className="py-2 pr-3">
                      {u.order_code
                        ? <span>{u.order_code}{u.customer_name ? ` · ${u.customer_name}` : ''}</span>
                        : <span className="text-ink-soft">—</span>}
                    </td>
                    <td className="py-2 pr-3 text-right">
                      <div className="flex items-center justify-end gap-1">
                        {u.status !== 'sold' && can('inventory:write') && (
                          <button onClick={() => setEditUnit(u)} className="p-1 rounded hover:bg-primary/10 text-primary" title={t('actions.edit')}>
                            <Pencil size={14} />
                          </button>
                        )}
                        {u.status === 'available' && can('inventory:delete') && (
                          <button onClick={() => setDeleteUnit(u)} className="p-1 rounded hover:bg-danger/10 text-danger" title={t('actions.delete')}>
                            <Trash2 size={14} />
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      {adding && <AddUnitsModal onClose={() => setAdding(false)} onSaved={refresh} />}
      {editUnit && (
        <EditUnitModal
          unit={editUnit}
          onClose={() => setEditUnit(null)}
          onSaved={refresh}
        />
      )}
      <ConfirmModal
        open={deleteUnit !== null}
        title={t('warehouse.deleteTitle')}
        message={t('warehouse.deleteMessage', { id: deleteUnit?.unique_id ?? '' })}
        confirmText={t('actions.delete')}
        variant="danger"
        onConfirm={confirmDelete}
        onCancel={() => setDeleteUnit(null)}
      />
    </div>
  );
}
