"""SalesAgent — bitta xabarni AgentOutput ga aylantiradi.

Tizim ko'rsatmasi (persona + bilim) barqaror bo'lgani uchun Claude uni keshlaydi.
Suhbat tarixi + joriy xabar `messages` orqali uzatiladi.
"""
from __future__ import annotations

from app.agent import knowledge as kb
from app.agent.prompts import build_system_prompt
from app.ai.factory import get_provider
from app.config import settings
from app.models import AgentOutput


class SalesAgent:
    async def handle(
        self,
        text: str,
        *,
        is_comment: bool,
        username: str | None = None,
        media_caption: str | None = None,
        history: list[dict] | None = None,
        known: dict | None = None,
        has_attachment: bool = False,
    ) -> AgentOutput:
        """Mijoz xabariga javob ishlab chiqadi.

        text          — mijoz yozgan matn
        is_comment    — ochiq izohmi (True) yoki DM (False)
        username      — Instagram username (kontekst uchun)
        media_caption — izoh qaysi post ostida (bilsak)
        history       — oldingi DM suhbati [{"role","content"}, ...]
        known         — biz allaqachon bilgan faktlar (raqam, qiziqish, ism)
        has_attachment— mijoz matnsiz (ovoz/rasm) xabar yubordimi
        """
        system = build_system_prompt(kb.get_knowledge(), settings.COMPANY_NAME)

        ctx_lines = [
            f"Kanal: {'ochiq IZOH' if is_comment else 'shaxsiy xabar (DM)'}",
        ]
        if username:
            ctx_lines.append(f"Mijoz username: @{username}")
        if media_caption:
            ctx_lines.append(f"Post matni: {media_caption[:300]}")

        # Biz allaqachon bilgan ma'lumot — AI ularni QAYTA so'ramasligi uchun
        facts = _known_lines(known)
        if facts:
            ctx_lines.append(
                "Bu mijoz haqida ALLAQACHON bilamiz (qayta so'rama, "
                "javobingda shu ma'lumotdan foydalan):"
            )
            ctx_lines.extend(f"  - {line}" for line in facts)
        if has_attachment:
            ctx_lines.append(
                "DIQQAT: mijoz matnsiz xabar (ovoz/rasm/fayl) yubordi — biz uning "
                "ichini o'qiy olmaymiz. Iltimos, mazmunini matn bilan yozishini "
                "xushmuomala so'ra."
            )
        context = "\n".join(ctx_lines)

        messages: list[dict] = _normalize_history(history)
        current = f"[Kontekst]\n{context}\n\n[Mijoz xabari]\n{text}"
        if messages and messages[-1]["role"] == "user":
            messages[-1]["content"] += "\n\n" + current
        else:
            messages.append({"role": "user", "content": current})

        result = await get_provider().generate(system, messages, AgentOutput)
        return result.clamp()


_FACT_LABELS = {
    "name": "Ismi",
    "contact": "Telefon/kontakt",
    "product_interest": "Qiziqqan mahsulot",
    "summary": "Oldingi suhbat xulosasi",
}


def _known_lines(known: dict | None) -> list[str]:
    """ERP'dagi lead faktlarini prompt uchun qatorlarga aylantiradi."""
    if not known:
        return []
    lines: list[str] = []
    for key, label in _FACT_LABELS.items():
        value = (known.get(key) or "").strip() if isinstance(known.get(key), str) else None
        if value:
            lines.append(f"{label}: {value}")
    return lines


def _normalize_history(history: list[dict] | None) -> list[dict]:
    """Tarixni AI API talab qiladigan ko'rinishga keltiradi.

    ERP'dan kelgan yozuvlarda `at` (vaqt) va `operator` roli bo'lishi mumkin.
    Bundan tashqari suhbat "user" bilan boshlanishi va rollar navbatma-navbat
    kelishi kerak — ketma-ket bir xil rollar bitta xabarga qo'shiladi.
    """
    out: list[dict] = []
    for item in history or []:
        content = (item.get("content") or "").strip()
        if not content:
            continue
        role = "user" if item.get("role") == "user" else "assistant"
        # Suhbat "assistant" bilan boshlanmasin (API buni qabul qilmaydi)
        if not out and role == "assistant":
            continue
        if out and out[-1]["role"] == role:
            out[-1]["content"] += "\n" + content
            continue
        out.append({"role": role, "content": content})
    # Oxirgi xabar "user" bo'lsa, joriy xabar bilan qo'shilib ketmasligi uchun
    # uni "assistant" bilan yakunlamaymiz — core keyingi qadamda user qo'shadi,
    # ketma-ket ikki "user" bo'lsa API xato bermasligi uchun birlashtiramiz.
    return out
