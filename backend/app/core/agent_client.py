"""NUR Agent (Instagram) bilan ichki aloqa.

ERP'da Instagram tokeni saqlanmaydi — barcha Instagram amallari agent orqali
bajariladi (servis kaliti `X-Agent-Key` bilan). Agent bir xil Docker tarmog'ida
`agent:8000` nomi bilan ko'rinadi; topilmasa sozlamalardagi tashqi manzil
(`AGENT_PUBLIC_URL`) bo'yicha urinamiz.
"""
from __future__ import annotations

from typing import Any, Optional

import httpx
from fastapi import HTTPException

from app.core.config import settings

# Ichki (docker) manzil — birinchi navbatda shu sinaladi
INTERNAL_URL = "http://agent:8000"


def _bases(public_url: Optional[str]) -> list[str]:
    bases = [INTERNAL_URL]
    public = (public_url or "").rstrip("/")
    if public and public != INTERNAL_URL:
        bases.append(public)
    return bases


async def agent_request(
    method: str,
    path: str,
    *,
    json: Optional[dict[str, Any]] = None,
    params: Optional[dict[str, Any]] = None,
    public_url: Optional[str] = None,
    timeout: float = 20.0,
) -> dict:
    """Agentga so'rov yuboradi va JSON javobini qaytaradi.

    Agent javob bermasa 502, agent o'zi xato qaytarsa — o'sha xato matni bilan
    mos status kod ko'tariladi (operator sababni ko'rishi uchun).
    """
    if not settings.AGENT_INGEST_KEY:
        raise HTTPException(503, "AGENT_INGEST_KEY sozlanmagan")

    headers = {"X-Agent-Key": settings.AGENT_INGEST_KEY}
    last_error = ""
    for base in _bases(public_url):
        url = f"{base}{path}"
        try:
            async with httpx.AsyncClient(timeout=timeout) as client:
                resp = await client.request(
                    method, url, json=json, params=params, headers=headers
                )
        except httpx.HTTPError as exc:
            last_error = str(exc)
            continue

        if resp.status_code < 300:
            try:
                return resp.json()
            except ValueError:
                return {}
        # Agent javob berdi, lekin xato — qayta urinmaymiz
        detail = resp.text[:300]
        try:
            detail = resp.json().get("detail", detail)
        except ValueError:
            pass
        raise HTTPException(resp.status_code, f"Agent: {detail}")

    raise HTTPException(502, f"Agentga ulanib bo'lmadi — {last_error}")
