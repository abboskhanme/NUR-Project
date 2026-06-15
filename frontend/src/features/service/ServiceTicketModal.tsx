import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useQuery } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { X, Search, Check, Package } from 'lucide-react';

import { api } from '@/api/client';
import { formatDate, formatPhone } from '@/lib/format';
import { computeWarranty, WARRANTY_META } from '@/features/service/warranty';

interface Customer { id: string; full_name: string; phone: string; address?: string | null }
interface Order {
  id: string; code: string; delivered_at?: string | null; status: string;
  delivery_address?: string | null; product_summary?: string | null;
}
interface Category { id: string; name: string }

export default function ServiceTicketModal({
  onClose, onSaved,
}: { onClose: () => void; onSaved: () => void }) {
  const { t } = useTranslation();
  const [search, setSearch] = useState('');
  const [debounced, setDebounced] = useState('');
  const [customer, setCustomer] = useState<Customer | null>(null);
  const [order, setOrder] = useState<Order | null>(null);
  const [problem, setProblem] = useState('');
  const [category, setCategory] = useState('');
  const [address, setAddress] = useState('');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    const timer = setTimeout(() => setDebounced(search.trim()), 300);
    return () => clearTimeout(timer);
  }, [search]);

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  const customersQ = useQuery<{ items: Customer[] }>({
    queryKey: ['svc-cust-search', debounced],
    queryFn: () => api.get('/customers', { params: { search: debounced, page_size: 8 } }).then((r) => r.data),
    enabled: !customer && debounced.length >= 1,
  });

  const ordersQ = useQuery<Order[]>({
    queryKey: ['svc-cust-orders', customer?.id],
    queryFn: () => api.get('/service/orders', {
      params: { customer_id: customer!.id },
    }).then((r) => r.data),
    enabled: !!customer,
  });
  const orders = ordersQ.data ?? [];

  const categoriesQ = useQuery<Category[]>({
    queryKey: ['service-categories'],
    queryFn: () => api.get('/service/categories').then((r) => r.data),
  });
  const categories = categoriesQ.data ?? [];

  const orderHasAddress = !!(order?.delivery_address && order.delivery_address.trim());
  const needAddress = !!order && !orderHasAddress;

  function pickCustomer(c: Customer) {
    setCustomer(c);
    setSearch(c.full_name);
    setOrder(null);
    setAddress('');
  }

  // Warranty label helpers — resolved at render time via t()
  function warrantyShort(status: string): string {
    const key = `service.warranty.${
      status === 'active_full' ? 'activeFull_short'
      : status === 'active_service_only' ? 'activeServiceOnly_short'
      : status === 'expired' ? 'expired_short'
      : 'notDelivered_short'
    }`;
    return t(key);
  }

  function warrantyLong(status: string): string {
    const key = `service.warranty.${
      status === 'active_full' ? 'activeFull_long'
      : status === 'active_service_only' ? 'activeServiceOnly_long'
      : status === 'expired' ? 'expired_long'
      : 'notDelivered_long'
    }`;
    return t(key);
  }

  async function handleSave() {
    if (!customer) { toast.error(t('service.toast.errorCustomer')); return; }
    if (!order) { toast.error(t('service.toast.errorOrder')); return; }
    if (!problem.trim() && !category) { toast.error(t('service.toast.errorProblem')); return; }
    if (needAddress && !address.trim()) { toast.error(t('service.toast.errorAddress')); return; }
    setSaving(true);
    try {
      await api.post('/service/tickets', {
        customer_id: customer.id,
        order_id: order.id,
        problem: problem.trim() || category,
        category: category || null,
        address: needAddress ? address.trim() : null,
      });
      toast.success(t('service.toast.ticketCreated'));
      onSaved();
      onClose();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || t('service.toast.errorGeneric'));
    } finally {
      setSaving(false);
    }
  }

  const selW = order ? computeWarranty(order.delivered_at) : null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div className="bg-card rounded-lg shadow-xl w-full max-w-lg max-h-[90vh] overflow-y-auto flex flex-col"
           onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/5 sticky top-0 bg-card z-10">
          <h3 className="font-semibold">{t('service.form.title')}</h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5"><X size={18} /></button>
        </div>

        <div className="p-5 space-y-4">
          {/* 1. Customer search */}
          <div>
            <label className="label">{t('service.form.customer')} *</label>
            <div className="relative">
              <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-ink-soft" />
              <input
                className="input pl-9"
                placeholder={t('service.form.customerPlaceholder')}
                value={search}
                onChange={(e) => { setSearch(e.target.value); setCustomer(null); setOrder(null); }}
              />
            </div>
            {!customer && debounced.length >= 1 && (customersQ.data?.items?.length ?? 0) > 0 && (
              <div className="mt-1 border border-black/10 rounded-button divide-y divide-black/5 overflow-hidden">
                {customersQ.data!.items.map((c) => (
                  <button key={c.id} type="button" onClick={() => pickCustomer(c)}
                    className="w-full text-left px-3 py-2 hover:bg-black/5 text-sm">
                    <div className="font-medium">{c.full_name}</div>
                    <div className="text-xs text-ink-soft">{formatPhone(c.phone)}</div>
                  </button>
                ))}
              </div>
            )}
            {customer && (
              <div className="mt-1 text-xs text-success flex items-center gap-1">
                <Check size={13} /> {customer.full_name} — {formatPhone(customer.phone)}
              </div>
            )}
          </div>

          {/* 2. Order selection */}
          {customer && (
            <div>
              <label className="label">
                {t('service.form.orderLabel')} *{' '}
                <span className="text-ink-soft font-normal">{t('service.form.orderLabelHint')}</span>
              </label>
              {ordersQ.isLoading ? (
                <div className="space-y-1.5">
                  {Array.from({ length: 3 }).map((_, i) => <div key={i} className="h-12 rounded-button bg-black/5 animate-pulse" />)}
                </div>
              ) : orders.length === 0 ? (
                <div className="text-sm text-ink-soft bg-black/[0.03] rounded-button p-3">
                  {t('service.form.noOrders')}
                </div>
              ) : (
                <div className="max-h-52 overflow-y-auto border border-black/10 rounded-button divide-y divide-black/5">
                  {orders.map((o) => {
                    const w = computeWarranty(o.delivered_at);
                    const meta = WARRANTY_META[w.status];
                    const active = order?.id === o.id;
                    return (
                      <button key={o.id} type="button" onClick={() => { setOrder(o); setAddress(''); }}
                        className={`w-full text-left px-3 py-2 text-sm flex items-center justify-between gap-2 transition ${
                          active ? 'bg-primary/10' : 'hover:bg-black/5'}`}>
                        <span className="flex items-center gap-2 min-w-0">
                          {active ? <Check size={14} className="text-primary shrink-0" /> : <Package size={14} className="text-ink-soft shrink-0" />}
                          <span className="min-w-0">
                            <span className="block truncate">
                              <span className="font-medium">{o.code}</span>
                              {o.product_summary && <span> — {o.product_summary}</span>}
                            </span>
                            {o.delivered_at && (
                              <span className="block text-xs text-ink-soft">
                                {t('service.form.delivered')} {formatDate(o.delivered_at)}
                              </span>
                            )}
                          </span>
                        </span>
                        <span className={`badge shrink-0 ${meta.cls}`}>{warrantyShort(w.status)}</span>
                      </button>
                    );
                  })}
                </div>
              )}
            </div>
          )}

          {/* Selected order warranty */}
          {selW && (
            <div className={`rounded-button p-3 text-sm font-medium ${WARRANTY_META[selW.status].cls}`}>
              {warrantyLong(selW.status)}
              {selW.status === 'active_full' && selW.daysYear1 > 0 && (
                <> {t('service.warranty.daysLeft', { count: selW.daysYear1 })}</>
              )}
              {selW.status === 'active_service_only' && selW.daysYear3 > 0 && (
                <> {t('service.warranty.daysLeft', { count: selW.daysYear3 })}</>
              )}
            </div>
          )}

          {/* 3. Problem */}
          {order && (
            <>
              <div>
                <label className="label">
                  {t('service.form.problem')}{' '}
                  {category
                    ? <span className="text-ink-soft font-normal">{t('service.form.problemOptional')}</span>
                    : '*'}
                </label>
                <textarea className="input min-h-[72px]" placeholder={t('service.form.problemPlaceholder')}
                          value={problem} onChange={(e) => setProblem(e.target.value)} />
              </div>

              {/* Category dropdown */}
              <div>
                <label className="label">{t('service.form.category')}</label>
                <select className="input" value={category} onChange={(e) => setCategory(e.target.value)}>
                  <option value="">{t('service.form.categoryNone')}</option>
                  {categories.map((c) => <option key={c.id} value={c.name}>{c.name}</option>)}
                </select>
                {categories.length === 0 && (
                  <div className="text-xs text-ink-soft mt-1">{t('service.form.noCategoriesHint')}</div>
                )}
              </div>

              {/* Address — only if order has no address */}
              {needAddress && (
                <div>
                  <label className="label">
                    {t('service.form.addressLabel')} *{' '}
                    <span className="text-ink-soft font-normal">{t('service.form.addressHint')}</span>
                  </label>
                  <input className="input" placeholder={t('service.form.addressPlaceholder')} value={address}
                         onChange={(e) => setAddress(e.target.value)} />
                </div>
              )}
            </>
          )}
        </div>

        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2 sticky bottom-0 bg-card">
          <button onClick={onClose} className="px-3 py-1.5 text-sm rounded-button hover:bg-black/5">
            {t('actions.cancel')}
          </button>
          <button onClick={handleSave} disabled={saving || !order} className="btn-primary disabled:opacity-50">
            {saving ? t('service.form.saving') : t('service.form.submit')}
          </button>
        </div>
      </div>
    </div>
  );
}
