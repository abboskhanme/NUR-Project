"""PDF hujjatlar generatori — faktura, to'lov kvitansiyasi, kafolat sertifikati.

reportlab (platypus) yordamida sotuv buyurtmasi uchun chop etiladigan hujjatlar
yaratadi. Matn o'zbek tilida (lotin). Yunikod shrift topilsa (Vera/DejaVu) — kirill
ham qo'llab-quvvatlanadi, aks holda Helvetica'ga qaytadi.
"""
from __future__ import annotations

import io
import logging
import os
from datetime import date, timedelta
from decimal import Decimal
from typing import Optional

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_RIGHT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.lib.utils import ImageReader
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    Flowable,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

from app.core.config import settings

log = logging.getLogger(__name__)

# Brend ranglari (frontend bilan mos: #1E3A5F asosiy, #2980B9 akssent)
BRAND_PRIMARY = colors.HexColor("#1E3A5F")
BRAND_ACCENT = colors.HexColor("#2980B9")
SOFT_LINE = colors.HexColor("#E2E8F0")
INK_SOFT = colors.HexColor("#64748B")

# ---- Shrift ro'yxati (birinchi topilgani ishlatiladi) ----
_FONT = "Helvetica"
_FONT_BOLD = "Helvetica-Bold"
_FONT_REGISTERED = False


def _has_cyrillic(ttf_path: str) -> bool:
    """TTF ichida kirill glifi bormi (kafolat hujjati kirill/ruschada chiqadi)."""
    try:
        return ord("А") in TTFont("nur_probe", ttf_path).face.charToGlyph
    except Exception:  # pragma: no cover — buzuq shriftni mos emas deb hisoblaymiz
        return False


