import { Link, useLocation } from 'react-router-dom';
import { ShieldCheck, Trash2, ArrowLeft } from 'lucide-react';

/**
 * Ochiq huquqiy sahifalar — /privacy va /data-deletion.
 *
 * Login TALAB QILINMAYDI: Meta (Instagram) ilovani «Live» rejimiga o'tkazish
 * uchun maxfiylik siyosati va ma'lumotlarni o'chirish sahifalarini tekshiradi
 * va ular hammaga ochiq bo'lishi shart.
 *
 * Matn ataylab aniq va qisqa: ilova FAQAT o'z Instagram akkauntimizga kelgan
 * xabarlarni qayta ishlaydi, uchinchi tomonlarga sotilmaydi.
 */

const COMPANY = 'NUR TECHNO GROUP';
const EMAIL = 'info@nurtechnogroup.uz';
const PHONE = '+998 97 666 26 75';
const SITE = 'www.nurtechnogroup.uz';
// Oxirgi yangilanish sanasi — matn o'zgarsa shuni ham yangilang
const UPDATED = '11.08.2026';

export default function LegalPage() {
  // Ikkala manzil ham shu komponentga keladi — qaysi biri ekanini yo'ldan aniqlaymiz
  const { pathname } = useLocation();
  return pathname.startsWith('/data-deletion') ? <DataDeletion /> : <Privacy />;
}

/* ─────────────────────────── umumiy qobiq ─────────────────────────── */

function Shell({ icon, title, otherTo, otherLabel, children }: {
  icon: React.ReactNode;
  title: string;
  /** Ikkinchi huquqiy sahifaga havola (ular o'zaro bog'langan) */
  otherTo: string;
  otherLabel: string;
  children: React.ReactNode;
}) {
  return (
    <div className="min-h-screen bg-bg">
      <div className="max-w-3xl mx-auto px-5 py-10 sm:py-14">
        <div className="flex items-center gap-3 mb-2">
          <div className="w-11 h-11 rounded-card bg-primary/10 text-primary flex items-center justify-center shrink-0">
            {icon}
          </div>
          <div>
            <h1 className="text-2xl font-bold">{title}</h1>
            <p className="text-sm text-ink-soft">{COMPANY}</p>
          </div>
        </div>
        <p className="text-xs text-ink-soft mb-8">Oxirgi yangilanish: {UPDATED}</p>

        <div className="space-y-6 text-[15px] leading-relaxed">{children}</div>

        <div className="mt-10 pt-6 border-t border-black/10 flex items-center justify-between flex-wrap gap-3 text-sm">
          <Link to="/login" className="text-primary hover:underline inline-flex items-center gap-1.5">
            <ArrowLeft size={15} /> Bosh sahifa
          </Link>
          <Link to={otherTo} className="text-primary hover:underline">{otherLabel}</Link>
        </div>
      </div>
    </div>
  );
}

function H({ children }: { children: React.ReactNode }) {
  return <h2 className="text-lg font-semibold mt-8 mb-2 first:mt-0">{children}</h2>;
}

function Contacts() {
  return (
    <ul className="list-disc pl-5 space-y-1">
      <li>Email: <a className="text-primary hover:underline" href={`mailto:${EMAIL}`}>{EMAIL}</a></li>
      <li>Telefon: {PHONE}</li>
      <li>Sayt: {SITE}</li>
    </ul>
  );
}

/* ─────────────────────────── maxfiylik siyosati ─────────────────────────── */

