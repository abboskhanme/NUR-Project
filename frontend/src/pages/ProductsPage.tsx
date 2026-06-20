import { useMemo, useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import toast from 'react-hot-toast';
import { Plus, Pencil, Trash2 } from 'lucide-react';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import EmptyState from '@/components/ui/EmptyState';
import ConfirmModal from '@/components/ui/ConfirmModal';
import { formatUSD } from '@/lib/format';
import ProductModal, { ProductFull, ProductType } from '@/features/products/ProductModal';
import ProductThumb from '@/features/products/ProductThumb';

interface Product extends ProductFull {
  display_name: string;
  created_at: string;
}

export default function ProductsPage() {
  const { t } = useTranslation();
  const qc = useQueryClient();
  const [tab, setTab] = useState<ProductType>('main');
  const [editing, setEditing] = useState<Product | null>(null);
  const [modalOpen, setModalOpen] = useState(false);
  const [toDelete, setToDelete] = useState<Product | null>(null);
  const [deleting, setDeleting] = useState(false);

  const TABS: Array<{ key: ProductType; label: string; hint: string }> = [
    { key: 'main', label: t('products.tabs.main'), hint: t('products.tabs.mainHint') },
    { key: 'additional', label: t('products.tabs.additional'), hint: t('products.tabs.additionalHint') },
  ];

  const { data, isLoading } = useQuery({
    queryKey: ['products', tab],
    queryFn: () =>
      api.get('/products', { params: { product_type: tab, page_size: 200 } }).then((r) => r.data),
  });
  const items: Product[] = data?.items ?? [];

  const sizeGroups = useMemo(() => {
    const map = new Map<number | null, Product[]>();
    for (const p of items) {
      const key = p.kvm ?? null;
      if (!map.has(key)) map.set(key, []);
      map.get(key)!.push(p);
    }
    return Array.from(map.entries())
      .sort((a, b) => (a[0] ?? Infinity) - (b[0] ?? Infinity))
      .map(([kvm, rows]) => ({
        kvm,
        rows: rows.sort((a, b) => (a.model ?? '').localeCompare(b.model ?? '')),
      }));
  }, [items]);

  const active = TABS.find((t) => t.key === tab)!;

  function openCreate() { setEditing(null); setModalOpen(true); }
  function openEdit(p: Product) { setEditing(p); setModalOpen(true); }
  function refresh() { qc.invalidateQueries({ queryKey: ['products'] }); }

  async function confirmDelete() {
    if (!toDelete) return;
    setDeleting(true);
    try {
      await api.delete(`/products/${toDelete.id}`);
      toast.success(t('products.toastDeleted'));
      setToDelete(null);
      refresh();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || t('products.toastError'));
    } finally {
      setDeleting(false);
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-2xl font-bold">{t('products.title')}</h1>
          <p className="text-sm text-ink-soft">{active.hint}</p>
        </div>
        <button className="btn-primary" onClick={openCreate}>
          <Plus size={16} /> {tab === 'main' ? t('products.addMain') : t('products.addAdditional')}
        </button>
      </div>

      {/* Tabs */}
      <div className="flex gap-1 border-b border-black/5">
        {TABS.map((tabItem) => (
          <button key={tabItem.key} onClick={() => setTab(tabItem.key)}
            className={
              'px-4 py-2 text-sm font-medium -mb-px border-b-2 transition-colors ' +
              (tab === tabItem.key
                ? 'border-primary text-primary'
                : 'border-transparent text-ink-soft hover:text-ink')
            }>
            {tabItem.label}
          </button>
        ))}
      </div>

      {isLoading ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {Array.from({ length: 6 }).map((_, i) => (
            <div key={i} className="h-28 rounded-card bg-black/5 animate-pulse" />
          ))}
        </div>
      ) : items.length === 0 ? (
        <EmptyState title={t('products.empty')} />
      ) : tab === 'main' ? (
        <div className="space-y-6">
          {sizeGroups.map(({ kvm, rows }) => (
            <section key={kvm ?? 'none'}>
              <div className="flex items-center gap-2 mb-2">
                <h2 className="text-sm font-bold text-ink">
                  {kvm ? `${kvm} ${t('products.sizeUnit')}` : t('products.noSize')}
                </h2>
                <span className="badge bg-primary/10 text-primary">{rows.length}</span>
                <div className="flex-1 h-px bg-black/5" />
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-3">
                {rows.map((p) => (
                  <Card key={p.id} className="group hover:shadow-lg transition-shadow !p-3">
                    <div className="flex items-start justify-between">
                      <div>
                        <div className="text-base font-semibold leading-tight">{p.model}</div>
                        <div className="text-lg font-bold text-primary mt-1">{formatUSD(p.base_price_usd)}</div>
                      </div>
                      <RowActions
                        onEdit={() => openEdit(p)}
                        onDelete={() => setToDelete(p)}
                        editTooltip={t('products.editTooltip')}
                        deleteTooltip={t('products.deleteTooltip')}
                      />
                    </div>
                  </Card>
                ))}
              </div>
            </section>
          ))}
        </div>
      ) : (
        <Card className="p-0 overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-black/[0.03] text-ink-soft text-left">
              <tr>
                <th className="px-4 py-2 w-14"></th>
                <th className="px-4 py-2 font-medium">{t('products.table.name')}</th>
                <th className="px-4 py-2 font-medium">{t('products.table.unit')}</th>
                <th className="px-4 py-2 font-medium text-right">{t('products.table.price')}</th>
                <th className="px-4 py-2 w-20"></th>
              </tr>
            </thead>
            <tbody>
              {items.map((p) => (
                <tr key={p.id} className="border-t border-black/5 hover:bg-black/[0.02]">
                  <td className="pl-4 py-2">
                    <ProductThumb id={p.id} hasImage={p.has_image} size={40} />
                  </td>
                  <td className="px-4 py-2 font-medium">{p.name}</td>
                  <td className="px-4 py-2 text-ink-soft">{p.unit || '—'}</td>
                  <td className="px-4 py-2 text-right font-semibold text-primary">{formatUSD(p.base_price_usd)}</td>
                  <td className="px-4 py-2">
                    <RowActions
                      onEdit={() => openEdit(p)}
                      onDelete={() => setToDelete(p)}
                      editTooltip={t('products.editTooltip')}
                      deleteTooltip={t('products.deleteTooltip')}
                    />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </Card>
      )}

      {modalOpen && (
        <ProductModal
          product={editing}
          defaultType={tab}
          onClose={() => setModalOpen(false)}
          onSaved={refresh}
        />
      )}

      <ConfirmModal
        open={toDelete !== null}
        title={t('products.deleteTitle')}
        message={
          <>{t('products.deleteMessage', { name: toDelete?.display_name ?? '' })}</>
        }
        loading={deleting}
        confirmText={t('actions.delete')}
        onConfirm={confirmDelete}
        onCancel={() => setToDelete(null)}
      />
    </div>
  );
}

function RowActions({
  onEdit,
  onDelete,
  editTooltip,
  deleteTooltip,
}: {
  onEdit: () => void;
  onDelete: () => void;
  editTooltip: string;
  deleteTooltip: string;
}) {
  return (
    <div className="flex items-center gap-1">
      <button onClick={onEdit} className="p-1.5 rounded hover:bg-black/5 text-ink-soft" title={editTooltip}>
        <Pencil size={15} />
      </button>
      <button onClick={onDelete} className="p-1.5 rounded hover:bg-danger/10 text-danger" title={deleteTooltip}>
        <Trash2 size={15} />
      </button>
    </div>
  );
}
