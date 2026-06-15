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
import { formatDate, formatUSD } from '@/lib/format';
import { usePermissions } from '@/lib/permissions';
import AddUnitsModal from '@/features/warehouse/AddUnitsModal';
import EditUnitModal from '@/features/warehouse/EditUnitModal';
import ProductModal, { ProductFull } from '@/features/products/ProductModal';

interface SummaryRow {
  product_id: string; model: string | null; kvm: number | null;
  available: number; reserved: number; sold: number; total: number;
}
interface Summary {
  rows: SummaryRow[]; total_available: number; total_reserved: number; total_sold: number;
}
interface Unit {
  id: string; unique_id: string; status: string; added_date: string; notes?: string | null;
  product_id: string; bunker_direction?: string | null;
  model: string | null; kvm: number | null; order_code?: string | null; customer_name?: string | null;
}
interface MainProduct extends ProductFull {
  display_name: string;
}

const STATUS_STYLE: Record<string, string> = {
  available: 'bg-success/10 text-success',
  reserved: 'bg-warning/10 text-warning',
  sold: 'bg-black/5 text-ink-soft',
};

type Tab = 'types' | 'list';

export default function WarehousePage() {
  const { t } = useTranslation();
  const qc = useQueryClient();
  const { can } = usePermissions();
  const [tab, setTab] = useState<Tab>('types');
  const [status, setStatus] = useState('');
  const [search, setSearch] = useState('');
  const [adding, setAdding] = useState(false);
  const [editUnit, setEditUnit] = useState<Unit | null>(null);
  const [deleteUnit, setDeleteUnit] = useState<Unit | null>(null);
  // Turlari (model) CRUD holati
  const [editingType, setEditingType] = useState<MainProduct | null>(null);
  const [typeModalOpen, setTypeModalOpen] = useState(false);
  const [deleteType, setDeleteType] = useState<MainProduct | null>(null);

  const summaryQ = useQuery<Summary>({
    queryKey: ['wh-summary'],
    queryFn: () => api.get('/inventory/summary').then((r) => r.data),
  });
  const unitsQ = useQuery<Unit[]>({
    queryKey: ['wh-units', status, search],
    queryFn: () => api.get('/inventory/units', {
      params: { status: status || undefined, search: search.trim() || undefined },
    }).then((r) => r.data),
    enabled: tab === 'list',
  });
  const typesQ = useQuery<{ items: MainProduct[] }>({
    queryKey: ['wh-types'],
    queryFn: () => api.get('/products', {
      params: { product_type: 'warehouse', page_size: 200 },
    }).then((r) => r.data),
    enabled: tab === 'types',
  });

  const s = summaryQ.data;
  const units = unitsQ.data ?? [];
  const types = typesQ.data?.items ?? [];

  // product_id -> qoldiq sanoqlari (Turlari tab uchun)
  const countByProduct = useMemo(() => {
    const m = new Map<string, SummaryRow>();
    for (const r of s?.rows ?? []) m.set(r.product_id, r);
    return m;
  }, [s]);

  const statusLabel = useMemo(() => ({
    available: t('warehouse.status.available'),
    reserved: t('warehouse.status.reserved'),
    sold: t('warehouse.status.sold'),
  } as Record<string, string>), [t]);

  function refresh() {
    qc.invalidateQueries({ queryKey: ['wh-summary'] });
    qc.invalidateQueries({ queryKey: ['wh-units'] });
    qc.invalidateQueries({ queryKey: ['wh-types'] });
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

  async function confirmDeleteType() {
    if (!deleteType) return;
    try {
      await api.delete(`/products/${deleteType.id}`);
      toast.success(t('common.deleted'));
      refresh();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || t('common.error'));
    } finally {
      setDeleteType(null);
    }
  }

  const STATUS_FILTERS = ['', 'available', 'reserved', 'sold'] as const;
  const TABS: Array<{ key: Tab; label: string }> = [
    { key: 'types', label: t('warehouse.tabs.types') },
    { key: 'list', label: t('warehouse.tabs.list') },
  ];

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-2xl font-bold">{t('warehouse.title')}</h1>
          <p className="text-sm text-ink-soft">{t('warehouse.subtitle')}</p>
        </div>
        {can('inventory:write') && (
          tab === 'list' ? (
            <button className="btn-primary" onClick={() => setAdding(true)}>
              <Plus size={16} /> {t('warehouse.addBtn')}
            </button>
          ) : (
            <button className="btn-primary" onClick={() => { setEditingType(null); setTypeModalOpen(true); }}>
              <Plus size={16} /> {t('warehouse.types.addBtn')}
            </button>
          )
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

      {/* Tabs */}
      <div className="flex gap-1 border-b border-black/5">
        {TABS.map((tb) => (
          <button key={tb.key} onClick={() => setTab(tb.key)}
            className={
              'px-4 py-2 text-sm font-medium -mb-px border-b-2 transition-colors ' +
              (tab === tb.key
                ? 'border-primary text-primary'
                : 'border-transparent text-ink-soft hover:text-ink')
            }>
            {tb.label}
          </button>
        ))}
      </div>

      {tab === 'types' ? (
        /* Turlari — kotyol modellari (qoʻshish / tahrir / oʻchirish) */
        <Card title={t('warehouse.tabs.types')}>
          {typesQ.isLoading ? (
            <div className="space-y-2">
              {Array.from({ length: 5 }).map((_, i) => <div key={i} className="h-10 rounded-button bg-black/5 animate-pulse" />)}
            </div>
          ) : types.length === 0 ? (
            <EmptyState title={t('warehouse.types.empty')} description={t('warehouse.types.emptyDesc')} />
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="text-left text-ink-soft border-b border-black/5">
                  <tr>
                    <th className="py-2 pr-3">{t('warehouse.types.col.model')}</th>
                    <th className="py-2 pr-3">{t('warehouse.types.col.kvm')}</th>
                    <th className="py-2 pr-3 text-right">{t('warehouse.types.col.price')}</th>
                    <th className="py-2 pr-3 text-right">{t('warehouse.types.col.available')}</th>
                    <th className="py-2 pr-3 text-right">{t('warehouse.types.col.reserved')}</th>
                    <th className="py-2 pr-3"></th>
                  </tr>
                </thead>
                <tbody>
                  {types.map((p) => {
                    const c = countByProduct.get(p.id);
                    return (
                      <tr key={p.id} className="border-b border-black/5 hover:bg-black/5">
                        <td className="py-2 pr-3 font-medium">{p.model ?? '—'}</td>
                        <td className="py-2 pr-3">{p.kvm ? `${p.kvm} kvm` : '—'}</td>
                        <td className="py-2 pr-3 text-right">{formatUSD(p.base_price_usd)}</td>
                        <td className="py-2 pr-3 text-right font-semibold text-success">{c?.available ?? 0}</td>
                        <td className="py-2 pr-3 text-right text-warning">{c?.reserved ?? 0}</td>
                        <td className="py-2 pr-3 text-right">
                          <div className="flex items-center justify-end gap-1">
                            {can('inventory:write') && (
                              <button onClick={() => { setEditingType(p); setTypeModalOpen(true); }}
                                      className="p-1 rounded hover:bg-primary/10 text-primary" title={t('actions.edit')}>
                                <Pencil size={14} />
                              </button>
                            )}
                            {can('inventory:delete') && (
                              <button onClick={() => setDeleteType(p)}
                                      className="p-1 rounded hover:bg-danger/10 text-danger" title={t('actions.delete')}>
                                <Trash2 size={14} />
                              </button>
                            )}
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </Card>
      ) : (
        /* Roʻyxat — ID raqamli birliklar */
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
                    <th className="py-2 pr-3">{t('warehouse.col.direction')}</th>
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
                        {u.bunker_direction === 'right' ? t('warehouse.dir.right')
                          : u.bunker_direction === 'left' ? t('warehouse.dir.left')
                          : <span className="text-ink-soft">—</span>}
                      </td>
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
      )}

      {adding && <AddUnitsModal onClose={() => setAdding(false)} onSaved={refresh} />}
      {editUnit && (
        <EditUnitModal
          unit={editUnit}
          onClose={() => setEditUnit(null)}
          onSaved={refresh}
        />
      )}
      {typeModalOpen && (
        <ProductModal
          product={editingType}
          defaultType="warehouse"
          onClose={() => setTypeModalOpen(false)}
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
      <ConfirmModal
        open={deleteType !== null}
        title={t('warehouse.types.deleteTitle')}
        message={t('warehouse.types.deleteMessage', { name: deleteType?.display_name ?? deleteType?.model ?? '' })}
        confirmText={t('actions.delete')}
        variant="danger"
        onConfirm={confirmDeleteType}
        onCancel={() => setDeleteType(null)}
      />
    </div>
  );
}
