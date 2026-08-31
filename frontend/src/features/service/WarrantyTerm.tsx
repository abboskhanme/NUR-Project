// Kafolat muddati — FAQAT KO'RSATISH uchun (read-only, hech qayerda tahrirlanmaydi).
//
// Qoida tizimda bitta va u yerdan o'zgarmaydi (backend: warranty_service.py,
// kafolat sertifikati: pdf_service.py):
//   • kafolat YETKAZILGAN (qabul qilingan) sanadan boshlanadi;
//   • 1-yil       — ish + ehtiyot qism bepul;
//   • keyingi 2 yil (2–3-yil) — faqat ish bepul, ehtiyot qism mijoz hisobidan;
//   • jami 3 yil.
// "0 dan" arizada (dillerdan olgan mijoz) boshlanish sanasi — sotib olingan sana.
import { formatDate } from '@/lib/format';
import { computeWarranty } from './warranty';

/** Kafolat qaysi sanadan boshlanadi: yetkazilgan sana, "0 dan"da — xarid sanasi. */
export function warrantyStart(t: {
  order?: { delivered_at?: string | null } | null;
  purchase_date?: string | null;
}): string | null {
  return t.order?.delivered_at ?? t.purchase_date ?? null;
}

export default function WarrantyTerm({ start }: { start?: string | null }) {
  const w = computeWarranty(start ?? null);

  if (w.status === 'not_delivered' || !w.year1End || !w.year3End) {
    return (
      <span className="text-ink-soft" title="Kafolat boshlanmagan — yetkazilgan (yoki sotib olingan) sana ko'rsatilmagan">
        —
      </span>
    );
  }

  const y1 = formatDate(w.year1End);
  const y3 = formatDate(w.year3End);
  const full = w.status === 'active_full';
  const partial = w.status === 'active_service_only';

  const title =
    `Kafolat boshlangan: ${formatDate(start!)}\n` +
    `1-yil (ish + ehtiyot qism bepul): ${y1} gacha` +
    (full ? ` — ${w.daysYear1} kun qoldi\n` : ' — tugagan\n') +
    `2–3-yil (faqat ish bepul): ${y3} gacha` +
    (partial ? ` — ${w.daysYear3} kun qoldi` : full ? '' : ' — tugagan');

  return (
    <div className="whitespace-nowrap leading-tight" title={title}>
      <div className={full ? 'text-success font-medium' : 'text-ink-soft'}>
        1-yil: {y1}
      </div>
      <div className={'text-xs ' + (partial ? 'text-warning font-medium' : 'text-ink-soft')}>
        3-yil: {y3}
      </div>
    </div>
  );
}
