import { useEffect, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import toast from 'react-hot-toast';
import { Camera, Trash2, X } from 'lucide-react';

import { api } from '@/api/client';

export type ProductType = 'main' | 'additional' | 'warehouse';

export interface ProductFull {
  id: string;
  product_type: ProductType;
  model?: string | null;
  kvm?: number | null;
  name?: string | null;
  unit?: string | null;
  sku?: string | null;
  description?: string | null;
  base_price_usd: string;
  status: string;
  has_image?: boolean;
}

const MAX_IMAGE_BYTES = 5 * 1024 * 1024;

const UNITS = ['dona', 'metr', 'komplekt', 'kg', 'litr'];

const num = (s: string) => {
  const n = parseFloat(s); return Number.isNaN(n) ? 0 : n;
};

export default function ProductModal({
  product,
  defaultType,
  onClose,
  onSaved,
}: {
  product: ProductFull | null;
  defaultType: ProductType;
  onClose: () => void;
  onSaved: () => void;
}) {
  const { t } = useTranslation();
  const isCreate = product === null;
  const type: ProductType = product?.product_type ?? defaultType;

  const [model, setModel] = useState(product?.model ?? '');
  const [kvm, setKvm] = useState(product?.kvm != null ? String(product.kvm) : '');
  const [name, setName] = useState(product?.name ?? '');
  const [unit, setUnit] = useState(product?.unit ?? 'dona');
  const [price, setPrice] = useState(product ? String(num(product.base_price_usd)) : '');
  const [description, setDescription] = useState(product?.description ?? '');
  const [saving, setSaving] = useState(false);

  // 'warehouse' (ombor turi) ham kotyol modeli kabi — model + kvm bilan kiritiladi.
  const isAdditional = type === 'additional';

  // --- Rasm (faqat qo'shimcha mahsulot uchun) ---
  const fileRef = useRef<HTMLInputElement>(null);
  const [imageFile, setImageFile] = useState<File | null>(null); // saqlashda yuklanadi
  const [preview, setPreview] = useState<string | null>(null);   // tanlangan faylning URL'i
  const [existingUrl, setExistingUrl] = useState<string | null>(null); // mavjud rasm
  const [removeExisting, setRemoveExisting] = useState(false);

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  // Tahrirlashda mavjud rasmni yuklab ko'rsatamiz (auth talab qiladi — blob orqali)
  useEffect(() => {
    if (!isAdditional || !product?.has_image) return;
    let obj: string | null = null;
    let alive = true;
    api.get(`/products/${product.id}/image`, { responseType: 'blob' })
      .then((r) => { if (alive) { obj = URL.createObjectURL(r.data); setExistingUrl(obj); } })
      .catch(() => {});
    return () => { alive = false; if (obj) URL.revokeObjectURL(obj); };
  }, [isAdditional, product]);

  function pickImage(file: File) {
    if (!file.type.startsWith('image/')) { toast.error(t('products.modal.imageOnlyImage')); return; }
    if (file.size > MAX_IMAGE_BYTES) { toast.error(t('products.modal.imageTooLarge')); return; }
    setPreview((old) => { if (old) URL.revokeObjectURL(old); return URL.createObjectURL(file); });
    setImageFile(file);
    setRemoveExisting(false);
  }

  function clearImage() {
    if (preview) { URL.revokeObjectURL(preview); setPreview(null); }
    setImageFile(null);
    if (existingUrl) { setRemoveExisting(true); }
  }

  const shownImage = preview || (removeExisting ? null : existingUrl);

  async function handleSave() {
    if (!isAdditional && !model.trim()) {
      toast.error(t('products.modal.modelRequired'));
      return;
    }
    if (isAdditional && !name.trim()) {
      toast.error(t('products.modal.nameRequired'));
      return;
    }

    const body: Record<string, unknown> = {
      product_type: type,
      base_price_usd: num(price),
      description: description.trim() || null,
    };
    if (!isAdditional) {
      body.model = model.trim();
      body.kvm = kvm.trim() ? parseInt(kvm, 10) : null;
      body.name = null;
      body.unit = null;
    } else {
      body.name = name.trim();
      body.unit = unit || null;
      body.model = null;
      body.kvm = null;
    }

    setSaving(true);
    try {
      let pid = product?.id;
      if (isCreate) {
        const { data } = await api.post('/products', body);
        pid = data.id;
      } else {
        await api.patch(`/products/${product!.id}`, body);
      }

      // Rasm: yangi tanlangan bo'lsa yuklaymiz, yoki mavjud rasm o'chirilgan bo'lsa olib tashlaymiz.
      if (isAdditional && pid) {
        if (imageFile) {
          const form = new FormData();
          form.append('file', imageFile);
          await api.post(`/products/${pid}/image`, form, {
            headers: { 'Content-Type': 'multipart/form-data' },
          });
        } else if (removeExisting && !isCreate) {
          await api.delete(`/products/${pid}/image`);
        }
      }

      toast.success(isCreate ? t('products.modal.toastAdded') : t('products.modal.toastUpdated'));
      onSaved();
      onClose();
    } catch (e: any) {
      toast.error(e?.response?.data?.detail || t('products.modal.toastError'));
    } finally {
      setSaving(false);
    }
  }

  const modalTitle = isCreate
    ? (isAdditional ? t('products.modal.createAdditional') : t('products.modal.createMain'))
    : (isAdditional ? t('products.modal.editAdditional') : t('products.modal.editMain'));

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div className="bg-card rounded-lg shadow-xl w-full max-w-lg max-h-[92vh] overflow-hidden flex flex-col"
           onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/5 shrink-0">
          <h3 className="font-semibold">{modalTitle}</h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5" aria-label={t('common.close')}>
            <X size={18} />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto p-5 space-y-4">
          {!isAdditional ? (
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="label">{t('products.modal.modelLabel')}</label>
                <input className="input" placeholder={t('products.modal.modelPlaceholder')} value={model}
                       onChange={(e) => setModel(e.target.value)} />
              </div>
              <div>
                <label className="label">{t('products.modal.kvmLabel')}</label>
                <input type="number" min={0} className="input" placeholder={t('products.modal.kvmPlaceholder')} value={kvm}
                       onChange={(e) => setKvm(e.target.value)} />
              </div>
            </div>
          ) : (
            <div className="grid grid-cols-2 gap-3">
              <div className="col-span-2">
                <label className="label">{t('products.modal.nameLabel')}</label>
                <input className="input" placeholder={t('products.modal.namePlaceholder')} value={name}
                       onChange={(e) => setName(e.target.value)} />
              </div>
              <div>
                <label className="label">{t('products.modal.unitLabel')}</label>
                <select className="input" value={unit} onChange={(e) => setUnit(e.target.value)}>
                  {UNITS.map((u) => <option key={u} value={u}>{u}</option>)}
                </select>
              </div>
            </div>
          )}

          <div>
            <label className="label">{t('products.modal.priceLabel')}</label>
            <input type="text" inputMode="decimal" className="input" placeholder={t('products.modal.pricePlaceholder')}
                   value={price}
                   onChange={(e) => setPrice(e.target.value.replace(/[^\d.]/g, ''))} />
          </div>

          <div>
            <label className="label">{t('products.modal.descriptionLabel')}</label>
            <textarea className="input min-h-[56px]" value={description}
                      onChange={(e) => setDescription(e.target.value)} />
          </div>

          {isAdditional && (
            <div>
              <label className="label">{t('products.modal.imageLabel')}</label>
              <div className="flex items-center gap-3">
                {shownImage ? (
                  <img src={shownImage} alt=""
                       className="w-20 h-20 rounded object-cover border border-black/10" />
                ) : (
                  <div className="w-20 h-20 rounded bg-black/5 flex items-center justify-center text-ink-soft">
                    <Camera size={22} />
                  </div>
                )}
                <div className="flex flex-col gap-2">
                  <button type="button" onClick={() => fileRef.current?.click()}
                          className="flex items-center gap-2 px-3 py-1.5 text-sm rounded-button border border-black/10 hover:bg-black/5">
                    <Camera size={14} /> {t('products.modal.imageUpload')}
                  </button>
                  {shownImage && (
                    <button type="button" onClick={clearImage}
                            className="flex items-center gap-2 px-3 py-1.5 text-sm rounded-button text-danger hover:bg-danger/5">
                      <Trash2 size={14} /> {t('products.modal.imageRemove')}
                    </button>
                  )}
                  <p className="text-xs text-ink-soft">{t('products.modal.imageHint')}</p>
                </div>
                <input ref={fileRef} type="file"
                       accept="image/png,image/jpeg,image/jpg,image/webp,image/gif"
                       className="hidden"
                       onChange={(e) => {
                         const f = e.target.files?.[0];
                         if (f) pickImage(f);
                         e.target.value = '';
                       }} />
              </div>
            </div>
          )}

          {!isAdditional && (
            <p className="text-xs text-ink-soft">
              {t('products.modal.directionHint')}
            </p>
          )}
        </div>

        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2 shrink-0">
          <button onClick={onClose} className="px-3 py-1.5 text-sm rounded-button hover:bg-black/5">
            {t('actions.cancel')}
          </button>
          <button onClick={handleSave} disabled={saving} className="btn-primary disabled:opacity-50">
            {saving ? t('products.modal.saving') : t('actions.save')}
          </button>
        </div>
      </div>
    </div>
  );
}