def _register_fonts() -> None:
    """Yunikod TTF shriftni topib ro'yxatdan o'tkazadi (bir marta).

    Kafolat sertifikati KIRILL va RUS tilida chiqadi, shuning uchun kirill
    glifi bor shrift (DejaVu) birinchi o'ringa qo'yiladi. reportlab bilan
    keladigan Vera'da kirill YO'Q — u faqat oxirgi chora sifatida ishlatiladi
    (u holda kirill matn bo'sh chiqadi, shu sababli ogohlantirish yoziladi).
    """
    global _FONT, _FONT_BOLD, _FONT_REGISTERED
    if _FONT_REGISTERED:
        return
    _FONT_REGISTERED = True

    try:
        import reportlab

        rl_fonts = os.path.join(os.path.dirname(reportlab.__file__), "fonts")
    except Exception:  # pragma: no cover
        rl_fonts = ""

    # (oddiy, qalin) shrift juftliklari — kirillni qo'llaydigani ustun
    candidates = [
        (
            os.path.join(rl_fonts, "DejaVuSans.ttf"),
            os.path.join(rl_fonts, "DejaVuSans-Bold.ttf"),
        ),
        (
            "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
            "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        ),
        (
            os.path.join(rl_fonts, "Vera.ttf"),
            os.path.join(rl_fonts, "VeraBd.ttf"),
        ),
    ]
    available = [(r, b) for r, b in candidates
                 if os.path.exists(r) and os.path.exists(b)]
    if not available:  # pragma: no cover — Helvetica (lotin) qoladi
        log.warning("PDF: yunikod shrift topilmadi — kirill matn chiqmaydi")
        return

    chosen = next((pair for pair in available if _has_cyrillic(pair[0])), None)
    if chosen is None:
        chosen = available[0]
        log.warning(
            "PDF: kirill glifi bor shrift topilmadi (%s ishlatilmoqda) — kafolat "
            "sertifikatidagi kirill/rus matni BO'SH chiqadi. Yechim: image'ni "
            "fonts-dejavu-core bilan qayta build qiling.", os.path.basename(chosen[0]),
        )

    try:
        pdfmetrics.registerFont(TTFont("NurSans", chosen[0]))
        pdfmetrics.registerFont(TTFont("NurSans-Bold", chosen[1]))
        # <b>…</b> paragraf ichida ishlashi uchun oila sifatida bog'laymiz
        pdfmetrics.registerFontFamily(
            "NurSans", normal="NurSans", bold="NurSans-Bold",
            italic="NurSans", boldItalic="NurSans-Bold",
        )
        _FONT, _FONT_BOLD = "NurSans", "NurSans-Bold"
    except Exception:  # pragma: no cover — shrift buzuq bo'lsa Helvetica qoladi
        log.exception("PDF: shriftni ro'yxatdan o'tkazib bo'lmadi")


def _fmt_uzs(value) -> str:
    """1234567.89 -> "1 234 568 so'm" (butun, bo'shliq ajratuvchi)."""
    try:
        n = Decimal(str(value or 0))
    except Exception:
        n = Decimal(0)
    return f"{int(n.quantize(Decimal('1'))):,}".replace(",", " ") + " so'm"


def _fmt_usd(value) -> str:
    try:
        n = Decimal(str(value or 0))
    except Exception:
        n = Decimal(0)
    return "$" + f"{n:,.2f}".replace(",", " ")


def _fmt_date(d: Optional[date]) -> str:
    return d.strftime("%d.%m.%Y") if d else "—"


def _styles() -> dict:
    _register_fonts()
    ss = getSampleStyleSheet()
    base = ss["Normal"]
    return {
        "normal": ParagraphStyle(
            "nur_normal", parent=base, fontName=_FONT, fontSize=9.5, leading=13
        ),
        "small": ParagraphStyle(
            "nur_small", parent=base, fontName=_FONT, fontSize=8, leading=11,
            textColor=INK_SOFT,
        ),
        "right": ParagraphStyle(
            "nur_right", parent=base, fontName=_FONT, fontSize=9.5, leading=13,
            alignment=TA_RIGHT,
        ),
        "h1": ParagraphStyle(
            "nur_h1", parent=base, fontName=_FONT_BOLD, fontSize=18, leading=22,
            textColor=BRAND_PRIMARY,
        ),
        "h2": ParagraphStyle(
            "nur_h2", parent=base, fontName=_FONT_BOLD, fontSize=12, leading=16,
            textColor=BRAND_PRIMARY,
        ),
        "doc_title": ParagraphStyle(
            "nur_doc_title", parent=base, fontName=_FONT_BOLD, fontSize=13,
            leading=16, alignment=TA_RIGHT, textColor=BRAND_ACCENT,
        ),
        "label": ParagraphStyle(
            "nur_label", parent=base, fontName=_FONT, fontSize=8, leading=11,
            textColor=INK_SOFT,
        ),
        "value": ParagraphStyle(
            "nur_value", parent=base, fontName=_FONT_BOLD, fontSize=10, leading=13,
        ),
        "center": ParagraphStyle(
            "nur_center", parent=base, fontName=_FONT, fontSize=9.5, leading=14,
            alignment=TA_CENTER,
        ),
    }


def _company_header(st: dict, doc_title: str, doc_meta: list[tuple[str, str]]) -> Table:
    """Yuqori sarlavha: chapda kompaniya, o'ngda hujjat nomi + meta."""
    left = [
        Paragraph(settings.COMPANY_NAME, st["h1"]),
        Paragraph(settings.COMPANY_ADDRESS or "", st["small"]),
        Paragraph(
            " · ".join(x for x in [settings.COMPANY_PHONE, settings.COMPANY_INN_LABEL] if x),
            st["small"],
        ),
    ]
    meta_rows = [Paragraph(doc_title, st["doc_title"])]
    for label, value in doc_meta:
        meta_rows.append(
            Paragraph(f'<font color="#64748B">{label}:</font> <b>{value}</b>', st["right"])
        )
    t = Table([[left, meta_rows]], colWidths=[100 * mm, 70 * mm])
    t.setStyle(TableStyle([
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 0),
        ("RIGHTPADDING", (0, 0), (-1, -1), 0),
    ]))
    return t


def _rule() -> Table:
    t = Table([[""]], colWidths=[170 * mm], rowHeights=[1])
    t.setStyle(TableStyle([("LINEBELOW", (0, 0), (-1, -1), 1, BRAND_ACCENT)]))
    return t


def _party_block(st: dict, title: str, lines: list[str]) -> list:
    out = [Paragraph(title, st["label"]), Spacer(1, 1 * mm)]
    for i, ln in enumerate(lines):
        out.append(Paragraph(ln, st["value"] if i == 0 else st["normal"]))
    return out


