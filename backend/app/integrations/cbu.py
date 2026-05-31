"""CBU (O'zbekiston Markaziy banki) — daily USD/UZS rate fetch."""
from datetime import date
from decimal import Decimal
from typing import Optional

import httpx

from app.core.config import settings


async def fetch_usd_rate() -> Optional[Decimal]:
    """Fetch today's USD->UZS rate from CBU public API."""
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.get(settings.CBU_API_URL)
            resp.raise_for_status()
            data = resp.json()
            for item in data:
                if item.get("Ccy") == "USD":
                    return Decimal(item["Rate"])
    except Exception:
        return None
    return None
