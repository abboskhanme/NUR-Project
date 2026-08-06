# Hujjat imzolari va pechat

Kafolat sertifikatiga **avtomatik** qo'yiladigan rasmlar shu papkada turadi.
Fayl nomlari qat'iy (kengaytma: `.png`, `.jpg`, `.jpeg`, `.webp` — birinchi
topilgani ishlatiladi):

| Fayl             | Nima uchun                              |
|------------------|-----------------------------------------|
| `imzo-savdo.png` | Savdo bo'limi mas'ul xodimining imzosi   |
| `imzo-servis.png`| Servis bo'limi mas'ul xodimining imzosi  |
| `pechat.png`     | Kompaniya pechati (imzolar orasida)      |

Talablar:

- **Fon shaffof PNG** bo'lgani ma'qul (oq fon hujjatda quti bo'lib ko'rinadi).
- Imzo uchun taxminan 600×250 px, pechat uchun 600×600 px yetarli.
- Rasm nisbati saqlanadi: imzo maks. 54×16 mm, pechat maks. 38×38 mm doirasiga
  joylashtiriladi.

Fayl qo'yilmasa hujjat baribir chiqadi — o'sha joyda bo'sh imzo chizig'i qoladi
(qo'lda imzolash uchun).

Imzo ostidagi F.I.Sh. `.env` orqali beriladi:

```
DOC_SALES_SIGNER="Familiya I.O."
DOC_SERVICE_SIGNER="Familiya I.O."
```

Rasmlar boshqa papkada tursin desangiz: `DOC_ASSETS_DIR=/opt/nur/docs`.
