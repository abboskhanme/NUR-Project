import { MapPin } from 'lucide-react';

/**
 * Ariza ochilayotganda lokatsiya kiritish (ixtiyoriy).
 *
 * Bu yerga mijoz yuborgan xarita havolasi yoki koordinata qo'yiladi. Telegram
 * pinini forward qilish yo'li ariza yaratilgandan keyin kartochkada mavjud —
 * shuning uchun bu maydon majburiy emas.
 */
export default function LocationInput({
  raw, note, onRaw, onNote,
}: {
  raw: string; note: string;
  onRaw: (v: string) => void; onNote: (v: string) => void;
}) {
  return (
    <div>
      <label className="label inline-flex items-center gap-1.5">
        <MapPin size={14} /> Lokatsiya{' '}
        <span className="text-ink-soft font-normal">(ixtiyoriy)</span>
      </label>
      <input className="input" placeholder="Xarita havolasi yoki 41.311, 69.240"
             value={raw} onChange={(e) => onRaw(e.target.value)} />
      <input className="input mt-2" placeholder="Mo'ljal (masalan: ko'k darvoza)"
             value={note} onChange={(e) => onNote(e.target.value)} />
      <div className="text-xs text-ink-soft mt-1">
        Telegram pinini keyin ariza kartochkasidan botga forward qilib biriktirasiz.
      </div>
    </div>
  );
}
