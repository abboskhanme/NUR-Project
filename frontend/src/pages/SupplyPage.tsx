import { useMemo, useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import {
  Plus, AlertTriangle, PackagePlus, Wallet, Truck, Boxes,
  ArrowUpRight, Pencil, Trash2, HandCoins,
} from 'lucide-react';
import toast from 'react-hot-toast';

import { api } from '@/api/client';
import Card from '@/components/ui/Card';
import BalanceCard from '@/components/ui/BalanceCard';
import EmptyState from '@/components/ui/EmptyState';
import ConfirmModal from '@/components/ui/ConfirmModal';
import { cn } from '@/lib/cn';
import { formatUZS, formatDate } from '@/lib/format';
import { usePermissions } from '@/lib/permissions';
import { useAuthStore } from '@/stores/auth';

import { VendorLite } from '@/features/supply/VendorModal';
import ItemModal, { ItemLite } from '@/features/supply/ItemModal';
import ReceiptModal from '@/features/supply/ReceiptModal';
import PaymentModal from '@/features/supply/PaymentModal';
import IssueModal from '@/features/supply/IssueModal';
import ReorderSuggestions from '@/features/supply/ReorderSuggestions';

interface Vendor extends VendorLite {
  open_debt: string; items_count: number; low_stock_count: number;
}
interface Item extends ItemLite { is_low: boolean }
interface Receipt {
  id: string; date: string; vendor_id: string; item_id: string;
  qty: string; unit_price: string; total: string; paid: string; balance: string;
  status: string; item_name?: string; vendor_name?: string; unit?: string;
}
interface Summary {
  total_debt: string; total_received: string; total_paid: string;
  stock_value: string; items_count: number; low_stock_count: number; vendors_count: number;
}

const SUPPLY_TABS: Record<string, string> = {
  items: 'Mahsulotlar',
  receipts: 'Kirimlar / Qarzlar',
};

export default function SupplyPage() {
  const qc = useQueryClient();
  const { can } = usePermissions();
  const user = useAuthStore((s) => s.user);
  const canWrite = can('supply:write');
  const canDelete = can('supply:delete');

  const [activeVendor, setActiveVendor] = useState<string>('all');
  const [tab, setTab] = useState<'items' | 'receipts'>('items');

  // Modallar
  const [itemModal, setItemModal] = useState<{ open: boolean; item?: Item | null }>({ open: false });
  const [receiptModal, setReceiptModal] = useState(false);
  const [paymentModal, setPaymentModal] = useState(false);
  const [issueItem, setIssueItem] = useState<Item | null>(null);
  const [deleteItem, setDeleteItem] = useState<Item | null>(null);

  const summaryQ = useQuery<Summary>({
    queryKey: ['supply-summary'],
    queryFn: () => api.get('/supply/summary').then((r) => r.data),
  });
  const vendorsQ = useQuery<Vendor[]>({
    queryKey: ['supply-vendors'],
    queryFn: () => api.get('/supply/vendors').then((r) => r.data),
  });

  const vendors = vendorsQ.data ?? [];
  const myVendor = useMemo(
    () => vendors.find((v) => v.user_id && v.user_id === user?.id),
    [vendors, user?.id],
  );
  const isSupplier = !!myVendor;
  const scopeVendorId = isSupplier ? myVendor!.id
    : (activeVendor === 'all' ? undefined : activeVendor);

  const itemsQ = useQuery({
    queryKey: ['supply-items', scopeVendorId],
    queryFn: () => api.get('/supply/items', {
      params: { vendor_id: scopeVendorId, page_size: 200 },
    }).then((r) => r.data),
  });
  const receiptsQ = useQuery<Receipt[]>({
    queryKey: ['supply-receipts', scopeVendorId],
    queryFn: () => api.get('/supply/receipts', {
      params: { vendor_id: scopeVendorId },
    }).then((r) => r.data),
  });

  const items: Item[] = itemsQ.data?.items ?? [];
  const receipts: Receipt[] = receiptsQ.data ?? [];
  const s = summaryQ.data;

  function refreshAll() {
    qc.invalidateQueries({ queryKey: ['supply-summary'] });
    qc.invalidateQueries({ queryKey: ['supply-vendors'] });
    qc.invalidateQueries({ queryKey: ['supply-items'] });
    qc.invalidateQueries({ queryKey: ['supply-receipts'] });
  }

  async function handleDeleteItem() {
    if (!deleteItem) return;
    try {
      await api.delete(`/supply/items/${deleteItem.id}`);
      toast.success("O'chirildi");
      refreshAll();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || "Xatolik");
    } finally {
      setDeleteItem(null);
    }
  }

  const receiptStatusLabel: Record<string, string> = {
    open: 'Qarz',
    partial: 'Qisman',
    paid: "To'langan",
  };
  const RECEIPT_STYLE: Record<string, string> = {
    open: 'bg-danger/10 text-danger',
    partial: 'bg-warning/10 text-warning',
    paid: 'bg-success/10 text-success',
  };

  return (
    <div className="space-y-4">
      {/* Sarlavha + asosiy amallar */}
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-2xl font-bold">Ta'minot</h1>
          <p className="text-sm text-ink-soft">
            {isSupplier ? myVendor!.name : 'Taminotchilar, mahsulotlar va qarzlar'}
          </p>
        </div>
        {canWrite && (
          <div className="flex gap-2 flex-wrap">
            <button className="btn-ghost border border-black/10" onClick={() => setPaymentModal(true)}>
              <HandCoins size={16} /> Qarz to'lash
            </button>
            <button className="btn-ghost border border-black/10" onClick={() => setItemModal({ open: true })}>
              <PackagePlus size={16} /> Yangi mahsulot
            </button>
            <button className="btn-primary" onClick={() => setReceiptModal(true)}>
              <Plus size={16} /> Yangi kirim
            </button>
          </div>
        )}
      </div>

      {/* KPI kartalari */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        <BalanceCard title="Umumiy qarz" accent="warning"
          value={formatUZS(s?.total_debt ?? 0)} icon={<Wallet size={18} />} />
        <BalanceCard title="Jami kirim (qiymat)" accent="primary"
          value={formatUZS(s?.total_received ?? 0)} icon={<ArrowUpRight size={18} />} />
        <BalanceCard title="Ombor qiymati" accent="success"
          value={formatUZS(s?.stock_value ?? 0)} icon={<Boxes size={18} />} />
        <BalanceCard
          title="Kam qolgan mahsulot"
          accent={s?.low_stock_count ? 'warning' : 'success'}
          value={`${s?.low_stock_count ?? 0} ta`}
          icon={<AlertTriangle size={18} />} />
      </div>

      {/* Buyurtma berish tavsiyalari — faqat zaxira kam bo'lganda ko'rinadi */}
      <ReorderSuggestions vendorId={scopeVendorId} />

      {/* Taminotchi tablari (faqat admin/menejer) */}
      {!isSupplier && (
        <div className="flex gap-2 flex-wrap items-center">
          <button onClick={() => setActiveVendor('all')}
            className={cn('btn-ghost', activeVendor === 'all' && 'bg-primary/10 text-primary')}>
            Barchasi
          </button>
          {vendors.map((v) => (
            <button key={v.id} onClick={() => setActiveVendor(v.id)}
              className={cn('btn-ghost flex items-center gap-1.5',
                activeVendor === v.id && 'bg-primary/10 text-primary')}>
              <Truck size={14} /> {v.name}
              {Number(v.open_debt) > 0 && (
                <span className="badge bg-danger/10 text-danger ml-1">
                  {formatUZS(v.open_debt)}
                </span>
              )}
            </button>
          ))}
          {vendors.length === 0 && (
            <span className="text-sm text-ink-soft px-2 py-1.5">
              Taminotchilar Foydalanuvchilar bo'limida «Taminotchi» roli bilan qo'shiladi
            </span>
          )}
        </div>
      )}

      {/* Tanlangan taminotchi qarz holati */}
      {!isSupplier && activeVendor !== 'all' && (() => {
        const v = vendors.find((x) => x.id === activeVendor);
        if (!v) return null;
        return (
          <Card className="flex items-center justify-between flex-wrap gap-3">
            <div>
              <div className="font-semibold">{v.name}</div>
              <div className="text-sm text-ink-soft">
                {`${v.items_count} mahsulot · ${v.low_stock_count} kam · qarz: ${formatUZS(v.open_debt)}`}
              </div>
            </div>
          </Card>
        );
      })()}

      {/* Ichki tablar */}
      <div className="flex gap-1 border-b border-black/5">
        {(['items', 'receipts'] as const).map((k) => (
          <button key={k} onClick={() => setTab(k)}
            className={cn('px-4 py-2 text-sm font-medium border-b-2 -mb-px',
              tab === k ? 'border-primary text-primary' : 'border-transparent text-ink-soft hover:text-ink')}>
            {SUPPLY_TABS[k]}
          </button>
        ))}
      </div>

      {tab === 'items' ? (
        <Card>
          {items.length === 0 ? (
            <EmptyState title="Mahsulotlar yo'q"
              description={canWrite ? "Yangi mahsulot qo'shing" : "Hozircha bo'sh"} />
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="text-left text-ink-soft border-b border-black/5">
                  <tr>
                    <th className="py-2 pr-3">Nomi</th>
                    <th className="py-2 pr-3">Birlik</th>
                    <th className="py-2 pr-3 text-right">Birlik narxi</th>
                    <th className="py-2 pr-3 text-right">Qoldiq</th>
                    <th className="py-2 pr-3 text-right">Minimum</th>
                    <th className="py-2 pr-3">Holat</th>
                    {canWrite && <th className="py-2 pr-3 text-right">Amallar</th>}
                  </tr>
                </thead>
                <tbody>
                  {items.map((it) => (
                    <tr key={it.id} className="border-b border-black/5 hover:bg-black/5">
                      <td className="py-2 pr-3 font-medium">{it.name}</td>
                      <td className="py-2 pr-3">{it.unit}</td>
                      <td className="py-2 pr-3 text-right">{formatUZS(it.unit_price)}</td>
                      <td className="py-2 pr-3 text-right">{parseFloat(it.stock_qty)}</td>
                      <td className="py-2 pr-3 text-right">{parseFloat(it.min_qty)}</td>
                      <td className="py-2 pr-3">
                        {it.is_low
                          ? <span className="badge bg-danger/10 text-danger"><AlertTriangle size={12} /> Kam</span>
                          : <span className="badge bg-success/10 text-success">OK</span>}
                      </td>
                      {canWrite && (
                        <td className="py-2 pr-3">
                          <div className="flex items-center justify-end gap-1">
                            <button title="Chiqim" className="p-1.5 rounded hover:bg-black/5"
                              onClick={() => setIssueItem(it)}>
                              <ArrowUpRight size={15} />
                            </button>
                            <button title="Tahrirlash" className="p-1.5 rounded hover:bg-black/5"
                              onClick={() => setItemModal({ open: true, item: it })}>
                              <Pencil size={15} />
                            </button>
                            {canDelete && (
                              <button title="O'chirish" className="p-1.5 rounded hover:bg-black/5 text-danger"
                                onClick={() => setDeleteItem(it)}>
                                <Trash2 size={15} />
                              </button>
                            )}
                          </div>
                        </td>
                      )}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </Card>
      ) : (
        <Card>
          {receipts.length === 0 ? (
            <EmptyState title="Kirimlar yo'q" description="«Yangi kirim» orqali qo'shing" />
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="text-left text-ink-soft border-b border-black/5">
                  <tr>
                    <th className="py-2 pr-3">Sana</th>
                    {!isSupplier && <th className="py-2 pr-3">Taminotchi</th>}
                    <th className="py-2 pr-3">Mahsulot</th>
                    <th className="py-2 pr-3 text-right">Miqdor</th>
                    <th className="py-2 pr-3 text-right">Summa</th>
                    <th className="py-2 pr-3 text-right">Qarz</th>
                    <th className="py-2 pr-3">Holat</th>
                  </tr>
                </thead>
                <tbody>
                  {receipts.map((r) => (
                    <tr key={r.id} className="border-b border-black/5 hover:bg-black/5">
                      <td className="py-2 pr-3">{formatDate(r.date)}</td>
                      {!isSupplier && <td className="py-2 pr-3">{r.vendor_name}</td>}
                      <td className="py-2 pr-3 font-medium">{r.item_name}</td>
                      <td className="py-2 pr-3 text-right">{parseFloat(r.qty)} {r.unit}</td>
                      <td className="py-2 pr-3 text-right">{formatUZS(r.total)}</td>
                      <td className="py-2 pr-3 text-right">
                        <span className={Number(r.balance) > 0 ? 'text-danger font-medium' : 'text-ink-soft'}>
                          {formatUZS(r.balance)}
                        </span>
                      </td>
                      <td className="py-2 pr-3">
                        <span className={cn('badge', RECEIPT_STYLE[r.status] || 'bg-gray-100 text-gray-700')}>
                          {receiptStatusLabel[r.status] || r.status}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </Card>
      )}

      {/* ===== Modallar ===== */}
      {itemModal.open && (
        <ItemModal item={itemModal.item} vendors={vendors}
          fixedVendorId={isSupplier ? myVendor!.id : undefined}
          onClose={() => setItemModal({ open: false })} onSaved={refreshAll} />
      )}
      {receiptModal && (
        <ReceiptModal vendors={vendors} fixedVendorId={isSupplier ? myVendor!.id : undefined}
          onClose={() => setReceiptModal(false)} onSaved={refreshAll} />
      )}
      {paymentModal && (
        <PaymentModal vendors={vendors} fixedVendorId={isSupplier ? myVendor!.id : undefined}
          initialVendorId={!isSupplier && activeVendor !== 'all' ? activeVendor : undefined}
          onClose={() => setPaymentModal(false)} onSaved={refreshAll} />
      )}
      {issueItem && (
        <IssueModal item={issueItem} onClose={() => setIssueItem(null)} onSaved={refreshAll} />
      )}
      {deleteItem && (
        <ConfirmModal
          open
          title="Mahsulotni o'chirish"
          message={`«${deleteItem.name}» o'chirilsinmi?`}
          confirmText="O'chirish"
          onConfirm={handleDeleteItem}
          onCancel={() => setDeleteItem(null)} />
      )}
    </div>
  );
}
