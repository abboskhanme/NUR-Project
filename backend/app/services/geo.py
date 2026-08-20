"""Xarita havolalari va koordinatalar bilan ishlash.

Servis arizasiga lokatsiya turli ko'rinishda tushadi:

  * Telegram pin — koordinata strukturaviy keladi (tahlil kerak emas);
  * Google / Yandex / 2GIS / Apple / OSM xarita havolasi;
  * qisqartirilgan havola (maps.app.goo.gl, yandex.uz/maps/-/…) — ochib
    ko'rish kerak, koordinata faqat yakuniy manzilda bo'ladi;
  * oddiy matn: "41.311, 69.240".

Bu modul barchasini bitta (lat, lon) juftligiga keltiradi va aksincha —
koordinatadan navigator havolalarini yasaydi.

DIQQAT — tartib: Google `lat,lon`, Yandex (`ll`, `pt`) va 2GIS (`m`) esa
`lon,lat` beradi. Shuning uchun har bir manba alohida qaraladi.
"""
from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Optional
from urllib.parse import unquote, urlsplit, parse_qs

import httpx

__all__ = [
    "Coords", "parse_coords", "resolve_coords", "map_links",
    "looks_like_map_link", "format_coords", "valid_coords",
]

# O'zbekiston chegaralari (taxminiy) — koordinata teskari tushganini aniqlash
# uchun ishlatiladi. To'g'ri juftlikda bu yerda lat har doim lon dan kichik.
_UZ_LAT = (37.0, 45.7)
_UZ_LON = (55.9, 73.2)

_NUM = r"[-+]?\d{1,3}(?:\.\d+)?"
_PAIR_RE = re.compile(rf"({_NUM})\s*[,;\s]\s*({_NUM})")
_PAIR_ONLY_RE = re.compile(rf"^\s*({_NUM})\s*[,;\s]\s*({_NUM})\s*$")
_AT_RE = re.compile(rf"@({_NUM}),({_NUM})")
_PLACE_RE = re.compile(rf"!3d({_NUM})!4d({_NUM})")       # Google "place" havolasi
_GEO_RE = re.compile(rf"geo:({_NUM}),({_NUM})")
_HASH_MAP_RE = re.compile(rf"map=\d+(?:\.\d+)?/({_NUM})/({_NUM})")  # OSM
_URL_RE = re.compile(r"https?://\S+")

_UA = "Mozilla/5.0 (compatible; NUR-ERP/1.0; +https://www.nurtechnogroup.uz)"

# Qisqartirilgan havolalar — ichida koordinata yo'q, ochib ko'rish shart.
_SHORT_HOSTS = {"maps.app.goo.gl", "goo.gl", "g.co", "go.2gis.com", "ya.cc"}

_MAP_HINTS = (
    "google.com/maps", "google.uz/maps", "maps.google", "maps.app.goo.gl",
    "goo.gl/maps", "yandex.", "2gis.", "maps.apple.com", "openstreetmap.org",
)


@dataclass(frozen=True)
class Coords:
    lat: float
    lon: float


def _valid(lat: float, lon: float) -> bool:
    if not (-90.0 <= lat <= 90.0 and -180.0 <= lon <= 180.0):
        return False
    # (0, 0) — Atlantika okeani; deyarli har doim tahlil xatosi.
    return not (abs(lat) < 1e-6 and abs(lon) < 1e-6)


def _in_uz(lat: float, lon: float) -> bool:
    return _UZ_LAT[0] <= lat <= _UZ_LAT[1] and _UZ_LON[0] <= lon <= _UZ_LON[1]


def _make(a: float, b: float, *, lon_first: bool = False) -> Optional[Coords]:
    """(a, b) juftligidan Coords yasaydi, tartibni tekshirib/tuzatib."""
    lat, lon = (b, a) if lon_first else (a, b)
    if not _valid(lat, lon):
        lat, lon = lon, lat            # masalan lat=181 — juftlik teskari
        if not _valid(lat, lon):
            return None
    # Xavfsizlik to'ri: almashtirilganda O'zbekistonga tushib, hozirgi holatda
    # tushmasa — juftlik teskari kelgan (Yandex/2GIS "lon,lat" beradi).
    if not _in_uz(lat, lon) and _in_uz(lon, lat):
        lat, lon = lon, lat
    return Coords(round(lat, 7), round(lon, 7))


def _pair(value: str, *, lon_first: bool = False) -> Optional[Coords]:
    if not value:
        return None
    m = _PAIR_RE.search(value)
    if not m:
        return None
    try:
        return _make(float(m.group(1)), float(m.group(2)), lon_first=lon_first)
    except ValueError:
        return None


def _first_url(text: str) -> Optional[str]:
    m = _URL_RE.search(text or "")
    return m.group(0).rstrip(').,;"\'') if m else None


def is_short_link(url: str) -> bool:
    """Qisqartirilgan havolami — koordinata olish uchun ochib ko'rish kerakmi?"""
    parts = urlsplit(url)
    host = parts.netloc.lower()
    if host in _SHORT_HOSTS:
        return True
    # yandex.uz/maps/-/CDxxxxx — Yandexning qisqa ko'rinishi
    return "yandex." in host and parts.path.startswith("/maps/-/")


