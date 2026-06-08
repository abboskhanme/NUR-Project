import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import toast from 'react-hot-toast';
import { X } from 'lucide-react';

import { api } from '@/api/client';
import PhoneInput from '@/components/ui/PhoneInput';
import Select from '@/components/ui/Select';
import { CENTRAL_ASIA, regionsOf } from '@/lib/centralAsia';

const TWEMOJI_BASE = 'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/svg';
const flagIcon = (codes: string) => (
  <img src={`${TWEMOJI_BASE}/${codes}.svg`} alt="" loading="lazy"
       className="w-[22px] h-4 rounded-sm object-cover shrink-0" />
);

export interface CustomerFull {
  id: string;
  full_name: string;
  phone: string;
  phone2?: string | null;
  country?: string;
  region?: string | null;
  city?: string | null;
  address?: string | null;
  source?: string | null;
  note?: string | null;
  is_dealer?: boolean;
}

export default function CustomerModal({
  customer,
  onClose,
  onSaved,
}: {
  customer: CustomerFull | null;
  onClose: () => void;
  onSaved: () => void;
}) {
  const { t } = useTranslation();
  const isCreate = customer === null;

  const [fullName, setFullName] = useState(customer?.full_name ?? '');
  const [phone, setPhone] = useState(customer?.phone ?? '');
  const [phone2, setPhone2] = useState(customer?.phone2 ?? '');
  const [country, setCountry] = useState(customer?.country ?? 'Uzbekistan');
  const [region, setRegion] = useState(customer?.region ?? '');
  const [city, setCity] = useState(customer?.city ?? '');
  const [address, setAddress] = useState(customer?.address ?? '');
  const [note, setNote] = useState(customer?.note ?? '');
  const [isDealer, setIsDealer] = useState(customer?.is_dealer ?? false);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  async function handleSave() {
    if (!fullName.trim()) {
      toast.error(t('customers.modal.fullNameRequired'));
      return;
    }
    if (!phone.trim()) {
      toast.error(t('customers.modal.phoneRequired'));
      return;
    }
    setSaving(true);
    const body: Record<string, unknown> = {
      full_name: fullName.trim(),
      phone: phone.trim(),
      phone2: phone2.trim() || null,
      country: country.trim() || 'Uzbekistan',
      region: region.trim() || null,
      city: city.trim() || null,
      address: address.trim() || null,
      note: note.trim() || null,
      is_dealer: isDealer,
    };
    try {
      if (isCreate) {
        await api.post('/customers', body);
        toast.success(t('customers.modal.toastAdded'));
      } else {
        await api.patch(`/customers/${customer!.id}`, body);
        toast.success(t('customers.modal.toastUpdated'));
      }
      onSaved();
      onClose();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || t('customers.modal.toastError'));
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div className="bg-card rounded-lg shadow-xl w-full max-w-xl max-h-[92vh] overflow-hidden flex flex-col"
           onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/5 shrink-0">
          <h3 className="font-semibold">
            {isCreate ? t('customers.modal.createTitle') : t('customers.modal.editTitle')}
          </h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5" aria-label={t('common.close')}>
            <X size={18} />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto p-5 space-y-4">
          <div>
            <label className="label">{t('customers.modal.fullNameLabel')}</label>
            <input className="input" value={fullName} onChange={(e) => setFullName(e.target.value)} />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="label">{t('customers.modal.phoneLabel')}</label>
              <PhoneInput value={phone} onChange={setPhone} />
            </div>
            <div>
              <label className="label">{t('customers.modal.phone2Label')}</label>
              <PhoneInput value={phone2} onChange={setPhone2} />
            </div>
          </div>

          <div className="grid grid-cols-3 gap-3">
            <div>
              <label className="label">{t('customers.modal.countryLabel')}</label>
              <Select
                value={country}
                onChange={(v) => { setCountry(v); setRegion(''); }}
                options={CENTRAL_ASIA.map((c) => ({
                  value: c.value, label: c.label, icon: flagIcon(c.flagCodes),
                }))}
              />
            </div>
            <div>
              <label className="label">{t('customers.modal.regionLabel')}</label>
              <Select
                value={region}
                onChange={setRegion}
                allowEmpty
                placeholder="—"
                options={[
                  ...(region && !regionsOf(country).includes(region)
                    ? [{ value: region, label: region }] : []),
                  ...regionsOf(country).map((r) => ({ value: r, label: r })),
                ]}
              />
            </div>
            <div>
              <label className="label">{t('customers.modal.cityLabel')}</label>
              <input className="input" value={city} onChange={(e) => setCity(e.target.value)} />
            </div>
          </div>

          <div>
            <label className="label">{t('customers.modal.addressLabel')}</label>
            <textarea className="input min-h-[56px]" value={address} onChange={(e) => setAddress(e.target.value)} />
          </div>

          <div>
            <label className="label">{t('customers.modal.noteLabel')}</label>
            <textarea className="input min-h-[56px]" value={note} onChange={(e) => setNote(e.target.value)} />
          </div>

          <label className="flex items-center gap-2 cursor-pointer select-none">
            <input type="checkbox" className="h-4 w-4 accent-primary"
                   checked={isDealer} onChange={(e) => setIsDealer(e.target.checked)} />
            <span className="text-sm">{t('customers.modal.dealerLabel')}</span>
          </label>
        </div>

        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2 shrink-0">
          <button onClick={onClose} className="px-3 py-1.5 text-sm rounded-button hover:bg-black/5">
            {t('actions.cancel')}
          </button>
          <button onClick={handleSave} disabled={saving} className="btn-primary disabled:opacity-50">
            {saving ? t('customers.modal.saving') : t('actions.save')}
          </button>
        </div>
      </div>
    </div>
  );
}