def _signature_block(st: dict, labels: tuple[str, str] = ("Sotuvchi", "Mijoz")) -> Table:
    cell = lambda lab: [  # noqa: E731
        Spacer(1, 10 * mm),
        Table([[""]], colWidths=[60 * mm], rowHeights=[1],
              style=TableStyle([("LINEBELOW", (0, 0), (-1, -1), 0.7, INK_SOFT)])),
        Paragraph(f"{lab} (imzo / F.I.Sh.)", st["small"]),
    ]
    t = Table([[cell(labels[0]), "", cell(labels[1])]],
              colWidths=[60 * mm, 10 * mm, 60 * mm])
    t.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "TOP")]))
    return t


# ---- Imzo rasmlari ----------------------------------------------------------
#  Rasmlar `app/assets/docs` (yoki DOC_ASSETS_DIR) papkasidan olinadi. Fayl
#  qo'yilmagan bo'lsa hujjat baribir chiqadi — faqat imzo chizig'i bo'sh qoladi.
_ASSET_EXTS = (".png", ".jpg", ".jpeg", ".webp")


def _assets_dir() -> str:
    if settings.DOC_ASSETS_DIR:
        return settings.DOC_ASSETS_DIR
    return os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "docs"
    )


def _asset(base_name: str) -> Optional[str]:
    """`imzo-savdo` -> mavjud bo'lsa to'liq yo'l (png/jpg/webp), aks holda None."""
    d = _assets_dir()
    for ext in _ASSET_EXTS:
        p = os.path.join(d, base_name + ext)
        if os.path.exists(p):
            return p
    return None


class _SignatureRow(Flowable):
    """Ikkita imzo maydoni (chap/o'ng).

    Imzo rasmlari mavjud bo'lsa avtomatik chiziladi — hujjatni qo'lda imzolash
    shart bo'lmaydi. Rasm topilmasa imzo chizig'i bo'sh qoladi.
    """

    def __init__(self, entries: list[dict], height: float = 40 * mm,
                 hint: str = "(imzo / F.I.Sh.)"):
        super().__init__()
        self.entries = entries
        self.hint = hint
        self.width = 170 * mm
        self.height = height

    def wrap(self, availWidth, availHeight):  # noqa: N803 — reportlab API
        self.width = availWidth
        return self.width, self.height

    def _image(self, path: str, cx: float, cy: float, max_w: float, max_h: float) -> None:
        """Rasmni (cx, cy) markazi bo'yicha, nisbatini saqlagan holda chizadi."""
        try:
            img = ImageReader(path)
            iw, ih = img.getSize()
        except Exception:  # pragma: no cover — buzuq rasm hujjatni buzmasin
            return
        if not iw or not ih:
            return
        scale = min(max_w / iw, max_h / ih)
        w, h = iw * scale, ih * scale
        try:
            self.canv.drawImage(img, cx - w / 2, cy - h / 2, width=w, height=h,
                                mask="auto", preserveAspectRatio=True)
        except Exception:  # pragma: no cover
            return

    def draw(self) -> None:
        c = self.canv
        col_w = 62 * mm
        line_y = 11 * mm
        positions = [0.0, self.width - col_w]

        for x, e in zip(positions, self.entries):
            c.setFont(_FONT_BOLD, 9)
            c.setFillColor(BRAND_PRIMARY)
            c.drawString(x, self.height - 4 * mm, e.get("title", ""))

            if e.get("image"):
                # Imzo chiziq ustiga tabiiy tushishi uchun: markazi chiziqdan
                # 9 mm yuqorida, balandligi ham 18 mm — pastki cheti chiziqda.
                self._image(e["image"], x + col_w / 2, line_y + 9 * mm,
                            col_w - 12 * mm, 18 * mm)

            c.setStrokeColor(INK_SOFT)
            c.setLineWidth(0.7)
            c.line(x, line_y, x + col_w, line_y)

            name = (e.get("name") or "").strip()
            if name:
                c.setFont(_FONT_BOLD, 9)
                c.setFillColor(colors.black)
                c.drawString(x, line_y - 5 * mm, name)
            elif not e.get("image"):
                # Na imzo rasmi, na F.I.Sh. bor — qo'lda to'ldirish uchun eslatma
                c.setFont(_FONT, 7.5)
                c.setFillColor(INK_SOFT)
                c.drawString(x, line_y - 4.5 * mm, self.hint)