def _from_url(url: str) -> Optional[Coords]:
    """Havoladan koordinata (tarmoqqa chiqmasdan)."""
    if is_short_link(url):
        return None

    decoded = unquote(url)
    parts = urlsplit(decoded)
    host = parts.netloc.lower()
    query = parse_qs(parts.query, keep_blank_values=False)

    def param(*names: str) -> Optional[str]:
        for name in names:
            vals = query.get(name)
            if vals:
                return vals[0]
        return None

    def from_params(*names: str, lon_first: bool = False) -> Optional[Coords]:
        """Nomlar bo'yicha birinchi TAHLIL QILINADIGAN qiymat.

        Bitta parametr bo'lgani yetmaydi: Apple havolasida `q=Manzil` (matn) va
        `ll=41.3,69.2` yonma-yon keladi — matnli qiymatda to'xtab qolmaymiz.
        """
        for name in names:
            for value in query.get(name, []):
                coords = _pair(value, lon_first=lon_first)
                if coords:
                    return coords
        return None

    if "yandex." in host:
        # ll/pt — lon,lat; rtext — "lat,lon~lat,lon" (oxirgi nuqta = manzil)
        coords = from_params("ll", "pt", "whatshere[point]", lon_first=True)
        if coords:
            return coords
        rtext = param("rtext")
        if rtext:
            coords = _pair(rtext.split("~")[-1])
            if coords:
                return coords
    elif "2gis." in host:
        coords = from_params("m", "center", lon_first=True)
        if coords:
            return coords
    else:
        # Google / Apple / umumiy — lat,lon
        coords = from_params("q", "query", "daddr", "destination", "ll",
                             "center", "sll", "saddr")
        if coords:
            return coords
        mlat, mlon = param("mlat"), param("mlon")      # OpenStreetMap
        if mlat and mlon:
            try:
                coords = _make(float(mlat), float(mlon))
            except ValueError:
                coords = None
            if coords:
                return coords

    for pattern, lon_first in ((_PLACE_RE, False), (_AT_RE, False),
                               (_GEO_RE, False), (_HASH_MAP_RE, False)):
        m = pattern.search(decoded)
        if m:
            try:
                coords = _make(float(m.group(1)), float(m.group(2)), lon_first=lon_first)
            except ValueError:
                coords = None
            if coords:
                return coords

    # Oxirgi chora — havolaning yo'l qismidagi birinchi juftlik
    # (masalan 2gis.uz/tashkent/geo/…/69.24,41.31).
    return _pair(parts.path)


def _from_plain(text: str) -> Optional[Coords]:
    m = _GEO_RE.search(text)
    if m:
        try:
            return _make(float(m.group(1)), float(m.group(2)))
        except ValueError:
            return None
    m = _PAIR_RE.search(text)
    if not m:
        return None
    try:
        return _make(float(m.group(1)), float(m.group(2)))
    except ValueError:
        return None


def parse_coords(text: Optional[str]) -> Optional[Coords]:
    """Matn/havoladan koordinata — tarmoqqa chiqmasdan (tez yo'l)."""
    if not text:
        return None
    raw = text.strip()
    if not raw:
        return None
    url = _first_url(raw)
    return _from_url(url) if url else _from_plain(raw)


async def resolve_coords(text: Optional[str], *, timeout: float = 8.0) -> Optional[Coords]:
    """Koordinata — kerak bo'lsa qisqa havolani ochib ko'rib.

    Tarmoq xatosi jim yutiladi: bunda `None` qaytadi va foydalanuvchiga
    "koordinata topilmadi" deyiladi.
    """
    coords = parse_coords(text)
    if coords:
        return coords
    url = _first_url((text or "").strip())
    if not url:
        return None
    try:
        async with httpx.AsyncClient(follow_redirects=True, timeout=timeout,
                                     headers={"User-Agent": _UA}) as client:
            resp = await client.get(url)
    except Exception:  # noqa: BLE001 — tarmoq/timeout: tahlil qilib bo'lmadi
        return None

    coords = _from_url(str(resp.url))
    if coords:
        return coords
    if "text/html" not in resp.headers.get("content-type", ""):
        return None
    body = resp.text[:300_000]
    for pattern in (_PLACE_RE, _AT_RE):
        m = pattern.search(body)
        if m:
            try:
                coords = _make(float(m.group(1)), float(m.group(2)))
            except ValueError:
                coords = None
            if coords:
                return coords
    return None


def valid_coords(lat: float, lon: float) -> bool:
    """Koordinata haqiqiy chegaralarda va (0, 0) emasmi?"""
    return _valid(lat, lon)


def looks_like_map_link(text: Optional[str]) -> bool:
    """Botga tushgan matn xarita havolasi/koordinatami?"""
    if not text:
        return False
    raw = text.strip()
    low = raw.lower()
    if low.startswith("geo:"):
        return True
    if low.startswith("http") and any(hint in low for hint in _MAP_HINTS):
        return True
    return bool(_PAIR_ONLY_RE.match(raw))


def format_coords(lat: float, lon: float) -> str:
    return f"{lat:.6f}, {lon:.6f}"


def map_links(lat: float, lon: float) -> dict[str, str]:
    """Navigator havolalari — API kaliti yoki to'lov talab qilmaydi."""
    return {
        "yandex": f"https://yandex.uz/maps/?pt={lon:.6f},{lat:.6f}&z=17&l=map",
        "yandex_route": f"https://yandex.uz/maps/?rtext=~{lat:.6f},{lon:.6f}&rtt=auto",
        "google": f"https://www.google.com/maps/search/?api=1&query={lat:.6f},{lon:.6f}",
        "twogis": f"https://2gis.uz/geo/{lon:.6f},{lat:.6f}",
    }