function Privacy() {
  return (
    <Shell icon={<ShieldCheck size={22} />} title="Maxfiylik siyosati"
           otherTo="/data-deletion" otherLabel="Ma'lumotlarni o'chirish">
      <p>
        {COMPANY} («biz») mijozlar bilan Instagram orqali muloqot qilish uchun
        avtomatlashtirilgan yordamchidan foydalanadi. Ushbu hujjat qanday
        ma'lumot to'planishini, u nima uchun kerakligini va uni qanday
        o'chirishingiz mumkinligini tushuntiradi.
      </p>

      <H>Qanday ma'lumot to'playmiz</H>
      <p>Biz faqat siz o'zingiz yuborgan ma'lumotni qayta ishlaymiz:</p>
      <ul className="list-disc pl-5 space-y-1">
        <li>Instagram foydalanuvchi nomi va ilova bergan ichki identifikator</li>
        <li>Bizga yozgan xabarlaringiz va izohlaringiz matni</li>
        <li>Muloqot vaqti</li>
        <li>Siz o'zingiz ixtiyoriy ravishda yozgan aloqa ma'lumotlari (telefon, manzil)</li>
      </ul>
      <p>
        Biz parolingizni, to'lov ma'lumotlaringizni, kontaktlar ro'yxatingizni yoki
        Instagram'dagi shaxsiy yozishmalaringizni <b>to'plamaymiz</b>.
      </p>

      <H>Nima uchun ishlatamiz</H>
      <ul className="list-disc pl-5 space-y-1">
        <li>Savolingizga javob berish va mahsulot bo'yicha maslahat berish</li>
        <li>Buyurtmani rasmiylashtirish va yetkazib berishni tashkil qilish</li>
        <li>Xizmat sifatini yaxshilash uchun ichki tahlil</li>
      </ul>
      <p>
        Ma'lumotlar reklama maqsadida ishlatilmaydi va uchinchi tomonlarga
        <b> sotilmaydi</b>.
      </p>

      <H>Kim ko'ra oladi</H>
      <p>
        Ma'lumotlarga faqat {COMPANY} ning vakolatli xodimlari kira oladi.
        Texnik jihatdan quyidagi xizmatlardan foydalanamiz:
      </p>
      <ul className="list-disc pl-5 space-y-1">
        <li><b>Meta (Instagram)</b> — xabarlarni yetkazish uchun</li>
        <li>
          <b>Sun'iy intellekt provayderi</b> (Anthropic yoki Google) — javob
          matnini tayyorlash uchun. Xabar matni shu maqsadda yuboriladi va
          model o'qitish uchun ishlatilmaydi.
        </li>
      </ul>

      <H>Qancha vaqt saqlanadi</H>
      <p>
        Muloqot tarixi xizmat ko'rsatish uchun zarur bo'lgan muddat davomida
        saqlanadi. So'rovingiz bo'yicha istalgan vaqtda o'chiriladi.
      </p>

      <H>Sizning huquqlaringiz</H>
      <ul className="list-disc pl-5 space-y-1">
        <li>O'zingiz haqingizdagi ma'lumotni so'rash</li>
        <li>Uni to'g'rilash yoki o'chirishni talab qilish</li>
        <li>Muloqotni istalgan vaqtda to'xtatish</li>
      </ul>
      <p>
        O'chirish tartibi:{' '}
        <Link to="/data-deletion" className="text-primary hover:underline">
          Ma'lumotlarni o'chirish
        </Link>.
      </p>

      <H>Xavfsizlik</H>
      <p>
        Ma'lumotlar himoyalangan serverda saqlanadi, uzatish HTTPS orqali
        shifrlanadi, kirish esa parol va rollar bilan cheklanadi.
      </p>

      <H>O'zgarishlar</H>
      <p>
        Siyosat yangilanishi mumkin. Yangilangan matn shu sahifada e'lon
        qilinadi va yuqoridagi sana o'zgaradi.
      </p>

      <H>Bog'lanish</H>
      <Contacts />
    </Shell>
  );
}

/* ─────────────────────── ma'lumotlarni o'chirish ─────────────────────── */

function DataDeletion() {
  return (
    <Shell icon={<Trash2 size={22} />} title="Ma'lumotlarni o'chirish"
           otherTo="/privacy" otherLabel="Maxfiylik siyosati">
      <p>
        {COMPANY} bilan Instagram orqali qilgan muloqotingiz ma'lumotlarini
        istalgan vaqtda o'chirishni so'rashingiz mumkin. Bu bepul.
      </p>

      <H>Qanday so'rash mumkin</H>
      <ol className="list-decimal pl-5 space-y-2">
        <li>
          Bizga <b>«Ma'lumotlarimni o'chiring»</b> deb yozing — Instagram DM
          orqali yoki quyidagi aloqa vositalaridan biri bilan.
        </li>
        <li>
          Instagram foydalanuvchi nomingizni ko'rsating, shunda qaysi
          yozishmani o'chirish kerakligini aniqlaymiz.
        </li>
        <li>
          So'rovni <b>7 ish kuni</b> ichida bajaramiz va tasdiqlab xabar beramiz.
        </li>
      </ol>

      <H>Nima o'chiriladi</H>
      <ul className="list-disc pl-5 space-y-1">
        <li>Muloqot tarixi va xabarlar matni</li>
        <li>Instagram foydalanuvchi nomi va identifikatori</li>
        <li>Siz yozgan aloqa ma'lumotlari</li>
      </ul>
      <p className="text-ink-soft text-sm">
        Eslatma: agar siz haqiqiy buyurtma bergan bo'lsangiz, buxgalteriya
        hujjatlari qonun talabiga ko'ra saqlanib qolishi mumkin. Ular alohida
        saqlanadi va Instagram muloqotiga bog'liq emas.
      </p>

      <H>Instagram tomonidan ruxsatni bekor qilish</H>
      <p>
        Ilovaning ma'lumotlaringizga kirishini o'zingiz ham to'xtatishingiz
        mumkin: Instagram → Sozlamalar → Saytlar va ilovalar ruxsatlari →
        ilovani o'chirish.
      </p>

      <H>Bog'lanish</H>
      <Contacts />
    </Shell>
  );
}
