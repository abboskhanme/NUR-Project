import { useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { X, Printer } from 'lucide-react';

import { formatDate, formatPhone } from '@/lib/format';
import type { OrderFull } from './OrdersTable';

// Kompaniya aloqa raqamlari (chek pastida tagma-tag chiqadi)
const COMPANY_PHONES = ['+998 97 058 20 25', '+998 97 318 20 25', '+998 99 675 20 22'];
const SERVICE_PHONES = ['+998 90 151 93 31', '+998 90 556 21 34'];

const num = (s: string | number | null | undefined) => {
  const n = parseFloat(String(s ?? ''));
  return Number.isNaN(n) ? 0 : n;
};

// Termal chek uchun ixcham UZS formati (so'm so'zisiz, 3 xonadan bo'shliq bilan).
function som(value: number): string {
  return Math.round(value).toLocaleString('uz-UZ', { maximumFractionDigits: 0 }).replace(/,/g, ' ');
}

function nowStamp(): string {
  const d = new Date();
  const p = (n: number) => String(n).padStart(2, '0');
  return `${p(d.getDate())}.${p(d.getMonth() + 1)}.${d.getFullYear()} ${p(d.getHours())}:${p(d.getMinutes())}`;
}

/**
 * Buyurtma uchun ingichka termal chek (58mm) — modal sifatida ko'rsatadi va
 * "Chop etish" tugmasi to'g'ridan-to'g'ri brauzer print oynasini ochadi.
 * Chop etishda faqat #thermal-receipt ko'rinadi (global.css'dagi @media print).
 * Bitta chop etishda chek ikki nusxada chiqadi (orasida kesish chizig'i bilan).
 */
export default function ReceiptModal({ order, onClose }: { order: OrderFull; onClose: () => void }) {
  const { t } = useTranslation();

  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [onClose]);

  const rate = num(order.exchange_rate);
  const balance = num(order.balance_uzs);
  const dirLabel = (d?: string | null) =>
    d === 'right' ? t('sales.dirRightFull') : d === 'left' ? t('sales.dirLeftFull') : '';

  // Inline stillar — print paytida tailwind ranglari yo'qoladi, shuning uchun
  // chop etiladigan qism uchun aniq inline qiymatlar ishlatamiz.
  const line: React.CSSProperties = { display: 'flex', justifyContent: 'space-between', gap: 4 };
  const hr: React.CSSProperties = { borderTop: '1px dashed #000', margin: '5px 0' };
  const muted: React.CSSProperties = { textAlign: 'center', fontSize: 11 };
  // Telefon raqamlari — 2.5x kattaroq, qalin qora (muted 11px → ~28px)
  const phone: React.CSSProperties = {
    textAlign: 'center',
    fontSize: 28,
    fontWeight: 700,
    color: '#000',
    lineHeight: 1.2,
  };

  // Bitta chek nusxasi
  const ReceiptCopy = () => (
    <div>
      {/* Logo + sarlavha */}
      <div style={{ textAlign: 'center' }}>
        <img
          src="/nur-logo.jpg"
          alt="NUR TECHNO GROUP"
          // Qora fon → oq, oltin rasm → qora (oq qog'ozli termal printer uchun)
          style={{
            width: '34mm',
            maxWidth: '90%',
            display: 'inline-block',
            filter: 'grayscale(1) invert(1) contrast(4) brightness(1.05)',
          }}
        />
      </div>
      <div style={hr} />

      <div style={line}><span>{t('sales.receiptOrderLabel')}:</span><span style={{ fontWeight: 700 }}>{order.code}</span></div>
      <div style={line}><span>{t('sales.receiptDateLabel')}:</span><span>{formatDate(order.order_date)}</span></div>
      {order.customer?.full_name && (
        <div style={line}><span>{t('sales.receiptCustomerLabel')}:</span><span>{order.customer.full_name}</span></div>
      )}
      {order.customer?.phone && (
        <div style={line}><span>{t('sales.receiptPhoneLabel')}:</span><span>{formatPhone(order.customer.phone)}</span></div>
      )}

      <div style={hr} />

      {/* Mahsulotlar */}
      {order.items.map((it) => {
        const qty = it.quantity || 1;
        const unitUzs = num(it.unit_price_uzs);
        const discUzs = num(it.discount_usd) * rate;
        const dir = it.product?.product_type !== 'additional' ? dirLabel(it.bunker_direction) : '';
        const name = it.product
          ? (it.product.display_name ?? it.product.model ?? it.product.name ?? '—')
          : '—';
        return (
          <div key={it.id} style={{ marginBottom: 4 }}>
            <div>{name}{dir ? ` (${dir})` : ''}</div>
            <div style={line}>
              <span>{qty} × {som(unitUzs)}</span>
              <span>{som(unitUzs * qty)}</span>
            </div>
            {discUzs > 0 && (
              <div style={line}>
                <span>{t('sales.receiptDiscountLabel')}</span>
                <span>−{som(discUzs)}</span>
              </div>
            )}
          </div>
        );
      })}

      <div style={hr} />

      {/* Yakuniy summalar */}
      <div style={{ ...line, fontWeight: 700, fontSize: 14 }}>
        <span>{t('sales.receiptTotalLabel')}</span><span>{som(num(order.items_total_uzs))}</span>
      </div>
      <div style={line}><span>{t('sales.receiptPaidLabel')}</span><span>{som(num(order.paid_uzs))}</span></div>
      <div style={line}>
        <span>{t('sales.receiptBalanceLabel')}</span><span>{som(balance)}</span>
      </div>

      <div style={hr} />

      {/* Sotuvchi */}
      {order.salesperson_name && (
        <div style={{ textAlign: 'center', marginBottom: 4 }}>
          {t('sales.receiptSellerLabel')}: <b>{order.salesperson_name}</b>
        </div>
      )}

      {/* Aloqa raqamlari — raqamlar shrifti 2.5x kattaroq, bold qora */}
      <div style={{ ...muted, fontWeight: 700 }}>{t('sales.receiptContactLabel')}</div>
      {COMPANY_PHONES.map((p) => <div key={p} style={phone}>{p}</div>)}
      <div style={{ ...muted, fontWeight: 700, marginTop: 6 }}>{t('sales.receiptServiceLabel')}</div>
      {SERVICE_PHONES.map((p) => <div key={p} style={phone}>{p}</div>)}

      <div style={hr} />
      <div style={{ textAlign: 'center', fontSize: 11, marginTop: 2 }}>{t('sales.receiptThanks')}</div>
      <div style={{ textAlign: 'center', fontSize: 10, marginTop: 4 }}>{nowStamp()}</div>
    </div>
  );

  // Ikki nusxa orasidagi kesish chizig'i
  const cut: React.CSSProperties = {
    borderTop: '1px dashed #000',
    textAlign: 'center',
    fontSize: 10,
    color: '#000',
    margin: '10mm 0 6mm',
    paddingTop: 2,
  };

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center overflow-auto bg-black/40 p-4" onClick={onClose}>
      <div className="bg-card rounded-lg shadow-xl w-full max-w-md my-6 overflow-hidden flex flex-col"
           onClick={(e) => e.stopPropagation()}>
        {/* Sarlavha — chop etilmaydi */}
        <div className="flex items-center justify-between px-4 py-3 border-b border-black/5">
          <h3 className="font-semibold text-sm">{t('sales.receiptModalTitle')}</h3>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/5"><X size={18} /></button>
        </div>

        {/* Chek ko'rinishi (preview + chop etiladigan qism) */}
        <div className="p-5 bg-black/5 flex justify-center overflow-auto">
          <div
            id="thermal-receipt"
            style={{
              background: '#fff',
              color: '#000',
              fontWeight: 700,
              fontFamily: "'Courier New', ui-monospace, monospace",
              fontSize: 13,
              lineHeight: 1.4,
              padding: '4mm 3mm',
              boxShadow: '0 1px 6px rgba(0,0,0,.18)',
            }}
          >
            <ReceiptCopy />
            <div style={cut}>✂ — — — — — — — — — —</div>
            <ReceiptCopy />
          </div>
        </div>

        {/* Tugmalar — chop etilmaydi */}
        <div className="px-4 py-3 border-t border-black/5 flex justify-end gap-2">
          <button onClick={onClose} className="px-3 py-1.5 text-sm rounded-button hover:bg-black/5">
            {t('sales.cancelBtnShort')}
          </button>
          <button onClick={() => window.print()} className="btn-primary text-sm py-1.5">
            <Printer size={15} /> {t('sales.receiptPrintBtn')}
          </button>
        </div>
      </div>
    </div>
  );
}
