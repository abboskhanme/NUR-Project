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
    ) -> AgentOutput:
        """Mijoz xabariga javob ishlab chiqadi.

        text          — mijoz yozgan matn
        is_comment    — ochiq izohmi (True) yoki DM (False)
        username      — Instagram username (kontekst uchun)
        media_caption — izoh qaysi post ostida (bilsak)
        history       — oldingi DM suhbati [{"role","content"}, ...]
        """
        system = build_system_prompt(kb.get_knowledge(), settings.COMPANY_NAME)

        ctx_lines = [
            f"Kanal: {'ochiq IZOH' if is_comment else 'shaxsiy xabar (DM)'}",
        ]
        if username:
            ctx_lines.append(f"Mijoz username: @{username}")
        if media_caption:
            ctx_lines.append(f"Post matni: {media_caption[:300]}")
        context = "\n".join(ctx_lines)

        messages: list[dict] = list(history or [])
        messages.append(
            {
                "role": "user",
                "content": f"[Kontekst]\n{context}\n\n[Mijoz xabari]\n{text}",
            }
        )

        result = await get_provider().generate(system, messages, AgentOutput)
        return result.clamp()
