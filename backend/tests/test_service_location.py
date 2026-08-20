"""Lokatsiya tahlilchisi — mijoz yuboradigan barcha ko'rinishlar (DB kerak emas).

Eng muhim tuzoq: Google `lat,lon`, Yandex va 2GIS esa `lon,lat` beradi.
"""
import pytest

from app.services.geo import (
    Coords, format_coords, looks_like_map_link, map_links, parse_coords, valid_coords,
)

# Toshkent markazi — barcha havolalarda shu nuqta
LAT, LON = 41.311081, 69.240562


def _close(coords: Coords, lat: float = LAT, lon: float = LON, eps: float = 1e-4) -> bool:
    return coords is not None and abs(coords.lat - lat) < eps and abs(coords.lon - lon) < eps


@pytest.mark.parametrize("text", [
    # Google — lat,lon
    "https://www.google.com/maps?q=41.311081,69.240562",
    "https://www.google.com/maps/@41.311081,69.240562,17z",
    "https://maps.google.com/maps?q=41.311081,69.240562&z=17",
    "https://www.google.com/maps/search/?api=1&query=41.311081%2C69.240562",
    "https://www.google.com/maps/place/Tashkent/data=!3m1!4b1!3d41.311081!4d69.240562",
    # Yandex — ll/pt "lon,lat"
    "https://yandex.uz/maps/?ll=69.240562%2C41.311081&z=17",
    "https://yandex.uz/maps/10335/tashkent/?pt=69.240562,41.311081&z=17&l=map",
    # Yandex marshrut — rtext "lat,lon", manzil oxirgi nuqta
    "https://yandex.uz/maps/?rtext=41.200000%2C69.100000~41.311081%2C69.240562&rtt=auto",
    # 2GIS — m "lon,lat"
    "https://2gis.uz/tashkent?m=69.240562%2C41.311081%2F16",
    # Apple / OSM
    "https://maps.apple.com/?ll=41.311081,69.240562&q=Manzil",
    "https://www.openstreetmap.org/?mlat=41.311081&mlon=69.240562#map=17/41.311081/69.240562",
    # Havolasiz ko'rinishlar
    "geo:41.311081,69.240562",
    "41.311081, 69.240562",
    "41.311081 69.240562",
    # Teskari nusxalangan juftlik — O'zbekiston chegarasi bo'yicha tuzatiladi
    "69.240562, 41.311081",
])
def test_barcha_korinishlar_bir_nuqtaga_keladi(text):
    assert _close(parse_coords(text)), f"tahlil qilinmadi: {text}"


@pytest.mark.parametrize("text", [
    None, "", "   ", "salom qalaysiz", "Chilonzor 9-kvartal, 3-uy",
    # Qisqartirilgan havola — ichida koordinata yo'q, ochib ko'rish kerak
    "https://maps.app.goo.gl/AbCdEf123456",
    "https://yandex.uz/maps/-/CDxxxxxx",
])
def test_koordinata_yoq_hollar(text):
    assert parse_coords(text) is None


def test_moskva_koordinatasi_teskari_burilmaydi():
    """Almashtirish faqat O'zbekistonga tushganda ishlaydi — boshqa nuqta buzilmaydi."""
    coords = parse_coords("55.751244, 37.618423")
    assert coords is not None
    assert abs(coords.lat - 55.751244) < 1e-6
    assert abs(coords.lon - 37.618423) < 1e-6


def test_nolinchi_nuqta_rad_etiladi():
    assert parse_coords("0, 0") is None
    assert not valid_coords(0.0, 0.0)
    assert not valid_coords(91.0, 69.2)
    assert valid_coords(LAT, LON)


@pytest.mark.parametrize("text,expected", [
    ("https://maps.app.goo.gl/AbCdEf", True),
    ("https://yandex.uz/maps/?ll=69.2,41.3", True),
    ("41.311081, 69.240562", True),
    ("geo:41.3,69.2", True),
    ("Ertaga soat 10 da boramiz", False),
    ("https://nurtechnogroup.uz/mahsulot/12", False),
    ("", False),
])
def test_botga_tushgan_matn_lokatsiyami(text, expected):
    assert looks_like_map_link(text) is expected


def test_navigator_havolalari():
    links = map_links(LAT, LON)
    assert links["google"].endswith(f"{LAT:.6f},{LON:.6f}")      # Google: lat,lon
    assert f"pt={LON:.6f},{LAT:.6f}" in links["yandex"]           # Yandex: lon,lat
    assert links["twogis"].endswith(f"{LON:.6f},{LAT:.6f}")       # 2GIS: lon,lat
    assert format_coords(LAT, LON) == f"{LAT:.6f}, {LON:.6f}"