def _department_signatures(L: dict) -> _SignatureRow:
    """Savdo va Servis bo'limi imzolari."""
    return _SignatureRow(
        [
            {"title": L["sign_sales"], "name": settings.DOC_SALES_SIGNER,
             "image": _asset("imzo-savdo")},
            {"title": L["sign_service"], "name": settings.DOC_SERVICE_SIGNER,
             "image": _asset("imzo-servis")},
        ],
        hint=L["sign_hint"],
    )


def _fmt_phone(raw: str) -> str:
    """+998970582025 -> "+998 97 058 20 25" (boshqa formatlar o'zgarishsiz)."""
    d = "".join(ch for ch in raw if ch.isdigit())
    if len(d) == 12 and d.startswith("998"):
        return f"+{d[:3]} {d[3:5]} {d[5:8]} {d[8:10]} {d[10:]}"
    return raw.strip()


def _phones(raw: str) -> list[str]:
    return [_fmt_phone(p) for p in raw.split(",") if p.strip()]


def _contacts_box(st: dict, L: dict) -> Optional[Table]:
    """Savdo va servis bo'limi aloqa raqamlari — kafolat hujjati ostidagi quti."""
    cols = [
        (L["sales"], _phones(settings.DOC_SALES_PHONES)),
        (L["service"], _phones(settings.DOC_SERVICE_PHONES)),
    ]
    if not any(phones for _, phones in cols):
        return None

    cells = []
    for title, phones in cols:
        block = [Paragraph(title, st["label"]), Spacer(1, 1.5 * mm)]
        block += [Paragraph(p, st["value"]) for p in phones] or [Paragraph("—", st["normal"])]
        cells.append(block)

    t = Table([cells], colWidths=[85 * mm, 85 * mm])
    t.setStyle(TableStyle([
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#F8FAFC")),
        ("BOX", (0, 0), (-1, -1), 0.5, SOFT_LINE),
        ("LINEAFTER", (0, 0), (0, -1), 0.5, SOFT_LINE),
        ("LEFTPADDING", (0, 0), (-1, -1), 6 * mm),
        ("RIGHTPADDING", (0, 0), (-1, -1), 4 * mm),
        ("TOPPADDING", (0, 0), (-1, -1), 4 * mm),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4 * mm),
    ]))
    return t


def _build(elements: list) -> bytes:
    buf = io.BytesIO()
    doc = SimpleDocTemplate(
        buf, pagesize=A4,
        leftMargin=20 * mm, rightMargin=20 * mm,
        topMargin=16 * mm, bottomMargin=16 * mm,
        title="NUR", author=settings.COMPANY_NAME,
    )
    doc.build(elements)
    return buf.getvalue()


def _customer_lines(order, L: Optional[dict] = None) -> list[str]:
    c = order.customer
    if not c:
        return ["—"]
    loc = ", ".join(x for x in [getattr(c, "region", None), getattr(c, "city", None),
                                getattr(c, "address", None)] if x)
    lines = [c.full_name]
    if c.phone:
        lines.append(f"{(L or {}).get('phone', 'Tel')}: {c.phone}")
    if loc:
        lines.append(loc)
    return lines


def _item_label(it, L: Optional[dict] = None) -> str:
    p = getattr(it, "product", None)
    if p is not None:
        name = getattr(p, "display_name", None) or getattr(p, "model", None) \
            or getattr(p, "name", None)
        if name:
            base = str(name)
            d = getattr(it, "bunker_direction", None)
            if d and getattr(p, "product_type", None) != "additional":
                right = (L or {}).get("right", "o'ng")
                left = (L or {}).get("left", "chap")
                base += f" ({right})" if d == "right" else f" ({left})" if d == "left" else ""
            return base
    return str(it.product_id)[:8]


