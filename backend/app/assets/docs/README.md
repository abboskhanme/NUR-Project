# Hujjat imzolari

Kafolat sertifikatiga **avtomatik** qo'yiladigan imzo rasmlari shu papkada
turadi. Fayl nomlari qat'iy (kengaytma: `.png`, `.jpg`, `.jpeg`, `.webp` —
birinchi topilgani ishlatiladi):

| Fayl              | Nima uchun                              |
|-------------------|-----------------------------------------|
| `imzo-savdo.png`  | Savdo bo'limi mas'ul xodimining imzosi   |
| `imzo-servis.png` | Servis bo'limi mas'ul xodimining imzosi  |

Talablar:

- **Fon shaffof PNG** bo'lgani ma'qul (oq fon hujjatda quti bo'lib ko'rinadi).
- Taxminan 600×250 px yetarli; atrofidagi bo'sh joy kesilgan bo'lsin.
- Rasm nisbati saqlanadi: maks. 50×18 mm doirasiga joylashtiriladi.

Fayl qo'yilmasa hujjat baribir chiqadi — o'sha joyda bo'sh imzo chizig'i qoladi
(qo'lda imzolash uchun).

Imzo ostidagi F.I.Sh. `.env` orqali beriladi:

```
DOC_SALES_SIGNER="Familiya I.O."
DOC_SERVICE_SIGNER="Familiya I.O."
```

Rasmlar boshqa papkada tursin desangiz: `DOC_ASSETS_DIR=/opt/nur/docs`.
