"""PDF hujjatlar generatori — faktura, to'lov kvitansiyasi, kafolat sertifikati.

reportlab (platypus) yordamida sotuv buyurtmasi uchun chop etiladigan hujjatlar
yaratadi. Matn o'zbek tilida (lotin). Yunikod shrift topilsa (Vera/DejaVu) — kirill
ham qo'llab-quvvatlanadi, aks holda Helvetica'ga qaytadi.
"""
from __future__ import annotations

import io
import os
from datetime import date, timedelta
from decimal import Decimal
from typing import Optional

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_RIGHT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

from app.core.config import settings

# Brend ranglari (frontend bilan mos: #1E3A5F asosiy, #2980B9 akssent)
BRAND_PRIMARY = colors.HexColor("#1E3A5F")
BRAND_ACCENT = colors.HexColor("#2980B9")
SOFT_LINE = colors.HexColor("#E2E8F0")
INK_SOFT = colors.HexColor("#64748B")

# ---- Shrift ro'yxati (birinchi topilgani ishlatiladi) ----
_FONT = "Helvetica"
_FONT_BOLD = "Helvetica-Bold"
_FONT_REGISTERED = False


def _register_fonts() -> None:
    """Yunikod TTF shriftni topib ro'yxatdan o'tkazadi (bir marta).

    reportlab bilan keladigan Vera shriftlari kirill/lotinni qo'llaydi; tizimda
    DejaVu bo'lsa ham ishlatamiz. Topilmasa Helvetica (lotin) qoladi.
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

    # (oddiy, qalin) shrift juftliklari — birinchi mavjud bo'lgani tanlanadi
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
    for regular, bold in candidates:
        try:
            if os.path.exists(regular) and os.path.exists(bold):
                pdfmetrics.registerFont(TTFont("NurSans", regular))
                pdfmetrics.registerFont(TTFont("NurSans-Bold", bold))
                _FONT, _FONT_BOLD = "NurSans", "NurSans-Bold"
                return
        except Exception:  # pragma: no cover — shrift buzuq bo'lsa keyingisiga o'tamiz
            continue


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


def _customer_lines(order) -> list[str]:
    c = order.customer
    if not c:
        return ["—"]
    loc = ", ".join(x for x in [getattr(c, "region", None), getattr(c, "city", None),
                                getattr(c, "address", None)] if x)
    lines = [c.full_name]
    if c.phone:
        lines.append(f"Tel: {c.phone}")
    if loc:
        lines.append(loc)
    return lines


def _item_label(it) -> str:
    p = getattr(it, "product", None)
    if p is not None:
        name = getattr(p, "display_name", None) or getattr(p, "model", None) \
            or getattr(p, "name", None)
        if name:
            base = str(name)
            d = getattr(it, "bunker_direction", None)
            if d and getattr(p, "product_type", None) != "additional":
                base += " (o'ng)" if d == "right" else " (chap)" if d == "left" else ""
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
#  Kafolat sertifikati (warranty certificate)
# ============================================================================
def warranty_certificate_pdf(order) -> bytes:
    st = _styles()
    el: list = []

    el.append(_company_header(
        st, "KAFOLAT SERTIFIKATI",
        [("Buyurtma", order.code)],
    ))
    el.append(Spacer(1, 3 * mm))
    el.append(_rule())
    el.append(Spacer(1, 6 * mm))

    el.extend(_party_block(st, "MIJOZ", _customer_lines(order)))
    el.append(Spacer(1, 5 * mm))

    # Mahsulot(lar)
    prod_lines = []
    for it in order.items:
        sn = f" · S/N: {it.serial_id}" if getattr(it, "serial_id", None) else ""
        prod_lines.append(f"{_item_label(it)} × {it.quantity}{sn}")
    el.extend(_party_block(st, "MAHSULOT", prod_lines or ["—"]))
    el.append(Spacer(1, 6 * mm))

    # Kafolat muddati
    delivered = order.delivered_at
    if delivered:
        y1 = delivered + timedelta(days=365)
        y3 = delivered + timedelta(days=365 * 3)
        terms = [
            ["Yetkazilgan sana", _fmt_date(delivered)],
            ["1-yil (to'liq kafolat)", f"{_fmt_date(delivered)} — {_fmt_date(y1)}"],
            ["2-3 yil (faqat servis)", f"{_fmt_date(y1)} — {_fmt_date(y3)}"],
        ]
    else:
        terms = [["Holat", "Hali yetkazilmagan — kafolat boshlanmagan"]]
    tbl = Table(terms, colWidths=[55 * mm, 95 * mm])
    tbl.setStyle(TableStyle([
        ("FONTNAME", (0, 0), (0, -1), _FONT),
        ("FONTNAME", (1, 0), (1, -1), _FONT_BOLD),
        ("FONTSIZE", (0, 0), (-1, -1), 10),
        ("TEXTCOLOR", (0, 0), (0, -1), INK_SOFT),
        ("LINEBELOW", (0, 0), (-1, -1), 0.5, SOFT_LINE),
        ("TOPPADDING", (0, 0), (-1, -1), 6),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
    ]))
    el.append(tbl)

    el.append(Spacer(1, 6 * mm))
    el.append(Paragraph(
        "<b>Kafolat shartlari:</b> 1-yil davomida butlovchi qismlar va servis "
        "bepul. 2-3 yil davomida servis (chiqish) bepul, butlovchi qismlar mijoz "
        "hisobidan. Kafolat noto'g'ri foydalanish, mexanik shikast yoki ruxsatsiz "
        "ta'mirlash holatlarida bekor bo'ladi.", st["normal"]))

    el.append(Spacer(1, 16 * mm))
    el.append(_signature_block(st, ("NUR TECHNO GROUP", "Mijoz")))
    el.append(Spacer(1, 6 * mm))
    el.append(Paragraph(_footer_note(), st["small"]))
    return _build(el)


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
