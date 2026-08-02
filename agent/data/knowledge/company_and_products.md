# NUR — kompaniya va mahsulotlar (NAMUNA — o'zingiznikiga almashtiring)

> Bu fayl AI agentga narx/mahsulot/FAQ ma'lumotini beradi. Pastdagi namunani
> o'chirib, HAQIQIY ma'lumotlaringizni yozing. Agent faqat shu yerdagi narxlarni
> aytadi; bu yerda yo'q narsani so'rashsa — operatorga o'tkazadi.
> O'zgartirgach: `POST /reload-knowledge` yoki konteynerni qayta ishga tushiring.

## Kompaniya haqida
- Nomi: NUR
- Nima bilan shug'ullanadi: (masalan — kotyol, bunker, garelka ishlab chiqarish)
- Ish vaqti: Dushanba–Shanba, 9:00–18:00
- Yetkazib berish: (bor/yo'q, qaysi hududlarga, narxi)
- To'lov: naqd / karta / bo'lib to'lash (bor bo'lsa)

## Mahsulotlar va narxlar
| Mahsulot | Hajm/o'lcham | Narx | Izoh |
|---|---|---|---|
| Kotyol | 50 L | (narx) | mavjud |
| Kotyol | 100 L | (narx) | buyurtma asosida |
| ... | ... | ... | ... |

## Ko'p so'raladigan savollar (FAQ)
- **Kafolat bormi?** (javob)
- **O'rnatib berasizmi?** (javob)
- **Qancha vaqtda tayyor bo'ladi?** (javob)

## Suhbat qoidalari (agent uchun)
- Narx so'ralsa va yuqorida bo'lsa — to'g'ridan-to'g'ri ayt.
- Narx yo'q yoki noaniq bo'lsa — o'ylab topma, operatorga o'tkaz.
- Buyurtma niyati bo'lsa — telefon raqamini so'ra.
