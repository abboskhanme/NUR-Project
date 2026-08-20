import { useEffect, useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { X, Info, UserPlus } from 'lucide-react';

import { api } from '@/api/client';
import PhoneInput from '@/components/ui/PhoneInput';
import Select from '@/components/ui/Select';
import { CENTRAL_ASIA, regionsOf } from '@/lib/centralAsia';
import { formatPhone } from '@/lib/format';
import { computeWarranty, WARRANTY_META } from '@/features/service/warranty';
import LocationInput from '@/features/service/LocationInput';

const TWEMOJI_BASE = 'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/svg';
const flagIcon = (codes: string) => (
  <img src={`${TWEMOJI_BASE}/${codes}.svg`} alt="" loading="lazy"
       className="w-[22px] h-4 rounded-sm object-cover shrink-0" />
);

const OTHER = '__other__';

interface Category { id: string; name: string }
interface SearchHit { customer_id: string; full_name: string; phone: string }

/**
 * "0 dan" servis arizasi — bizning bazada buyurtmasi yo'q mijoz uchun
 * (masalan dillerdan sotib olganlar). Mijozning barcha ma'lumotlari qo'lda
 * kiritiladi, kafolat sotib olingan sanadan hisoblanadi.
 */
export default function ExternalTicketModal({
  onClose, onSaved,
}: { onClose: () => void; onSaved: () => void }) {
  // Mijoz
  const [fullName, setFullName] = useState('');
  const [phone, setPhone] = useState('');
  const [phone2, setPhone2] = useState('');
  const [country, setCountry] = useState('Uzbekistan');
  const [region, setRegion] = useState('');
  const [city, setCity] = useState('');
  const [address, setAddress] = useState('');
  // Borish lokatsiyasi (ixtiyoriy) — havola/koordinata; keyin kartochkadan ham qo'shsa bo'ladi
  const [locRaw, setLocRaw] = useState('');
  const [locNote, setLocNote] = useState('');
  // Mahsulot
  const [modelPick, setModelPick] = useState('');
  const [modelOther, setModelOther] = useState('');
  const [serial, setSerial] = useState('');
  const [purchaseDate, setPurchaseDate] = useState('');
  const [seller, setSeller] = useState('');
  // Ariza
  const [problem, setProblem] = useState('');
  const [category, setCategory] = useState('');
  const [warrantyOverride, setWarrantyOverride] = useState<boolean | null>(null);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  const categoriesQ = useQuery<Category[]>({
    queryKey: ['service-categories'],
    queryFn: () => api.get('/service/categories').then((r) => r.data),
  });
  const categories = categoriesQ.data ?? [];

  const modelsQ = useQuery<string[]>({
    queryKey: ['service-product-models'],
    queryFn: () => api.get('/service/product-models').then((r) => r.data),
  });
  const models = modelsQ.data ?? [];

  // Telefon raqami bazada bormi — dublikat mijoz yaratilmasligi haqida ogohlantirish
  const phoneDigits = phone.replace(/\D/g, '');
  const [debouncedPhone, setDebouncedPhone] = useState('');
  useEffect(() => {
    const timer = setTimeout(() => setDebouncedPhone(phoneDigits), 400);
    return () => clearTimeout(timer);
  }, [phoneDigits]);

  const dupQ = useQuery<SearchHit[]>({
    queryKey: ['svc-ext-dup', debouncedPhone],
    queryFn: () => api.get('/service/customer-search', {
      params: { q: debouncedPhone },
    }).then((r) => r.data),
    enabled: debouncedPhone.length >= 7,
  });
  const duplicate = useMemo(() => {
    const hits = dupQ.data ?? [];
    return hits.find((h) => h.phone.replace(/\D/g, '') === debouncedPhone) ?? null;
  }, [dupQ.data, debouncedPhone]);

  // Kafolat — sotib olingan sanadan avtomatik, qo'lda o'zgartirsa bo'ladi
  const w = computeWarranty(purchaseDate || null);
  const autoWarranty = w.status === 'active_full' || w.status === 'active_service_only';
  const inWarranty = warrantyOverride ?? autoWarranty;

  const model = modelPick === OTHER ? modelOther.trim() : modelPick;

  async function handleSave() {
    if (!fullName.trim()) { toast.error('Ism-familiya majburiy'); return; }
    if (!phone.trim()) { toast.error('Telefon raqami majburiy'); return; }
    if (!address.trim()) { toast.error('Manzilni kiriting'); return; }
    if (!problem.trim() && !category) { toast.error('Muammo yozing yoki toifani tanlang'); return; }
    setSaving(true);
    try {
      await api.post('/service/tickets/external', {
        full_name: fullName.trim(),
        phone: phone.trim(),
        phone2: phone2.trim() || null,
        country: country || 'Uzbekistan',
        region: region || null,
        city: city.trim() || null,
        address: address.trim(),
        ext_product: model || null,
        serial_id: serial.trim() || null,
        purchase_date: purchaseDate || null,
        ext_seller: seller.trim() || null,
        problem: problem.trim() || category,
        category: category || null,
        in_warranty: inWarranty,
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

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div className="bg-card rounded-lg shadow-xl w-full max-w-2xl max-h-[90vh] flex flex-col"
           onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/5 shrink-0">
          <div>
            <h3 className="font-semibold flex items-center gap-2"><UserPlus size={17} /> 0 dan ariza</h3>
            <p className="text-xs text-ink-soft">Bizning bazada buyurtmasi yo'q mijoz (masalan dillerdan olgan)</p>
          </div>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5" aria-label="Yopish">
            <X size={18} />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto p-5 space-y-5">
          {/* --- 1. Mijoz --- */}
          <div className="space-y-3">
            <div className="text-xs font-semibold text-ink-soft uppercase tracking-wide">Mijoz</div>

            <div>
              <label className="label">Ism familiya *</label>
              <input className="input" value={fullName} placeholder="Masalan: Aliyev Alisher"
                     onChange={(e) => setFullName(e.target.value)} />
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div>
                <label className="label">Telefon *</label>
                <PhoneInput value={phone} onChange={setPhone} />
              </div>
              <div>
                <label className="label">Qo'shimcha telefon</label>
                <PhoneInput value={phone2} onChange={setPhone2} />
              </div>
            </div>

            {duplicate && (
              <div className="rounded-button bg-amber-50 text-amber-800 p-3 text-sm flex gap-2">
                <Info size={16} className="shrink-0 mt-0.5" />
                <span>
                  Bu raqam bazada bor — <span className="font-medium">{duplicate.full_name}</span>{' '}
                  ({formatPhone(duplicate.phone)}). Ariza yangi mijoz yaratmasdan o'sha mijozga bog'lanadi.
                </span>
              </div>
            )}

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <div>
                <label className="label">Davlat</label>
                <Select
                  value={country}
                  onChange={(v) => { setCountry(v); setRegion(''); }}
                  options={CENTRAL_ASIA.map((c) => ({
                    value: c.value, label: c.label, icon: flagIcon(c.flagCodes),
                  }))}
                />
              </div>
              <div>
                <label className="label">Viloyat</label>
                <Select
                  value={region}
                  onChange={setRegion}
                  allowEmpty
                  placeholder="—"
                  options={regionsOf(country).map((r) => ({ value: r, label: r }))}
                />
              </div>
              <div>
                <label className="label">Shahar / tuman</label>
                <input className="input" value={city} onChange={(e) => setCity(e.target.value)} />
              </div>
            </div>

            <div>
              <label className="label">Manzil * <span className="text-ink-soft font-normal">(servis boradigan manzil)</span></label>
              <textarea className="input min-h-[56px]" value={address}
                        onChange={(e) => setAddress(e.target.value)} />
            </div>

            <LocationInput raw={locRaw} note={locNote} onRaw={setLocRaw} onNote={setLocNote} />
          </div>

          {/* --- 2. Mahsulot --- */}
          <div className="space-y-3 pt-1 border-t border-black/5">
            <div className="text-xs font-semibold text-ink-soft uppercase tracking-wide pt-3">Mahsulot</div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div>
                <label className="label">Qanday model olgan</label>
                <Select
                  value={modelPick}
                  onChange={setModelPick}
                  allowEmpty
                  placeholder="— Tanlang —"
                  options={[
                    ...models.map((m) => ({ value: m, label: m })),
                    { value: OTHER, label: "Boshqa (qo'lda yozish)" },
                  ]}
                />
                {modelPick === OTHER && (
                  <input className="input mt-2" placeholder="Model nomini yozing"
                         value={modelOther} onChange={(e) => setModelOther(e.target.value)} />
                )}
              </div>
              <div>
                <label className="label">Seriya / ID raqami</label>
                <input className="input" value={serial} onChange={(e) => setSerial(e.target.value)} />
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
                       value={seller} onChange={(e) => setSeller(e.target.value)} />
              </div>
            </div>

            {/* Kafolat — sanadan avtomatik, qo'lda o'zgartirish mumkin */}
            {purchaseDate && (
              <div className={`rounded-button p-3 text-sm ${WARRANTY_META[w.status].cls}`}>
                {WARRANTY_META[w.status].long}
                {w.status === 'active_full' && w.daysYear1 > 0 && <> {`· ${w.daysYear1} kun qoldi`}</>}
                {w.status === 'active_service_only' && w.daysYear3 > 0 && <> {`· ${w.daysYear3} kun qoldi`}</>}
              </div>
            )}
            <label className="flex items-center gap-2 cursor-pointer select-none">
              <input type="checkbox" className="h-4 w-4 accent-primary" checked={inWarranty}
                     onChange={(e) => setWarrantyOverride(e.target.checked)} />
              <span className="text-sm">
                Kafolatda
                <span className="text-ink-soft">
                  {' '}— {purchaseDate ? 'sanadan avtomatik aniqlandi' : 'sana kiritilmagan'},
                  o'zgartirish mumkin
                </span>
              </span>
            </label>
          </div>

          {/* --- 3. Ariza --- */}
          <div className="space-y-3 pt-1 border-t border-black/5">
            <div className="text-xs font-semibold text-ink-soft uppercase tracking-wide pt-3">Ariza</div>

            <div>
              <label className="label">
                Muammo {category ? <span className="text-ink-soft font-normal">(toifa tanlangan — ixtiyoriy)</span> : '*'}
              </label>
              <textarea className="input min-h-[72px]" placeholder="Mijoz aytgan muammoni yozing…"
                        value={problem} onChange={(e) => setProblem(e.target.value)} />
            </div>

            <div>
              <label className="label">Toifa</label>
              <Select
                value={category}
                onChange={setCategory}
                allowEmpty
                placeholder="— Tanlanmagan —"
                options={categories.map((c) => ({ value: c.name, label: c.name }))}
              />
              {categories.length === 0 && (
                <div className="text-xs text-ink-soft mt-1">Toifalar yo'q — "Toifalar" bo'limidan qo'shing.</div>
              )}
            </div>
          </div>
        </div>

        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2 shrink-0">
          <button onClick={onClose} className="px-3 py-1.5 text-sm rounded-button hover:bg-black/5">
            Bekor qilish
          </button>
          <button onClick={handleSave} disabled={saving} className="btn-primary disabled:opacity-50">
            {saving ? 'Saqlanmoqda…' : 'Ariza yaratish'}
          </button>
        </div>
      </div>
    </div>
  );
}