# ============================================================================
#  Faktura (invoice)
# ============================================================================
def order_invoice_pdf(order) -> bytes:
    st = _styles()
    el: list = []

    el.append(_company_header(
        st, "FAKTURA",
        [("Buyurtma", order.code),
         ("Sana", _fmt_date(order.order_date))],
    ))
    el.append(Spacer(1, 3 * mm))
    el.append(_rule())
    el.append(Spacer(1, 5 * mm))

    # Mijoz bloki
    party = Table(
        [[_party_block(st, "MIJOZ", _customer_lines(order)),
          _party_block(st, "HOLAT", [_status_label(order.status)])]],
        colWidths=[110 * mm, 60 * mm],
    )
    party.setStyle(TableStyle([
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 0),
    ]))
    el.append(party)
    el.append(Spacer(1, 6 * mm))

    # Mahsulotlar jadvali
    head = ["#", "Mahsulot", "Soni", "Narx (1 dona)", "Summa"]
    rows = [head]
    for i, it in enumerate(order.items, start=1):
        rows.append([
            str(i),
            Paragraph(_item_label(it), st["normal"]),
            str(it.quantity),
            _fmt_usd(it.unit_price_usd),
            _fmt_uzs(it.total_uzs),
        ])
    tbl = Table(rows, colWidths=[10 * mm, 78 * mm, 16 * mm, 30 * mm, 36 * mm])
    tbl.setStyle(TableStyle([
        ("FONTNAME", (0, 0), (-1, 0), _FONT_BOLD),
        ("FONTNAME", (0, 1), (-1, -1), _FONT),
        ("FONTSIZE", (0, 0), (-1, -1), 9),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("BACKGROUND", (0, 0), (-1, 0), BRAND_PRIMARY),
        ("ALIGN", (2, 0), (-1, -1), "RIGHT"),
        ("ALIGN", (0, 0), (0, -1), "CENTER"),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F8FAFC")]),
        ("LINEBELOW", (0, 0), (-1, -1), 0.5, SOFT_LINE),
        ("TOPPADDING", (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
    ]))
    el.append(tbl)
    el.append(Spacer(1, 5 * mm))

    # Yakuniy summalar (o'ng tomonda)
    totals = [
        ["Jami summa:", _fmt_uzs(order.items_total_uzs)],
        ["To'langan:", _fmt_uzs(order.paid_uzs)],
        ["Qoldiq:", _fmt_uzs(order.balance_uzs)],
    ]
    tt = Table(totals, colWidths=[40 * mm, 50 * mm], hAlign="RIGHT")
    tt.setStyle(TableStyle([
        ("FONTNAME", (0, 0), (-1, -1), _FONT),
        ("FONTNAME", (0, -1), (-1, -1), _FONT_BOLD),
        ("FONTSIZE", (0, 0), (-1, -1), 10),
        ("ALIGN", (1, 0), (1, -1), "RIGHT"),
        ("TEXTCOLOR", (0, -1), (-1, -1), BRAND_PRIMARY),
        ("LINEABOVE", (0, -1), (-1, -1), 0.7, SOFT_LINE),
        ("TOPPADDING", (0, 0), (-1, -1), 3),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
    ]))
    el.append(tt)

    if order.exchange_rate and Decimal(str(order.exchange_rate)) > 0:
        el.append(Spacer(1, 2 * mm))
        el.append(Paragraph(
            f"Valyuta kursi: 1$ = {_fmt_uzs(order.exchange_rate)}", st["small"]))

    el.append(Spacer(1, 14 * mm))
    el.append(_signature_block(st))
    el.append(Spacer(1, 6 * mm))
    el.append(Paragraph(_footer_note(), st["small"]))
    return _build(el)


# ============================================================================
#  To'lov kvitansiyasi (payment receipt)
# ============================================================================
def payment_receipt_pdf(order, payment) -> bytes:
    st = _styles()
    el: list = []

    el.append(_company_header(
        st, "TO'LOV KVITANSIYASI",
        [("Buyurtma", order.code),
         ("Sana", _fmt_date(payment.date))],
    ))
    el.append(Spacer(1, 3 * mm))
    el.append(_rule())
    el.append(Spacer(1, 5 * mm))

    el.extend(_party_block(st, "MIJOZ", _customer_lines(order)))
    el.append(Spacer(1, 6 * mm))

    method_labels = {"cash": "Naqd", "card": "Karta", "transfer": "O'tkazma"}
    amount_str = (_fmt_usd(payment.amount) if (payment.currency or "UZS") == "USD"
                  else _fmt_uzs(payment.amount))
    rows = [
        ["To'lov sanasi", _fmt_date(payment.date)],
        ["To'lov summasi", amount_str],
        ["To'lov usuli", method_labels.get(payment.method or "", payment.method or "—")],
    ]
    if (payment.currency or "UZS") == "USD" and payment.amount_uzs_equiv:
        rows.append(["UZS ekvivalent", _fmt_uzs(payment.amount_uzs_equiv)])
    rows.append(["Buyurtma bo'yicha qoldiq", _fmt_uzs(order.balance_uzs)])

    tbl = Table(rows, colWidths=[60 * mm, 90 * mm])
    tbl.setStyle(TableStyle([
        ("FONTNAME", (0, 0), (0, -1), _FONT),
        ("FONTNAME", (1, 0), (1, -1), _FONT_BOLD),
        ("FONTSIZE", (0, 0), (-1, -1), 10),
        ("TEXTCOLOR", (0, 0), (0, -1), INK_SOFT),
        ("LINEBELOW", (0, 0), (-1, -1), 0.5, SOFT_LINE),
        ("TOPPADDING", (0, 0), (-1, -1), 6),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
    ]))
    # To'lov summasini ajratib ko'rsatamiz
    tbl.setStyle(TableStyle([
        ("FONTSIZE", (1, 1), (1, 1), 13),
        ("TEXTCOLOR", (1, 1), (1, 1), BRAND_ACCENT),
    ]))
    el.append(tbl)

    if payment.note:
        el.append(Spacer(1, 4 * mm))
        el.append(Paragraph(f"Izoh: {payment.note}", st["small"]))

    el.append(Spacer(1, 16 * mm))
    el.append(_signature_block(st, ("Qabul qildi", "To'lovchi")))
    el.append(Spacer(1, 6 * mm))
    el.append(Paragraph(_footer_note(), st["small"]))
    return _build(el)


# ============================================================================
#  Kafolat sertifikati (warranty certificate) — o'zbekcha, KIRILL yozuvda
# ============================================================================
#  Hujjatdagi barcha matn shu lug'atda — tuzilma `_warranty_page`da.
#  DIQQAT: kirill glifi uchun DejaVu shrifti kerak (Dockerfile: fonts-dejavu-core).
WARRANTY_TEXT = {
    "doc_title": "КАФОЛАТ СЕРТИФИКАТИ",
    "doc_id": "Буюртма ID",
    "customer": "МИЖОЗ",
    "phone": "Тел",
    "product": "МАҲСУЛОТ",
    "delivered_at": "Етказилган (қабул қилинган) сана",
    "year1": "1-йил — эҳтиёт қисм + сервис бепул",
    "year23": "2–3-йил — фақат сервис бепул",
    "status": "Ҳолат",
    "not_delivered": "Ҳали етказилмаган — кафолат бошланмаган",
    "terms_title": "КАФОЛАТ ШАРТЛАРИ",
    "terms": [
        "Маҳсулот жами <b>3 (уч) йил</b> кафолат муддатига эга.",
        "<b>1-йил</b> давомида барча эҳтиёт қисмлар ва сервис хизмати "
        "мутлақо бепул.",
        "Кейинги 2 йил давомида, яъни <b>2- ва 3-йиллар</b> давомида фақат "
        "сервис хизмати бепул, эҳтиёт қисмлар эса мижоз ҳисобидан бўлади. "
        "Бузилган эҳтиёт қисмни мижоз бизга жўнатиб бериши керак — биз уни "
        "янгисига алмаштириб берамиз. Йўл (жўнатиш) харажатлари қопланмайди.",
        "Кафолат нотўғри фойдаланиш, механик шикастланиш ёки рухсатсиз "
        "таъмирлаш ҳолатларида бекор қилиниши мумкин.",
        "Кафолат муддати юк етказилган ва қабул қилинган вақтдан бошлаб "
        "ҳисобланади.",
    ],
    "contacts_title": "АЛОҚА УЧУН",
    "sales": "САВДО БЎЛИМИ",
    "service": "СЕРВИС ХИЗМАТИ",
    "sign_sales": "САВДО БЎЛИМИ",
    "sign_service": "СЕРВИС БЎЛИМИ",
    "sign_hint": "(имзо / Ф.И.Ш.)",
    "right": "ўнг",
    "left": "чап",
}


def order_doc_id(order) -> str:
    """Hujjatlarda ko'rsatiladigan buyurtma ID'si.

    Bu — qo'lda kiritiladigan ID raqami (`unit_uid`, ombordagi kotyol raqami),
    tizim generatsiya qiladigan `code` emas. ID kiritilmagan buyurtmada hujjat
    umuman raqamsiz qolmasligi uchun `code`ga qaytamiz.
    """
    return (getattr(order, "unit_uid", None) or "").strip() or order.code


def _warranty_page(st: dict, order, L: dict) -> list:
    """Kafolat sertifikatining bitta varag'i — `L` lug'atidagi tilda."""
    el: list = []

    el.append(_company_header(
        st, L["doc_title"],
        [(L["doc_id"], order_doc_id(order))],
    ))
    el.append(Spacer(1, 3 * mm))
    el.append(_rule())
    el.append(Spacer(1, 6 * mm))

    el.extend(_party_block(st, L["customer"], _customer_lines(order, L)))
    el.append(Spacer(1, 5 * mm))

    # Mahsulot(lar)
    prod_lines = []
    for it in order.items:
        sn = f" · S/N: {it.serial_id}" if getattr(it, "serial_id", None) else ""
        prod_lines.append(f"{_item_label(it, L)} × {it.quantity}{sn}")
    el.extend(_party_block(st, L["product"], prod_lines or ["—"]))
    el.append(Spacer(1, 6 * mm))

    # Kafolat muddati
    delivered = order.delivered_at
    if delivered:
        y1 = delivered + timedelta(days=365)
        y3 = delivered + timedelta(days=365 * 3)
        terms = [
            [L["delivered_at"], _fmt_date(delivered)],
            [L["year1"], f"{_fmt_date(delivered)} — {_fmt_date(y1)}"],
            [L["year23"], f"{_fmt_date(y1)} — {_fmt_date(y3)}"],
        ]
    else:
        terms = [[L["status"], L["not_delivered"]]]
    # Yorliqlar Paragraph'da — uzun ruscha matn ustunga sig'may qolsa o'raladi
    rows = [[Paragraph(f'<font color="#64748B">{lab}</font>', st["normal"]),
             Paragraph(f"<b>{val}</b>", st["normal"])] for lab, val in terms]
    tbl = Table(rows, colWidths=[78 * mm, 72 * mm])
    tbl.setStyle(TableStyle([
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("LINEBELOW", (0, 0), (-1, -1), 0.5, SOFT_LINE),
        ("LEFTPADDING", (0, 0), (0, -1), 0),
        ("TOPPADDING", (0, 0), (-1, -1), 6),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
    ]))
    el.append(tbl)

    el.append(Spacer(1, 7 * mm))
    el.append(Paragraph(L["terms_title"], st["h2"]))
    el.append(Spacer(1, 2 * mm))
    for i, line in enumerate(L["terms"], start=1):
        el.append(Paragraph(line, st["normal"], bulletText=f"{i}."))
        el.append(Spacer(1, 1.5 * mm))

    contacts = _contacts_box(st, L)
    if contacts is not None:
        el.append(Spacer(1, 7 * mm))
        el.append(Paragraph(L["contacts_title"], st["h2"]))
        el.append(Spacer(1, 2 * mm))
        el.append(contacts)

    el.append(Spacer(1, 10 * mm))
    el.append(_department_signatures(L))
    # Mijozga beriladigan hujjat — pastda "tizimda shakllantirildi" izohi yo'q.
    return el


def warranty_certificate_pdf(order) -> bytes:
    """Kafolat sertifikati — bitta varaq, o'zbekcha (kirill yozuvda)."""
    st = _styles()
    return _build(_warranty_page(st, order, WARRANTY_TEXT))


def _status_label(status: str) -> str:
    return {
        "new": "Navbatda",
        "ready": "Tayyor bo'ldi",
        "delivered": "Yetkazildi",
        "rejected": "Rad etildi",
    }.get(status, status)


def _footer_note() -> str:
    parts = [settings.COMPANY_NAME]
    if settings.COMPANY_PHONE:
        parts.append(settings.COMPANY_PHONE)
    if settings.COMPANY_WEBSITE:
        parts.append(settings.COMPANY_WEBSITE)
    return " · ".join(parts) + "  —  ushbu hujjat NUR ERP tizimida shakllantirildi."
