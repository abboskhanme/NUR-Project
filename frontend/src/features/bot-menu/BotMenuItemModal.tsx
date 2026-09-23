import { useEffect, useRef, useState } from 'react';
import toast from 'react-hot-toast';
import { ImagePlus, X } from 'lucide-react';

import { cn } from '@/lib/cn';
import BotMenuThumb from '@/features/bot-menu/BotMenuThumb';
import {
  botMenuApi, suggestCommand, CAPTION_LIMIT, IMAGE_ACCEPT, MAX_IMAGE_BYTES,
  MAX_IMAGES_PER_ITEM, MAX_TEXT_LENGTH, type BotMenuItem,
} from '@/features/bot-menu/api';

interface NewImage {
  key: string;
  file: File;
  url: string;
}

/**
 * Bo'lim qo'shish / tahrirlash. Rasmlar «Saqlash» bosilganda yuklanadi va
 * o'chiriladi (ProductModal bilan bir xil oqim) — bekor qilinsa hech narsa
 * o'zgarmaydi.
 */
export default function BotMenuItemModal({
  item, canDelete, onClose, onSaved,
}: {
  item: BotMenuItem | null;          // null — yangi bo'lim
  canDelete: boolean;                // mavjud rasmni o'chirish `telegram:delete` talab qiladi
  onClose: () => void;
  onSaved: () => void;
}) {
  const isCreate = !item;
  const [title, setTitle] = useState(item?.title ?? '');
  const [command, setCommand] = useState(item?.command ?? '');
  // Foydalanuvchi buyruqni o'zi yozmaguncha nomdan avtomatik taklif qilamiz
  const [commandTouched, setCommandTouched] = useState(!isCreate);
  const [text, setText] = useState(item?.text ?? '');
  const [isActive, setIsActive] = useState(item?.is_active ?? true);
  const [removed, setRemoved] = useState<Set<string>>(new Set());
  const [added, setAdded] = useState<NewImage[]>([]);
  const [saving, setSaving] = useState(false);
  const fileRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && !saving && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose, saving]);

  // Tanlangan fayllarning object URL'larini tozalash
  const addedRef = useRef(added);
  addedRef.current = added;
  useEffect(() => () => addedRef.current.forEach((a) => URL.revokeObjectURL(a.url)), []);

  const existing = (item?.images ?? []).filter((img) => !removed.has(img.id));
  const imageCount = existing.length + added.length;
  const hasImages = imageCount > 0;
  const trimmedText = text.trim();

  function onTitleChange(value: string) {
    setTitle(value);
    if (!commandTouched) setCommand(suggestCommand(value));
  }

  function pickFiles(files: FileList | null) {
    if (!files) return;
    const next: NewImage[] = [];
    for (const file of Array.from(files)) {
      if (!IMAGE_ACCEPT.split(',').includes(file.type)) {
        toast.error(`${file.name}: faqat JPEG, PNG yoki WEBP`);
        continue;
      }
      if (file.size > MAX_IMAGE_BYTES) {
        toast.error(`${file.name}: rasm 5 MB dan kichik bo‘lishi kerak`);
        continue;
      }
      if (imageCount + next.length >= MAX_IMAGES_PER_ITEM) {
        toast.error(`Bitta bo‘limga ko‘pi bilan ${MAX_IMAGES_PER_ITEM} ta rasm`);
        break;
      }
      next.push({ key: `${file.name}-${file.lastModified}-${Math.random()}`, file,
                  url: URL.createObjectURL(file) });
    }
    setAdded((prev) => [...prev, ...next]);
  }

  function dropAdded(key: string) {
    setAdded((prev) => {
      const target = prev.find((a) => a.key === key);
      if (target) URL.revokeObjectURL(target.url);
      return prev.filter((a) => a.key !== key);
    });
  }

  async function handleSave() {
    const cmd = command.trim().replace(/^\//, '').toLowerCase();
    if (!title.trim()) { toast.error('Tugma nomini kiriting'); return; }
    if (!/^[a-z0-9_]{1,32}$/.test(cmd)) {
      toast.error('Buyruq: faqat lotin kichik harf, raqam va _ (1-32 belgi)');
      return;
    }
    if (!trimmedText && !hasImages) {
      toast.error('Matn yoki kamida bitta rasm qo‘shing — aks holda mijozga hech narsa bormaydi');
      return;
    }

    setSaving(true);
    let itemId = item?.id;
    try {
      const body = { command: cmd, title: title.trim(), text: trimmedText || null, is_active: isActive };
      if (isCreate) {
        itemId = (await botMenuApi.create(body)).id;
      } else {
        await botMenuApi.update(item!.id, body);
      }
    } catch (e: any) {
      const detail = e?.response?.data?.detail;
      toast.error(typeof detail === 'string' ? detail : 'Saqlab bo‘lmadi');
      setSaving(false);
      return;
    }

    // Bo'lim saqlandi — rasmlarni alohida qayta ishlaymiz, biri yiqilsa ham
    // qolganlari davom etadi va foydalanuvchi aniq xabar oladi
    let failed = 0;
    for (const imageId of removed) {
      try { await botMenuApi.removeImage(imageId); } catch { failed += 1; }
    }
    for (const img of added) {
      try { await botMenuApi.uploadImage(itemId!, img.file); } catch { failed += 1; }
    }

    setSaving(false);
    onSaved();
    if (failed) {
      toast.error(`Bo‘lim saqlandi, lekin ${failed} ta rasm bilan xato bo‘ldi — qayta urinib ko‘ring`);
    } else {
      toast.success(isCreate ? 'Bo‘lim qo‘shildi' : 'Saqlandi');
    }
    onClose();
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
         onClick={() => !saving && onClose()}>
      <div className="bg-card rounded-lg shadow-xl w-full max-w-xl max-h-[92vh] overflow-hidden flex flex-col"
           onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between px-5 py-3 border-b border-black/5 shrink-0">
          <h3 className="font-semibold">{isCreate ? 'Yangi bo‘lim' : 'Bo‘limni tahrirlash'}</h3>
          <button onClick={onClose} disabled={saving} className="p-1 rounded hover:bg-black/5" aria-label="Yopish">
            <X size={18} />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto p-5 space-y-4">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label className="label">Tugma nomi *</label>
              <input className="input" maxLength={64} placeholder="💰 Narxlar" value={title}
                     onChange={(e) => onTitleChange(e.target.value)} />
            </div>
            <div>
              <label className="label">Buyruq *</label>
              <div className="flex items-center">
                <span className="px-2.5 py-2 rounded-l-button border border-r-0 border-black/10 bg-black/[0.03] text-ink-soft">/</span>
                <input className="input rounded-l-none" maxLength={33} placeholder="narxlar" value={command}
                       onChange={(e) => { setCommandTouched(true); setCommand(e.target.value.toLowerCase()); }} />
              </div>
            </div>
          </div>
          <p className="text-xs text-ink-soft -mt-2">
            Mijoz pastdagi tugmani bosadi yoki botning «Menu» ro‘yxatidan <b>/{command || 'buyruq'}</b> ni tanlaydi.
          </p>

          <div>
            <div className="flex items-center justify-between">
              <label className="label">Javob matni</label>
              <span className={cn('text-xs', text.length > MAX_TEXT_LENGTH ? 'text-danger' : 'text-ink-soft')}>
                {text.length} / {MAX_TEXT_LENGTH}
              </span>
            </div>
            <textarea className="input min-h-[140px]" maxLength={MAX_TEXT_LENGTH} value={text}
                      placeholder={'Kotyol 50L — 1 200 000 so‘m\nKotyol 100L — 2 100 000 so‘m\n\nBuyurtma uchun raqamingizni yozing 👇'}
                      onChange={(e) => setText(e.target.value)} />
            {hasImages && trimmedText.length > CAPTION_LIMIT && (
              <p className="text-xs text-amber-700 mt-1">
                Matn {CAPTION_LIMIT} belgidan uzun — rasm ostiga sig‘maydi, rasmlardan keyin alohida xabar bo‘lib boradi.
              </p>
            )}
          </div>

          <div>
            <div className="flex items-center justify-between">
              <label className="label">Rasmlar</label>
              <span className="text-xs text-ink-soft">{imageCount} / {MAX_IMAGES_PER_ITEM}</span>
            </div>
            <div className="flex flex-wrap gap-2">
              {existing.map((img) => (
                <div key={img.id} className="relative">
                  <BotMenuThumb imageId={img.id} size={76} />
                  {canDelete && (
                    <button type="button" aria-label="Rasmni olib tashlash"
                            onClick={() => setRemoved((prev) => new Set(prev).add(img.id))}
                            className="absolute -top-1.5 -right-1.5 w-6 h-6 rounded-full bg-white shadow border border-black/10 flex items-center justify-center text-danger hover:bg-danger/5">
                      <X size={13} />
                    </button>
                  )}
                </div>
              ))}
              {added.map((img) => (
                <div key={img.key} className="relative">
                  <img src={img.url} alt="" className="w-[76px] h-[76px] rounded-button object-cover border-2 border-primary/40" />
                  <button type="button" aria-label="Rasmni olib tashlash" onClick={() => dropAdded(img.key)}
                          className="absolute -top-1.5 -right-1.5 w-6 h-6 rounded-full bg-white shadow border border-black/10 flex items-center justify-center text-danger hover:bg-danger/5">
                    <X size={13} />
                  </button>
                </div>
              ))}
              {imageCount < MAX_IMAGES_PER_ITEM && (
                <button type="button" onClick={() => fileRef.current?.click()}
                        className="w-[76px] h-[76px] rounded-button border-2 border-dashed border-black/15 text-ink-soft hover:border-primary hover:text-primary flex flex-col items-center justify-center gap-1 text-xs">
                  <ImagePlus size={20} /> Qo‘shish
                </button>
              )}
            </div>
            <p className="text-xs text-ink-soft mt-1.5">
              JPEG / PNG / WEBP, har biri 5 MB gacha. 2 va undan ko‘p rasm albom bo‘lib boradi.
            </p>
            <input ref={fileRef} type="file" accept={IMAGE_ACCEPT} multiple className="hidden"
                   onChange={(e) => { pickFiles(e.target.files); e.target.value = ''; }} />
          </div>

          <label className="flex items-center gap-2 text-sm cursor-pointer select-none">
            <input type="checkbox" checked={isActive} onChange={(e) => setIsActive(e.target.checked)} />
            Botda ko‘rinsin
          </label>
        </div>

        <div className="px-5 py-3 border-t border-black/5 flex justify-end gap-2 shrink-0">
          <button onClick={onClose} disabled={saving} className="px-3 py-1.5 text-sm rounded-button hover:bg-black/5">
            Bekor qilish
          </button>
          <button onClick={handleSave} disabled={saving} className="btn-primary">
            {saving ? 'Saqlanmoqda...' : 'Saqlash'}
          </button>
        </div>
      </div>
    </div>
  );
}
