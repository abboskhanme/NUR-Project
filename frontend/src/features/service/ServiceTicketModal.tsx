import { useEffect, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { X, Search, Check, Package, PackageX } from 'lucide-react';

import { api } from '@/api/client';
import { formatDate, formatPhone } from '@/lib/format';
import { computeWarranty, WARRANTY_META } from '@/features/service/warranty';
import LocationInput from '@/features/service/LocationInput';

interface Customer { id: string; full_name: string; phone: string; address?: string | null }
interface SearchHit {
  customer_id: string; full_name: string; phone: string; address?: string | null;
  order_id?: string | null; order_code?: string | null; product_summary?: string | null;
}
interface Order {
  id: string; code: string; delivered_at?: string | null; status: string;
  delivery_address?: string | null; product_summary?: string | null;
}
interface Category { id: string; name: string }
// Mijozning oldingi arizalari — buyurtmasiz arizada mahsulot ma'lumotini
// qayta yozdirmaslik uchun (oxirgi "0 dan" arizadan olinadi).
interface PrevTicket {
  id: string; is_external?: boolean; ext_product?: string | null;
  purchase_date?: string | null; ext_seller?: string | null; serial_id?: string | null;
}

const MODELS_LIST_ID = 'svc-ticket-models';

export default function ServiceTicketModal({
  onClose, onSaved,
}: { onClose: () => void; onSaved: () => void }) {
  const [search, setSearch] = useState('');
  const [debounced, setDebounced] = useState('');
  const [customer, setCustomer] = useState<Customer | null>(null);
  const [order, setOrder] = useState<Order | null>(null);
  // Buyurtma ID bo'yicha topilganda — mijoz tanlangach shu buyurtmani avtomatik tanlash
  const [pendingOrderId, setPendingOrderId] = useState<string | null>(null);
  const [problem, setProblem] = useState('');
  const [category, setCategory] = useState('');
  const [address, setAddress] = useState('');
  // Borish lokatsiyasi (ixtiyoriy) — havola/koordinata
  const [locRaw, setLocRaw] = useState('');
  const [locNote, setLocNote] = useState('');
  const [saving, setSaving] = useState(false);
  // Buyurtmasiz ("0 dan") ariza — mijoz bizdan emas, dillerdan olgan bo'lsa
  const [noOrder, setNoOrder] = useState(false);
  const [extProduct, setExtProduct] = useState('');
  const [extSerial, setExtSerial] = useState('');
  const [extSeller, setExtSeller] = useState('');
  const [purchaseDate, setPurchaseDate] = useState('');
  const [warrantyOverride, setWarrantyOverride] = useState<boolean | null>(null);

  useEffect(() => {
    const timer = setTimeout(() => setDebounced(search.trim()), 300);
    return () => clearTimeout(timer);
  }, [search]);

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  const customersQ = useQuery<SearchHit[]>({
    queryKey: ['svc-cust-search', debounced],
    queryFn: () => api.get('/service/customer-search', { params: { q: debounced } }).then((r) => r.data),
    enabled: !customer && debounced.length >= 1,
  });
  const hits = customersQ.data ?? [];

  const ordersQ = useQuery<Order[]>({
    queryKey: ['svc-cust-orders', customer?.id],
    queryFn: () => api.get('/service/orders', {
      params: { customer_id: customer!.id },
    }).then((r) => r.data),
    enabled: !!customer,
  });
  const orders = ordersQ.data ?? [];

  // Buyurtma ID bo'yicha topilgan bo'lsa — mijoz buyurtmalari yuklangach o'shani tanlaymiz
  useEffect(() => {
    if (!pendingOrderId) return;
    const found = orders.find((o) => o.id === pendingOrderId);
    if (found) {
      setOrder(found);
      setAddress('');
      setPendingOrderId(null);
    }
  }, [orders, pendingOrderId]);

  const categoriesQ = useQuery<Category[]>({
    queryKey: ['service-categories'],
    queryFn: () => api.get('/service/categories').then((r) => r.data),
  });
  const categories = categoriesQ.data ?? [];

  // Mijozning oldingi arizalari — oxirgi "0 dan" arizadagi mahsulot ma'lumoti
  const prevQ = useQuery<{ items: PrevTicket[] }>({
    queryKey: ['svc-cust-tickets', customer?.id],
    queryFn: () => api.get('/service/tickets', {
      params: { customer_id: customer!.id, page_size: 20 },
    }).then((r) => r.data),
    enabled: !!customer,
  });
  const prevExt = (prevQ.data?.items ?? []).find((t) => t.is_external) ?? null;

  const modelsQ = useQuery<string[]>({
    queryKey: ['service-product-models'],
    queryFn: () => api.get('/service/product-models').then((r) => r.data),
    enabled: noOrder,
  });
  const models = modelsQ.data ?? [];

  const orderHasAddress = !!(order?.delivery_address && order.delivery_address.trim());
  const needAddress = noOrder || (!!order && !orderHasAddress);

  // Buyurtmasiz arizada kafolat sotib olingan sanadan hisoblanadi
  const extW = computeWarranty(purchaseDate || null);
  const autoWarranty = extW.status === 'active_full' || extW.status === 'active_service_only';
  const extInWarranty = warrantyOverride ?? autoWarranty;

  function enterNoOrder() {
    setOrder(null);
    setNoOrder(true);
    setPendingOrderId(null);
    setExtProduct(prevExt?.ext_product ?? '');
    setExtSerial(prevExt?.serial_id ?? '');
    setExtSeller(prevExt?.ext_seller ?? '');
    setPurchaseDate(prevExt?.purchase_date ?? '');
    setWarrantyOverride(null);
    setAddress(customer?.address ?? '');
  }

  function exitNoOrder() {
    setNoOrder(false);
    setAddress('');
  }

  // Oldingi ariza ma'lumoti kechroq yuklansa ham (sekin internet) — bo'sh
  // maydonlarni to'ldiramiz. Operator yozgan qiymat ustidan yozilmaydi.
  useEffect(() => {
    if (!noOrder || !prevExt) return;
    setExtProduct((v) => v || prevExt.ext_product || '');
    setExtSerial((v) => v || prevExt.serial_id || '');
    setExtSeller((v) => v || prevExt.ext_seller || '');
    setPurchaseDate((v) => v || prevExt.purchase_date || '');
  }, [noOrder, prevExt?.id]);

  function pickHit(h: SearchHit) {
    setCustomer({ id: h.customer_id, full_name: h.full_name, phone: h.phone, address: h.address ?? null });
    setSearch(h.full_name);
    setOrder(null);
    setAddress('');
    setNoOrder(false);
    // Buyurtma ID bo'yicha topilgan bo'lsa — o'sha buyurtmani avtomatik tanlaymiz
    setPendingOrderId(h.order_id ?? null);
  }

  // Warranty label helpers — literal o'zbekcha matnlar
  function warrantyShort(status: string): string {
    return status === 'active_full' ? '1-yil — bepul'
      : status === 'active_service_only' ? '2–3-yil — faqat ish'
      : status === 'expired' ? 'Kafolat tugagan'
      : 'Yetkazilmagan';
  }

  function warrantyLong(status: string): string {
    return status === 'active_full' ? '1-yil kafolat — ish va ehtiyot qism bepul'
      : status === 'active_service_only' ? '2–3-yil kafolat — faqat ish bepul, ehtiyot qism mijoz hisobidan'
      : status === 'expired' ? 'Kafolat muddati tugagan — xizmat va ehtiyot qism mijoz hisobidan'
      : 'Mahsulot hali yetkazilmagan — kafolat boshlanmagan';
  }

  async function handleSave() {
    if (!customer) { toast.error('Mijozni tanlang'); return; }
    if (!order && !noOrder) { toast.error('Buyurtmani tanlang'); return; }
    if (!problem.trim() && !category) { toast.error('Muammo yozing yoki toifani tanlang'); return; }
    if (needAddress && !address.trim()) { toast.error('Manzilni kiriting'); return; }
    setSaving(true);
    try {
      if (noOrder) {
        // Buyurtmasiz ariza — mavjud mijozga "0 dan" ariza
        await api.post('/service/tickets/external', {
          customer_id: customer.id,
          address: address.trim(),
          ext_product: extProduct.trim() || null,
          serial_id: extSerial.trim() || null,
          purchase_date: purchaseDate || null,
          ext_seller: extSeller.trim() || null,
          problem: problem.trim() || category,
          category: category || null,
          in_warranty: extInWarranty,
          location_raw: locRaw.trim() || null,
          location_note: locNote.trim() || null,
        });
        toast.success('Ariza yaratildi');
        onSaved();
        onClose();
        return;
      }
      await api.post('/service/tickets', {
        customer_id: customer.id,
        order_id: order!.id,
        problem: problem.trim() || category,
        category: category || null,
        address: needAddress ? address.trim() : null,
        location_raw: locRaw.trim() || null,
        location_note: locNote.trim() || null,
      });
      toast.success('Ariza yaratildi');
      onSaved();
      onClose();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || 'Xatolik yuz berdi');
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
          <h3 className="font-semibold">Yangi servis arizasi</h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5"><X size={18} /></button>
        </div>

        <div className="p-5 space-y-4">
          {/* 1. Customer search */}
          <div>
            <label className="label">Mijoz *</label>
            <div className="relative">
              <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-ink-soft" />
              <input
                className="input pl-9"
                placeholder="Ism, telefon yoki buyurtma ID bo'yicha qidiring…"
                value={search}
                onChange={(e) => { setSearch(e.target.value); setCustomer(null); setOrder(null); setPendingOrderId(null); setNoOrder(false); }}
              />
            </div>
            {!customer && debounced.length >= 1 && hits.length > 0 && (
              <div className="mt-1 border border-black/10 rounded-button divide-y divide-black/5 overflow-hidden">
                {hits.map((h, i) => (
                  <button key={`${h.customer_id}-${h.order_id ?? i}`} type="button" onClick={() => pickHit(h)}
                    className="w-full text-left px-3 py-2 hover:bg-black/5 text-sm flex items-center justify-between gap-2">
                    <span className="min-w-0">
                      <span className="block font-medium truncate">{h.full_name}</span>
                      <span className="block text-xs text-ink-soft">{formatPhone(h.phone)}</span>
                    </span>
                    {h.order_code && (
                      <span className="badge bg-primary/10 text-primary shrink-0 inline-flex items-center gap-1">
                        <Package size={12} /> {h.order_code}
                      </span>
                    )}
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
          {customer && !noOrder && (
            <div>
              <label className="label">
                Buyurtmani tanlang *{' '}
                <span className="text-ink-soft font-normal">(kafolat shu zakaz bo'yicha)</span>
              </label>
              {ordersQ.isLoading ? (
                <div className="space-y-1.5">
                  {Array.from({ length: 3 }).map((_, i) => <div key={i} className="h-12 rounded-button bg-black/5 animate-pulse" />)}
                </div>
              ) : orders.length === 0 ? (
                <div className="text-sm bg-black/[0.03] rounded-button p-3 flex flex-wrap items-center justify-between gap-2">
                  <span className="text-ink-soft">Bu mijozda buyurtma topilmadi.</span>
                  <button type="button" onClick={enterNoOrder}
                          className="btn-action bg-primary/10 text-primary hover:bg-primary/20">
                    <PackageX size={15} /> Buyurtmasiz ariza
                  </button>
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
                                Yetkazildi: {formatDate(o.delivered_at)}
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
              {orders.length > 0 && (
                <button type="button" onClick={enterNoOrder}
                        className="mt-1.5 text-xs text-ink-soft hover:text-primary underline underline-offset-2">
                  Mahsulot bizdan olinmagan — buyurtmasiz ariza
                </button>
              )}
            </div>
          )}

          {/* 2b. Buyurtmasiz ("0 dan") ariza — mahsulot ma'lumoti qo'lda */}
          {customer && noOrder && (
            <div className="rounded-button border border-primary/25 bg-primary/[0.06] p-3 space-y-3">
              <div className="flex items-center justify-between gap-2">
                <div className="text-sm font-medium inline-flex items-center gap-1.5">
                  <PackageX size={15} /> Buyurtmasiz ariza
                </div>
                <button type="button" onClick={exitNoOrder}
                        className="text-xs text-ink-soft hover:text-primary underline underline-offset-2">
                  Buyurtma tanlashga qaytish
                </button>
              </div>
              {prevExt && (
                <div className="text-xs text-ink-soft">
                  Mahsulot ma'lumoti oldingi arizadan olindi — kerak bo'lsa o'zgartiring.
                </div>
              )}

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="label">Qanday model olgan</label>
                  <input className="input" list={MODELS_LIST_ID} value={extProduct}
                         placeholder="Masalan: OPTIMA 400 kvm"
                         onChange={(e) => setExtProduct(e.target.value)} />
                  <datalist id={MODELS_LIST_ID}>
                    {models.map((m) => <option key={m} value={m} />)}
                  </datalist>
                </div>
                <div>
                  <label className="label">Seriya / ID raqami</label>
                  <input className="input" value={extSerial} onChange={(e) => setExtSerial(e.target.value)} />
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="label">Sotib olingan sana</label>
                  <input type="date" className="input" value={purchaseDate}
                         onChange={(e) => setPurchaseDate(e.target.value)} />
                </div>
                <div>
                  <label className="label">Qayerdan olgan</label>
                  <input className="input" placeholder="Diller yoki do'kon nomi"
                         value={extSeller} onChange={(e) => setExtSeller(e.target.value)} />
                </div>
              </div>

              {purchaseDate && (
                <div className={`rounded-button p-2.5 text-sm ${WARRANTY_META[extW.status].cls}`}>
                  {warrantyLong(extW.status)}
                  {extW.status === 'active_full' && extW.daysYear1 > 0 && <> {`· ${extW.daysYear1} kun qoldi`}</>}
                  {extW.status === 'active_service_only' && extW.daysYear3 > 0 && <> {`· ${extW.daysYear3} kun qoldi`}</>}
                </div>
              )}
              <label className="flex items-center gap-2 cursor-pointer select-none">
                <input type="checkbox" className="h-4 w-4 accent-primary" checked={extInWarranty}
                       onChange={(e) => setWarrantyOverride(e.target.checked)} />
                <span className="text-sm">
                  Kafolatda
                  <span className="text-ink-soft">
                    {' '}— {purchaseDate ? 'sanadan avtomatik' : 'sana kiritilmagan'}, o'zgartirish mumkin
                  </span>
                </span>
              </label>
            </div>
          )}

          {/* Selected order warranty */}
          {selW && (
            <div className={`rounded-button p-3 text-sm font-medium ${WARRANTY_META[selW.status].cls}`}>
              {warrantyLong(selW.status)}
              {selW.status === 'active_full' && selW.daysYear1 > 0 && (
                <> {`· ${selW.daysYear1} kun qoldi`}</>
              )}
              {selW.status === 'active_service_only' && selW.daysYear3 > 0 && (
                <> {`· ${selW.daysYear3} kun qoldi`}</>
              )}
            </div>
          )}

          {/* 3. Problem */}
          {(order || noOrder) && (
            <>
              <div>
                <label className="label">
                  Muammo{' '}
                  {category
                    ? <span className="text-ink-soft font-normal">(toifa tanlangan — ixtiyoriy)</span>
                    : '*'}
                </label>
                <textarea className="input min-h-[72px]" placeholder="Mijoz aytgan muammoni yozing…"
                          value={problem} onChange={(e) => setProblem(e.target.value)} />
              </div>

              {/* Category dropdown */}
              <div>
                <label className="label">Toifa</label>
                <select className="input" value={category} onChange={(e) => setCategory(e.target.value)}>
                  <option value="">— Tanlanmagan —</option>
                  {categories.map((c) => <option key={c.id} value={c.name}>{c.name}</option>)}
                </select>
                {categories.length === 0 && (
                  <div className="text-xs text-ink-soft mt-1">Toifalar yo'q — "Toifalar" bo'limidan qo'shing.</div>
                )}
              </div>

              {/* Address — only if order has no address */}
              {needAddress && (
                <div>
                  <label className="label">
                    Manzil *{' '}
                    <span className="text-ink-soft font-normal">
                      {noOrder ? '(servis boradigan manzil)' : "(buyurtmada manzil ko'rsatilmagan)"}
                    </span>
                  </label>
                  <input className="input" placeholder="Borish manzili" value={address}
                         onChange={(e) => setAddress(e.target.value)} />
                </div>
              )}

              <LocationInput raw={locRaw} note={locNote} onRaw={setLocRaw} onNote={setLocNote} />
            </>
          )}
        </div>

        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2 sticky bottom-0 bg-card">
          <button onClick={onClose} className="px-3 py-1.5 text-sm rounded-button hover:bg-black/5">
            Bekor qilish
          </button>
          <button onClick={handleSave} disabled={saving || (!order && !noOrder)} className="btn-primary disabled:opacity-50">
            {saving ? 'Saqlanmoqda…' : 'Ariza yaratish'}
          </button>
        </div>
      </div>
    </div>
  );
}
