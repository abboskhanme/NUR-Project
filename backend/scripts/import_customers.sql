-- NUR SAVDO eski baza -> faqat MIJOZLAR importi (idempotent, bitta tranzaksiya)
-- Lokal:  docker compose exec -T postgres psql -U postgres -d nur_erp < backend/scripts/import_customers.sql
-- Server: docker compose -f docker-compose.prod.yml exec -T postgres psql -U postgres -d nur_erp < backend/scripts/import_customers.sql
-- DRY-RUN uchun oxiridagi COMMIT; ni ROLLBACK; ga o'zgartiring.
\set ON_ERROR_STOP on
BEGIN;

INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Xujamov jasurbek', '+998 93 788 03 06', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan norin', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 788 03 06');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'mingboev shoxrux', '+998 94 056 35 66', NULL, 'Uzbekistan', 'Toshkent', NULL, 'TOSHKENT SHAXAR', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 056 35 66');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Murodilayev Nodirbek', '+998 91 916 66 66', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan shaxar', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 916 66 66');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'AVAZBEK SATAROV', '+998 33 007 00 91', NULL, 'Uzbekistan', NULL, NULL, 'O''ZBEKISTON TUMANI', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 33 007 00 91');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'SOBIROV IQBOLJON', '+998 91 683 83 75', NULL, 'Uzbekistan', NULL, NULL, 'Uchkuprik tumani', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 683 83 75');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'SAFAROV ANVAR', '+998 94 025 10 08', NULL, 'Uzbekistan', NULL, NULL, 'SURXANDARYO MUZRABOT', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 025 10 08');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'UMAROV FAXRIDDIN', '+998 97 693 83 93', NULL, 'Uzbekistan', NULL, NULL, 'DANGARA MULK OBOD', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 693 83 93');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ALIYEV ADXAMJON', '+998 91 284 34 35', NULL, 'Uzbekistan', NULL, NULL, 'FARGONA QUVA', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 284 34 35');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'bozorbayev mansur', '+998 50 300 17 66', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan uychi', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 50 300 17 66');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'XOLMIRZAYEV ALISHER', '+998 91 050 08 51', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan NUROBOT', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 050 08 51');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Yunusuv oltmishvoy xoji', '+998 88 991 78 77', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon shaxrixon tumani', 'import', 'Eski bazadan import — 3 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 991 78 77');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ABDUQAYUMAVA NODIRA', '+998 99 810 99 86', NULL, 'Uzbekistan', 'Toshkent', NULL, 'TOSHKENT BUKA BUSTON', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 810 99 86');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'AZIMOV JAHONGIR', '+998 99 066 33 00', NULL, 'Uzbekistan', 'Namangan', NULL, 'YANGI NAMANGAN TUMAN SOHIL', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 066 33 00');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'MASAIDEV GIOSIDDIN', '+998 97 121 91 00', NULL, 'Uzbekistan', NULL, NULL, 'DANGARA SHIVOQ', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 121 91 00');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ABDURAHMONOV ABDUTOLIB', '+998 91 205 45 17', NULL, 'Uzbekistan', NULL, NULL, 'UCH KO`PRIK', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 205 45 17');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'TURSUNOV AHRORBEK', '+998 99 933 19 93', NULL, 'Uzbekistan', 'Namangan', NULL, 'NAMANGAN Norin', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 933 19 93');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'UTKIRJON ramazonov', '+385 955462622', '+998 91 975 94 05', 'Croatia', 'Buxoro', NULL, 'BUXORO peshku', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+385 955462622');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'QOSIMOV XOSONBOY', '+998 90 835 29 38', NULL, 'Uzbekistan', NULL, NULL, 'QO`SHTEPA TUMANI', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 835 29 38');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'QOSIMOV OYBEK', '+998 97 208 84 83', NULL, 'Uzbekistan', NULL, NULL, 'QO`SHTEPA TUMANI', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 208 84 83');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'QOSIMOV OTABEK', '+998 90 780 46 56', NULL, 'Uzbekistan', NULL, NULL, 'QO`SHTEPA TUMANI', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 780 46 56');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ulmas', '+998 90 600 13 60', NULL, 'Uzbekistan', 'Samarqand', NULL, 'SAMARQAND SHAXAR TURKSITON', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 600 13 60');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Komilov n', '+998 90 530 41 51', NULL, 'Uzbekistan', NULL, NULL, 'QUVA TUMANI', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 530 41 51');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'MADALIMOV O', '+998 90 711 60 50', NULL, 'Uzbekistan', NULL, NULL, 'O''ZBEKISTON tumani', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 711 60 50');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'AZIZBEK RAUPOV', '+998 90 251 08 88', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON ISBOSGAN', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 251 08 88');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'OBLAKULOV OTABEK', '+998 90 197 77 73', NULL, 'Uzbekistan', 'Samarqand', NULL, 'SAMARQAND URGUT', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 197 77 73');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'FAYZULLAYEV INODULLOJON', '+7 905 113 28 22', NULL, 'Russia/Kazakhstan', NULL, NULL, 'KOSONSOY', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+7 905 113 28 22');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'FAYZULLAYEV INODULLOJON', '+998 94 301 64 10', NULL, 'Uzbekistan', NULL, NULL, 'KOSONSOY', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 301 64 10');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ERGASHEV RASHIDBEK', '+998 95 007 92 85', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON BULOQ BOSHI', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 007 92 85');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'KENJAEV BAXROM', '+998 33 051 55 30', NULL, 'Uzbekistan', NULL, NULL, 'BUVAYDA TUMANI', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 33 051 55 30');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'BOYQO`ZIYEV IQBOLJON', '+998 88 965 72 22', NULL, 'Uzbekistan', NULL, NULL, 'BUVAYDA TUMANI', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 965 72 22');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'RAHIMOV ULUGBEK', '+998 90 627 16 71', '+998 90 967 16 60', 'Uzbekistan', 'Buxoro', NULL, 'BUXORO ARABXONA', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 627 16 71');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ERGASHEV U.M', '+998 91 665 49 92', NULL, 'Uzbekistan', NULL, NULL, 'OLTIARIG` TUMANI', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 665 49 92');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ortiqov Akmaljon', '+998 95 159 54 53', NULL, 'Uzbekistan', NULL, NULL, 'FARG`ONA OQ BILOL', 'import', 'Eski bazadan import — 2 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 159 54 53');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'RAHMONOV BURXONJON', '+998 99 994 93 23', NULL, 'Uzbekistan', NULL, NULL, 'uchkuprik kenagaz', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 994 93 23');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'QURBONOV MUROD', '+998 91 147 00 95', NULL, 'Uzbekistan', NULL, NULL, 'BOG`DOD NURAFSHON', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 147 00 95');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Oxunjonov xasanboy', '+998 93 900 88 82', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan turagurgon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 900 88 82');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Qodirov diyorbek', '+998 95 233 77 24', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon baliqchi', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 233 77 24');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'SHERZOD ERGASHEV', '+998 90 290 00 17', NULL, 'Uzbekistan', NULL, NULL, 'MARG`ILON BESHKAPA', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 290 00 17');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'SULTONOV FARRUX', '+998 93 044 03 62', NULL, 'Uzbekistan', NULL, NULL, 'BESHARIQ TUMANI', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 044 03 62');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'YUSUPOV UMIRZOQ', '+998 88 794 72 00', NULL, 'Uzbekistan', NULL, NULL, 'SURXANDARYO', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 794 72 00');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'VAHOBOV AKRAM', '+998 97 626 66 09', NULL, 'Uzbekistan', 'Namangan', NULL, 'NAMANGAN', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 626 66 09');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'NOMONOV AXATJON', '+998 95 368 83 35', NULL, 'Uzbekistan', NULL, NULL, 'KOSONSOY', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 368 83 35');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'MIRZAYEV FARXODJON', '+998 91 124 78 77', NULL, 'Uzbekistan', NULL, NULL, 'MARG`ILON', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 124 78 77');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'QO`LDASHEV JAXONGIR', '+998 88 737 03 13', '+998 90 573 05 66', 'Uzbekistan', 'Andijon', NULL, 'ANDIJON', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 737 03 13');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Мухторов Амон', '+998 88 238 32 97', NULL, 'Uzbekistan', NULL, NULL, 'бухоро карвон', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 238 32 97');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'IZZATOV OSTON', '+998 77 101 55 93', NULL, 'Uzbekistan', 'Buxoro', NULL, 'BUXORO PESHKO', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 77 101 55 93');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'RAXIMOVA SEVARA', '+998 99 054 83 93', NULL, 'Uzbekistan', NULL, NULL, 'XORAZIM SHOVOT', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 054 83 93');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'SADIYEV MUHAMMAD', '+998 90 251 08 01', NULL, 'Uzbekistan', 'Samarqand', NULL, 'SAMARQAND URGUT', 'import', 'Eski bazadan import — 22 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 251 08 01');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'BURXONOV ULUGBEK', '+998 90 869 17 08', NULL, 'Uzbekistan', 'Qashqadaryo', NULL, 'QASHQADARYO KITOB', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 869 17 08');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ABDUHAKIM JO''RAYEV', '+998 94 506 30 31', NULL, 'Uzbekistan', 'Namangan', NULL, 'NAMANGAN UCHQURGON', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 506 30 31');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Mansurxon', '+998 93 335 93 16', NULL, 'Uzbekistan', 'Samarqand', NULL, 'Samarqand', 'import', 'Eski bazadan import — 2 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 335 93 16');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'AMETOV AYBEK', '+998 99 575 93 74', NULL, 'Uzbekistan', NULL, NULL, 'Qoraqlpogiston', 'import', 'Eski bazadan import — 3 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 575 93 74');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'khujakulov ollayor', '+998 91 940 09 92', NULL, 'Uzbekistan', 'Jizzax', NULL, 'jizzax zarbdor tumani', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 940 09 92');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'xaitov uktam', '+998 99 999 89 41', NULL, 'Uzbekistan', 'Buxoro', NULL, 'Buxoro karvon b', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 999 89 41');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ELMUROD BEKCHONOV', '+998 91 436 66 69', NULL, 'Uzbekistan', NULL, NULL, 'XIVA SHAHAR', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 436 66 69');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'raxmatov b', '+998 93 588 59 88', NULL, 'Uzbekistan', NULL, NULL, 'SURXANDARYO TERMIZ', 'import', 'Eski bazadan import — 3 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 588 59 88');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'namazov a', '+998 99 679 52 78', NULL, 'Uzbekistan', NULL, NULL, 'SURXANDARYO TERMIZ', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 679 52 78');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'asqarov a', '+998 97 975 00 06', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON v andijon t', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 975 00 06');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Parpiyev Azimjon', '+998 88 133 86 83', NULL, 'Uzbekistan', 'Namangan', NULL, 'namangan turaqurgon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 133 86 83');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'HOLMATOV ERKINJON', '+998 93 410 15 10', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON ASAKA', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 410 15 10');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Qodirjon', '+998 90 531 18 48', NULL, 'Uzbekistan', NULL, NULL, 'Qoshtepa tumani', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 531 18 48');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'rahmattilo', '+998 90 277 71 32', '+998 91 117 45 43', 'Uzbekistan', NULL, NULL, 'Margilon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 277 71 32');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'qosimov m', '+998 90 151 52 60', NULL, 'Uzbekistan', NULL, NULL, 'Furqat t', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 151 52 60');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'jonibek', '+998 90 614 38 88', NULL, 'Uzbekistan', 'Buxoro', NULL, 'buxoro sh', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 614 38 88');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'abdurahmonov a', '+998 90 277 06 95', NULL, 'Uzbekistan', NULL, NULL, 'Margilon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 277 06 95');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'azambek', '+998 94 780 31 80', '+998 88 183 97 17', 'Uzbekistan', 'Buxoro', NULL, 'buxoro sh', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 780 31 80');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'alisher', '+998 90 583 20 80', NULL, 'Uzbekistan', NULL, NULL, 'quva', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 583 20 80');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'bobomurod', '+998 99 096 99 90', NULL, 'Uzbekistan', 'Xorazm', NULL, 'xorazm', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 096 99 90');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Abdurahmonov kamoliddin', '+998 99 600 28 00', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan shahar', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 600 28 00');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'boturov zarshed', '+998 93 341 41 11', NULL, 'Uzbekistan', 'Samarqand', NULL, 'Samarqand shaxar', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 341 41 11');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ALIBEKOV QAXRAMONJON', '+998 93 050 01 54', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON TUMANI', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 050 01 54');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Qodirov Kamollidin', '+998 90 254 15 10', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON TUMANI', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 254 15 10');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'SHAVKATJON A', '+998 91 679 45 86', NULL, 'Uzbekistan', NULL, NULL, 'YOZYAVON TUMANI', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 679 45 86');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'XAYDAROV OYBEK', '+998 94 832 89 96', NULL, 'Uzbekistan', 'Samarqand', NULL, 'SAMARQAND PAXTACHI', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 832 89 96');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'MUSABEKOV A', '+998 99 327 16 79', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON PAXTAOBOD', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 327 16 79');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'SUNATILLO', '+998 77 777 21 01', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON QURGONTEPA', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 77 777 21 01');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'AYUBXON', '+998 93 736 88 87', NULL, 'Uzbekistan', 'Namangan', NULL, 'NAMANGAN', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 736 88 87');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'qobilov abdulaxad', '+998 99 405 57 17', NULL, 'Uzbekistan', 'Namangan', NULL, 'NAMANGAN uchqurgon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 405 57 17');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'FAROHIDIN ABDUHAMIDOV', '+998 94 568 04 15', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON XONABOD', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 568 04 15');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'TOSHIEV NABIJON', '+998 99 900 75 63', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON MARXAMAT', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 900 75 63');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ABRORJON', '+998 99 605 57 17', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON ULUGNOR', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 605 57 17');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'SAITOV TALANTBEK', '+996 553019490', NULL, 'Kyrgyzstan', NULL, NULL, 'QIRGIZSTON OSH', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+996 553019490');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'RAHMONOV D', '+998 90 535 05 94', NULL, 'Uzbekistan', NULL, NULL, 'QUSHTEPA', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 535 05 94');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Abbos', '+998 99 417 35 17', NULL, 'Uzbekistan', 'Samarqand', NULL, 'samarqand pastargon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 417 35 17');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Xursanali', '+998 90 567 34 44', NULL, 'Uzbekistan', NULL, NULL, 'Bagdod', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 567 34 44');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'NARZIYEV SOBIRJON', '+998 97 577 74 10', NULL, 'Uzbekistan', 'Samarqand', NULL, 'samarqand pastargon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 577 74 10');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Ibragimov Rahmatillo', '+998 99 785 66 60', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 785 66 60');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'NUYDINOV MURODILJON', '+998 93 255 55 62', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON BUSTON', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 255 55 62');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'MUSTAFOYEV ZOKIRJON', '+7 925 466 02 51', NULL, 'Russia/Kazakhstan', 'Jizzax', NULL, 'JIZZAX PAXTAKOR', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+7 925 466 02 51');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Saidikromxon', '+998 97 583 98 00', NULL, 'Uzbekistan', NULL, NULL, 'aasaka tumani', 'import', 'Eski bazadan import — 2 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 583 98 00');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Ayubxon', '+998 97 217 77 11', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 217 77 11');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'MATNIYAZ', '+998 99 562 42 44', NULL, 'Uzbekistan', 'Xorazm', NULL, 'XORAZM', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 562 42 44');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ILHOMJON', '+998 94 748 02 00', NULL, 'Uzbekistan', NULL, NULL, 'TOSHLOQ TUMAN', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 748 02 00');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'LOCHINBEK', '+998 91 483 15 76', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON BULOQBOSHI', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 483 15 76');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'HUSHNUDBEK', '+998 90 202 11 22', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 202 11 22');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'QAHRAMONJON', '+998 99 503 27 35', NULL, 'Uzbekistan', 'Buxoro', NULL, 'BUXORO', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 503 27 35');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'AZAMXON', '+998 93 502 90 32', NULL, 'Uzbekistan', 'Buxoro', NULL, 'BUXORO', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 502 90 32');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'MAQSUDXON', '+998 99 611 60 01', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 611 60 01');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'nizomjon', '+7 929 917 47 87', NULL, 'Russia/Kazakhstan', 'Namangan', NULL, 'Namangan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+7 929 917 47 87');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Sirojiddin', '+998 99 621 01 11', NULL, 'Uzbekistan', NULL, NULL, 'rishton', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 621 01 11');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Isroiljon', '+998 33 963 30 55', NULL, 'Uzbekistan', NULL, NULL, 'Oltiariq', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 33 963 30 55');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Vohidjon', '+998 93 714 34 84', NULL, 'Uzbekistan', NULL, NULL, 'Qoraqalpogiston', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 714 34 84');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Xaliljon', '+998 90 271 77 00', NULL, 'Uzbekistan', NULL, NULL, 'Oltiariq', 'import', 'Eski bazadan import — 3 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 271 77 00');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Farxodjon', '+998 93 492 39 32', NULL, 'Uzbekistan', NULL, NULL, 'uychi tumani', 'import', 'Eski bazadan import — 2 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 492 39 32');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'XOLMATOV RAVSHAN', '+998 88 662 72 59', NULL, 'Uzbekistan', NULL, NULL, 'Margilon', 'import', 'Eski bazadan import — 3 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 662 72 59');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Qurbonboy', '+998 99 036 10 61', NULL, 'Uzbekistan', 'Xorazm', NULL, 'Xorazm', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 036 10 61');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Raxmatullo', '+998 97 253 93 93', NULL, 'Uzbekistan', NULL, NULL, 'uychi tumani', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 253 93 93');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Raxmatullo', '+998 91 364 01 99', NULL, 'Uzbekistan', NULL, NULL, 'uychi tumani', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 364 01 99');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Musulmonqul', '+998 97 337 50 02', NULL, 'Uzbekistan', NULL, NULL, 'Bogish qishlogi', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 337 50 02');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'HAMDAMJON', '+998 77 777 72 75', '+998 90 877 80 80', 'Uzbekistan', NULL, NULL, 'MARGILON', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 77 777 72 75');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'akmaljon', '+998 88 700 60 84', NULL, 'Uzbekistan', 'Qashqadaryo', NULL, 'qashqadaryo kitob', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 700 60 84');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'isxakov sharfkul', '+998 91 552 70 10', '+998 90 606 46 44', 'Uzbekistan', 'Samarqand', NULL, 'samarqand', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 552 70 10');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'shuxratjon', '+998 90 273 87 87', NULL, 'Uzbekistan', NULL, NULL, 'margilon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 273 87 87');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'MAGAZIN', '+998 91 173 33 11', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON DILLLER', 'import', 'Eski bazadan import — 3 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 173 33 11');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Karimov Soxibjon', '+998 94 404 42 12', NULL, 'Uzbekistan', NULL, NULL, 'Paxtabod tumani', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 404 42 12');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'JAHONGIR MUSAEV', '+998 88 666 07 71', '+998 91 652 61 00', 'Uzbekistan', NULL, NULL, 'QUVA TUMANI', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 666 07 71');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Karimov Sherali', '+998 91 655 95 00', NULL, 'Uzbekistan', NULL, NULL, 'Qushtepa tuman', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 655 95 00');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'JAHONGIR', '+998 99 603 53 99', NULL, 'Uzbekistan', NULL, NULL, 'UZBEKISTON TUMANI', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 603 53 99');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'SHAVKAT', '+998 99 507 80 05', NULL, 'Uzbekistan', 'Xorazm', NULL, 'XORAZM URGECHN', 'import', 'Eski bazadan import — 4 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 507 80 05');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'DOSTONBEK', '+998 99 896 54 54', NULL, 'Uzbekistan', NULL, NULL, 'margilon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 896 54 54');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ergashev xabibsher', '+998 93 730 04 01', NULL, 'Uzbekistan', NULL, NULL, 'buvayda', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 730 04 01');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'iqboljon', '+998 91 669 88 05', NULL, 'Uzbekistan', NULL, NULL, 'fargona', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 669 88 05');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'odiljon', '+998 93 483 42 02', NULL, 'Uzbekistan', NULL, NULL, 'yaypan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 483 42 02');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'xasanboy', '+998 93 441 85 70', NULL, 'Uzbekistan', 'Andijon', NULL, 'andijon shaxar', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 441 85 70');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'jAHONGIR', '+998 91 600 19 94', NULL, 'Uzbekistan', NULL, NULL, 'marxamat', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 600 19 94');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'TOLIBJON', '+998 93 243 19 19', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON PAXTA OBOD', 'import', 'Eski bazadan import — 2 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 243 19 19');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Dilshod', '+998 90 272 70 50', NULL, 'Uzbekistan', NULL, NULL, 'Margilon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 272 70 50');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'eSHANQULOV aKBAR', '+998 97 911 37 93', NULL, 'Uzbekistan', 'Samarqand', NULL, 'samarqand tuman', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 911 37 93');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ABDULAEV MUMINJON', '+998 90 407 29 94', NULL, 'Uzbekistan', NULL, NULL, 'YOZYOVON', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 407 29 94');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'MIRZAEV ADHAMJON', '+998 97 468 08 87', NULL, 'Uzbekistan', NULL, NULL, 'UCHQURGON', 'import', 'Eski bazadan import — 2 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 468 08 87');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ABDUQAHHOR', '+998 93 677 99 22', NULL, 'Uzbekistan', 'Namangan', NULL, 'NAMANGAN UYCHI', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 677 99 22');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'OLIMOV TOHIR', '+998 93 866 18 92', NULL, 'Uzbekistan', 'Namangan', NULL, 'NAMANGAN NORIN', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 866 18 92');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'TILLABOEV ABBOS', '+998 97 345 20 42', NULL, 'Uzbekistan', NULL, NULL, 'BUSTONLIQ TUMANI', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 345 20 42');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ABRORJON', '+998 90 560 87 89', NULL, 'Uzbekistan', NULL, NULL, 'Qushtepa tuman', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 560 87 89');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ERGASHEV DALER', '+998 94 199 31 91', NULL, 'Uzbekistan', 'Jizzax', NULL, 'JIZZAX ZAFAROBOD', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 199 31 91');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'AXMEDOV JURABEK', '+998 91 441 38 46', NULL, 'Uzbekistan', 'Buxoro', NULL, 'BUXORO VOBKENT', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 441 38 46');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'MURODIL', '+998 99 819 00 88', NULL, 'Uzbekistan', NULL, NULL, 'QUVA TUMANI', 'import', 'Eski bazadan import — 2 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 819 00 88');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'MURODIL', '+998 97 819 00 88', NULL, 'Uzbekistan', NULL, NULL, 'QUVA TUMANI', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 819 00 88');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'MARUFJON', '+998 88 223 20 92', NULL, 'Uzbekistan', 'Samarqand', NULL, 'SAMARQAND TOYLOQ', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 223 20 92');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'AZAMJON BOZOROV', '+998 99 303 52 37', NULL, 'Uzbekistan', 'Namangan', NULL, 'NAMANGAN YANGIQURGON', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 303 52 37');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'DOVRONJON', '+998 90 366 43 43', NULL, 'Uzbekistan', NULL, NULL, 'MANGIT', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 366 43 43');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'TOHIRJON', '+998 93 942 15 00', NULL, 'Uzbekistan', 'Namangan', NULL, 'NAMANGAN', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 942 15 00');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'JOBIRXON', '+998 90 750 46 64', NULL, 'Uzbekistan', 'Namangan', NULL, 'NAMANGAN', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 750 46 64');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'BURXON', '+998 99 657 77 00', NULL, 'Uzbekistan', 'Samarqand', NULL, 'samarqand', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 657 77 00');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'DILMUROD', '+998 90 290 00 37', NULL, 'Uzbekistan', NULL, NULL, 'MARGILON', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 290 00 37');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'BOZORVOY', '+998 90 164 64 45', NULL, 'Uzbekistan', NULL, NULL, 'MARGILON', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 164 64 45');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Anarov Eminjon', '+998 94 448 61 18', NULL, 'Uzbekistan', NULL, NULL, 'beshariq', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 448 61 18');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Sarvarjon', '+998 91 138 24 70', NULL, 'Uzbekistan', NULL, NULL, 'yaypan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 138 24 70');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Alberganov Farrux', '+998 99 446 23 48', NULL, 'Uzbekistan', NULL, NULL, 'Xorazim Xiva', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 446 23 48');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Qushaniv Sherzod', '+998 91 482 08 15', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon buloqboshi', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 482 08 15');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'IBRAGIMOV KOZIMJON', '+998 93 781 36 10', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON JALAQUDUQ', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 781 36 10');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'IBRAGIMOV KOZIMJON', '+998 93 789 36 19', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON JALAQUDUQ', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 789 36 19');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'SIROJIDIN', '+998 91 161 03 03', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON QURQONTEPA', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 161 03 03');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Muhammad', '+998 88 791 60 20', NULL, 'Uzbekistan', NULL, NULL, 'Xorazim Xiva', 'import', 'Eski bazadan import — 2 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 791 60 20');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'sirojiddin', '+998 88 117 58 83', NULL, 'Uzbekistan', 'Samarqand', NULL, 'Samarqand urgut', 'import', 'Eski bazadan import — 3 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 117 58 83');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'abduhamid qurbonov', '+998 99 971 76 68', NULL, 'Uzbekistan', 'Andijon', NULL, 'andijon marxamat', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 971 76 68');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Numonov Shermurod', '+998 93 737 55 58', NULL, 'Uzbekistan', NULL, NULL, 'Buvayda tumani', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 737 55 58');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'tuychiyev salohidin', '+998 94 447 81 11', NULL, 'Uzbekistan', NULL, NULL, 'mangit', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 447 81 11');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Otaxonov Bekmurod', '+998 50 108 10 00', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon marxamat', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 50 108 10 00');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Qodirxonov Baxodir', '+998 94 279 00 18', NULL, 'Uzbekistan', 'Namangan', NULL, 'namangan shahar', 'import', 'Eski bazadan import — 2 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 279 00 18');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Ruslan', '+998 99 403 04 09', NULL, 'Uzbekistan', 'Toshkent', NULL, 'Toshkent shahar', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 403 04 09');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'akmaljon', '+998 93 733 45 07', NULL, 'Uzbekistan', NULL, NULL, 'MARGILON', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 733 45 07');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Iskandar', '+998 90 309 18 00', NULL, 'Uzbekistan', NULL, NULL, 'Buvayda tumani', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 309 18 00');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Fayozbek', '+998 99 907 33 74', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon shaxar', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 907 33 74');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Boburjon', '+998 90 622 47 49', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon shaxar', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 622 47 49');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'xusanboy', '+998 90 210 98 35', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon marhamat', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 210 98 35');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'baxtiyorjon', '+998 93 389 60 30', NULL, 'Uzbekistan', NULL, NULL, 'jizzah', 'import', 'Eski bazadan import — 2 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 389 60 30');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Jalolliddin', '+998 90 300 83 84', NULL, 'Uzbekistan', NULL, NULL, 'Oltiariq', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 300 83 84');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'azimjonov bobur', '+998 99 989 35 19', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon buloqboshi', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 989 35 19');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Yaqubov komiljon', '+998 91 205 55 77', NULL, 'Uzbekistan', NULL, NULL, 'UZBEKISTON TUMANI', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 205 55 77');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'qodirjon', '+998 91 490 73 77', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon shaxar', 'import', 'Eski bazadan import — 2 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 490 73 77');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Beshariq tumani', '+998 94 496 74 00', NULL, 'Uzbekistan', NULL, NULL, 'Beshariq tumani', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 496 74 00');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'MUHAMMAD', '+998 90 534 30 15', NULL, 'Uzbekistan', NULL, NULL, 'QUVA TUMANI', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 534 30 15');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'NURMUHAMMAD', '+998 91 112 12 23', NULL, 'Uzbekistan', NULL, NULL, 'margilon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 112 12 23');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'hamidjon', '+998 77 078 11 87', NULL, 'Uzbekistan', 'Namangan', NULL, 'namanganb uchqurgon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 77 078 11 87');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Avazbek', '+998 91 119 43 52', NULL, 'Uzbekistan', NULL, NULL, 'Toshloq tumani', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 119 43 52');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'XASANBOY', '+998 91 114 54 30', NULL, 'Uzbekistan', NULL, NULL, 'VODIL', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 114 54 30');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Asqarov Uchqunbek', '+998 93 448 70 41', NULL, 'Uzbekistan', NULL, NULL, 'BALIQCHI TUMAN', 'import', 'Eski bazadan import — 6 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 448 70 41');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Mansurxon', '+998 77 384 40 49', NULL, 'Uzbekistan', 'Namangan', NULL, 'namangan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 77 384 40 49');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'tuychi', '+998 93 477 76 97', NULL, 'Uzbekistan', NULL, NULL, 'Samarqnd toyloq', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 477 76 97');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Akmaljon', '+998 97 000 60 40', NULL, 'Uzbekistan', NULL, NULL, 'Chust', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 000 60 40');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'GULNORA', '+998 90 301 70 74', NULL, 'Uzbekistan', NULL, NULL, 'Qushtepa', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 301 70 74');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Qahharjon', '+998 91 110 26 06', NULL, 'Uzbekistan', NULL, NULL, 'Margilon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 110 26 06');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'MUHAMMADDIN', '+998 90 211 60 62', NULL, 'Uzbekistan', NULL, NULL, 'Marhamat tuman', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 211 60 62');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Donyor', '+998 99 430 10 35', NULL, 'Uzbekistan', NULL, NULL, 'Yangiqurgon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 430 10 35');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Qobil', '+998 90 214 77 46', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 214 77 46');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Isaqov Muzaffar', '+998 93 941 10 04', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan uychi', 'import', 'Eski bazadan import — 2 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 941 10 04');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'JASURBEK', '+998 99 690 85 70', NULL, 'Uzbekistan', NULL, NULL, 'UCHKUPRIK', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 690 85 70');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'GANIJON', '+998 97 552 59 50', NULL, 'Uzbekistan', NULL, NULL, 'SURXANDARYO DENOV', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 552 59 50');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'BEGALI', '+998 91 684 13 90', NULL, 'Uzbekistan', NULL, NULL, 'UZBEKISTON TUMANI', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 684 13 90');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'BAXROMJON', '+998 99 992 05 24', NULL, 'Uzbekistan', NULL, NULL, 'UZBEKISTON TUMANI', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 992 05 24');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Dilshod', '+998 90 457 84 84', NULL, 'Uzbekistan', NULL, NULL, 'Margilon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 457 84 84');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Avazbek', '+998 91 154 54 50', NULL, 'Uzbekistan', NULL, NULL, 'Yaypan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 154 54 50');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Faxriddin', '+998 95 960 21 10', NULL, 'Uzbekistan', NULL, NULL, 'Uchqurgon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 960 21 10');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Nosirjon', '+998 93 949 87 91', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon Qurgontepa', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 949 87 91');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Rustamjon', '+998 77 001 39 16', '+998 99 005 35 74', 'Uzbekistan', NULL, NULL, 'Kosonsoy tumani', 'import', 'Eski bazadan import — 2 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 77 001 39 16');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Sardor', '+998 95 645 20 20', NULL, 'Uzbekistan', NULL, NULL, 'Norin tumani', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 645 20 20');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Isroilov azizjon', '+998 91 323 07 33', NULL, 'Uzbekistan', NULL, NULL, 'qoqon shahar', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 323 07 33');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Sarvarjon', '+998 90 068 01 05', NULL, 'Uzbekistan', NULL, NULL, 'Uychi tuman', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 068 01 05');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Saidxon', '+998 91 348 17 77', '+998 90 753 39 33', 'Uzbekistan', NULL, NULL, 'Kosonsoy tumani', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 348 17 77');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Rasulbek', '+998 91 994 66 63', NULL, 'Uzbekistan', NULL, NULL, 'Xiva tuman', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 994 66 63');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'MUHAMMADJON', '+998 94 277 08 07', NULL, 'Uzbekistan', NULL, NULL, 'chust tumani', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 277 08 07');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Jurayev Mardior', '+998 93 496 42 42', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan tumani', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 496 42 42');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Azizbek', '+998 99 903 02 06', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon Jalaquduq', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 903 02 06');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'MUSALLAS', '+998 91 399 69 59', NULL, 'Uzbekistan', NULL, NULL, 'Qoraqalpogiston', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 399 69 59');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Xurshidbek', '+998 94 383 00 35', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon xonobod', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 383 00 35');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Avazbek', '+998 93 794 33 00', NULL, 'Uzbekistan', NULL, NULL, 'Norin tumani', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 794 33 00');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'umrzoq', '+998 99 162 77 07', NULL, 'Uzbekistan', NULL, NULL, 'SURXANDARYO termz', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 162 77 07');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'umrzoq', '+998 99 762 00 26', NULL, 'Uzbekistan', NULL, NULL, 'SURXANDARYO termz', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 762 00 26');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'MAGAZIN', '+998 90 777 00 66', NULL, 'Uzbekistan', NULL, NULL, 'MAGILOB MAGAZIN', 'import', 'Eski bazadan import — 3 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 777 00 66');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'nosirjon', '+998 77 373 10 92', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON BUSTON TUMANI', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 77 373 10 92');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Sardor', '+998 88 949 88 89', NULL, 'Uzbekistan', NULL, NULL, 'Toshloq tuman', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 949 88 89');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Ahliddin', '+998 91 202 18 92', '+998 90 556 96 89', 'Uzbekistan', NULL, NULL, 'Bogdod tuman', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 202 18 92');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'SHAXZOD SOVUNOV', '+998 91 546 08 95', NULL, 'Uzbekistan', 'Samarqand', NULL, 'SAMARQAND JOMBOY', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 546 08 95');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'MUHAMMADQODIR', '+998 90 302 00 57', NULL, 'Uzbekistan', NULL, NULL, 'MARGILON SHAXAR', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 302 00 57');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'DONYORJON', '+998 93 490 50 02', NULL, 'Uzbekistan', NULL, NULL, 'TURAQURGON', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 490 50 02');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'SHUXRATBEK', '+998 50 054 84 10', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 50 054 84 10');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Turabek', '+998 77 000 26 08', NULL, 'Uzbekistan', NULL, NULL, 'UZBEKISTON TUMANI', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 77 000 26 08');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Akmaljon', '+998 95 951 29 79', NULL, 'Uzbekistan', NULL, NULL, 'TURAQURGON', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 951 29 79');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Qamchiev Abror', '+998 99 972 14 45', NULL, 'Uzbekistan', NULL, NULL, 'Isboskan tuman', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 972 14 45');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Qahramonjon', '+998 91 914 24 44', NULL, 'Uzbekistan', NULL, NULL, 'Xiva tuman', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 914 24 44');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'MUHAMMADYUSUF', '+998 93 100 52 41', NULL, 'Uzbekistan', NULL, NULL, 'Rishton', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 100 52 41');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Muzaffar', '+998 90 271 77 44', NULL, 'Uzbekistan', NULL, NULL, 'Rishton', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 271 77 44');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Abdurahim', '+998 99 325 47 44', NULL, 'Uzbekistan', NULL, NULL, 'Asaka', 'import', 'Eski bazadan import — 4 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 325 47 44');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Umidjon usta', '+998 88 636 55 55', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan tumani', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 636 55 55');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ruzi ali', '+998 98 558 77 84', NULL, 'Uzbekistan', NULL, NULL, 'uchkuprik', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 98 558 77 84');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Dostonbek', '+998 88 713 40 00', NULL, 'Uzbekistan', NULL, NULL, 'o''zbekiston tumani', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 713 40 00');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Jaloliddin', '+998 97 812 65 66', NULL, 'Uzbekistan', NULL, NULL, 'Nurafshon qishlogi', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 812 65 66');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'shokirjon', '+998 91 689 49 10', NULL, 'Uzbekistan', NULL, NULL, 'bogdod soy buyi', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 689 49 10');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'bexruz fayziyev', '+998 91 313 17 71', NULL, 'Uzbekistan', 'Samarqand', NULL, 'Samarqand tuman', 'import', 'Eski bazadan import — 4 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 313 17 71');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Murodilxon', '+998 97 217 61 01', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan kosonsoy', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 217 61 01');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Sardorbek', '+998 90 597 33 36', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan chortoq', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 597 33 36');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Narimonjon', '+998 94 301 04 40', NULL, 'Uzbekistan', NULL, NULL, 'Qashqar qishlogi', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 301 04 40');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Salimjon', '+998 90 560 46 26', NULL, 'Uzbekistan', NULL, NULL, 'Marg''ilon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 560 46 26');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'abdulloh', '+998 91 201 83 00', NULL, 'Uzbekistan', NULL, NULL, 'o''zbekston tumani', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 201 83 00');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'farruh usta', '+998 91 140 46 02', NULL, 'Uzbekistan', NULL, NULL, 'o''zbekston tumani', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 140 46 02');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'akmalxon', '+998 93 403 04 43', '+998 33 780 16 16', 'Uzbekistan', NULL, NULL, 'namanagan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 403 04 43');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'akbarali', '+998 97 187 53 03', NULL, 'Uzbekistan', NULL, NULL, 'namanagan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 187 53 03');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'mirzayev sherzod', '+998 97 418 20 22', NULL, 'Uzbekistan', NULL, NULL, 'beshariq', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 418 20 22');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'saidjon', '+998 95 165 27 77', NULL, 'Uzbekistan', NULL, NULL, 'uchkuprik', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 165 27 77');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'mihudinov jalolidin', '+998 94 644 15 61', NULL, 'Uzbekistan', 'Samarqand', NULL, 'samarqand kattaqurgon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 644 15 61');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'MUHAMMADJON', '+998 94 155 67 65', NULL, 'Uzbekistan', 'Namangan', NULL, 'NAMANGAN UYCHI', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 155 67 65');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'KOZIMXOM', '+998 93 651 78 00', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON ASAKA', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 651 78 00');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'SHOKIROV SHOVKAT', '+998 91 360 62 00', NULL, 'Uzbekistan', 'Namangan', NULL, 'NAMANGAN SHAXAR', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 360 62 00');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Abdurashid', '+998 91 563 04 04', NULL, 'Uzbekistan', NULL, NULL, 'Margilon', 'import', 'Eski bazadan import — 5 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 563 04 04');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Muzaffar', '+998 97 640 27 27', NULL, 'Uzbekistan', NULL, NULL, 'Margilon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 640 27 27');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Farruxbek', '+998 91 601 00 11', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 601 00 11');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Shuhratjon', '+998 33 266 80 07', NULL, 'Uzbekistan', NULL, NULL, 'Rishton', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 33 266 80 07');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Sobirjon', '+998 95 141 00 89', NULL, 'Uzbekistan', NULL, NULL, 'Chust tumani', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 141 00 89');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Adhamjon', '+998 91 125 00 23', NULL, 'Uzbekistan', NULL, NULL, 'Yozyovon tuman', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 125 00 23');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'xabbullayev sabrllo', '+998 93 720 20 01', NULL, 'Uzbekistan', 'Samarqand', NULL, 'Samarqand tuman', 'import', 'Eski bazadan import — 3 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 720 20 01');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Abdulaziz', '+998 90 551 57 57', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan shahar', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 551 57 57');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'MUXAMMADXON', '+998 90 218 70 00', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan shahar', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 218 70 00');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Zuxriddin', '+998 93 258 44 86', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan norin', 'import', 'Eski bazadan import — 2 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 258 44 86');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Baxriddin', '+998 93 403 77 04', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan norin', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 403 77 04');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Boychanov Aqilbek', '+998 93 432 17 05', '+998 93 300 35 00', 'Uzbekistan', NULL, NULL, 'Navoi Konimex', 'import', 'Eski bazadan import — 2 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 432 17 05');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Dilmurod', '+998 93 510 73 10', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan', 'import', 'Eski bazadan import — 2 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 510 73 10');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Rustamjon', '+998 95 973 01 50', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 973 01 50');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Yaqubjon', '+998 90 308 95 05', NULL, 'Uzbekistan', NULL, NULL, 'Yoyilma uchkoprik', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 308 95 05');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Yaxyobek', '+998 99 393 92 92', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan Norin', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 393 92 92');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'QOBILJON', '+998 88 999 87 81', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON BALIQCHI', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 999 87 81');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Yaxyobek', '+998 93 179 80 20', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 179 80 20');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ALISHER', '+996 552233360', NULL, 'Kyrgyzstan', NULL, NULL, 'QIRGIZISTON OSH', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+996 552233360');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ALISHER', '+996 558808071', NULL, 'Kyrgyzstan', NULL, NULL, 'QIRGIZISTON OSH', 'import', 'Eski bazadan import — 4 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+996 558808071');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Uktam', '+998 91 176 75 79', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon Buloqboshi', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 176 75 79');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Olovuddin', '+998 99 138 26 68', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon Xonobod', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 138 26 68');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'abdulatif mansurov', '+998 94 376 00 04', NULL, 'Uzbekistan', NULL, NULL, 'olmaliq', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 376 00 04');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'nizomiddinov xusniddin', '+998 93 213 33 88', NULL, 'Uzbekistan', 'Namangan', NULL, 'namangan norin', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 213 33 88');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'mamadaliyev abdumalik', '+998 77 254 10 10', '+998 93 946 16 66', 'Uzbekistan', 'Namangan', NULL, 'namangan shaxar', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 77 254 10 10');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'mamatov mirzoxid', '+998 99 922 30 09', NULL, 'Uzbekistan', 'Namangan', NULL, 'namangan shaxar', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 922 30 09');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'abdullayev shokirjon', '+998 90 214 77 84', NULL, 'Uzbekistan', 'Namangan', NULL, 'namangan shaxar', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 214 77 84');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'O''rinboev A', '+998 91 652 35 45', NULL, 'Uzbekistan', NULL, NULL, 'MARGILON magazin', 'import', 'Eski bazadan import — 11 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 652 35 45');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Xoldorov Shohruh', '+998 94 311 91 90', '+998 93 771 67 60', 'Uzbekistan', NULL, NULL, 'Fargona qushtepa', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 311 91 90');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'adxamjon', '+998 97 212 25 15', '+998 93 938 29 94', 'Uzbekistan', 'Namangan', NULL, 'namangan uychi', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 212 25 15');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'UMIDJON', '+998 97 583 01 23', NULL, 'Uzbekistan', NULL, NULL, 'ASAKA SHAHAR', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 583 01 23');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'O''rinboev Almat', '+998 97 353 72 63', NULL, 'Uzbekistan', NULL, NULL, 'Qoraqolpog''iston', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 353 72 63');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Rasuljon', '+998 90 278 25 32', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan shahar', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 278 25 32');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'gulomjon uktamovich', '+998 33 557 46 54', NULL, 'Uzbekistan', NULL, NULL, 'xorazim bogdod tumani', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 33 557 46 54');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'yusupov azzibek', '+998 91 157 61 61', NULL, 'Uzbekistan', NULL, NULL, 'rishton tumani', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 157 61 61');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Hamitov Donyor', '+998 99 749 23 96', NULL, 'Uzbekistan', 'Buxoro', NULL, 'Buxoro', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 749 23 96');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Egamberdiev Bobur', '+998 88 277 55 90', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan Uychi', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 277 55 90');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), '30179', '+998 99 326 63 48', NULL, 'Uzbekistan', NULL, NULL, 'Sux tumani', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 326 63 48');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'UMIDJON', '+998 93 731 81 89', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon Xujabod', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 731 81 89');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Azamjon', '+998 91 290 67 77', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon Qorasuv', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 290 67 77');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Dostonbek', '+998 88 177 46 00', NULL, 'Uzbekistan', NULL, NULL, 'Buloqboshi', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 177 46 00');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Dilbarxon', '+998 94 387 50 43', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon Marxamat', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 387 50 43');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'xoliqov umed', '+992 920147000', NULL, 'Tajikistan', NULL, NULL, 'tojikiston spitamen', 'import', 'Eski bazadan import — 2 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+992 920147000');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ahadjon', '+992 988802575', NULL, 'Tajikistan', NULL, NULL, 'TOJIKSTON USTA RAVSHAN', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+992 988802575');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'GANIYEV BAXTIYOR', '+998 88 107 50 53', NULL, 'Uzbekistan', 'Samarqand', NULL, 'SAMARQAND SHAXAR', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 107 50 53');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ABDURAHMOVOV', '+998 95 707 14 90', '+998 94 717 72 72', 'Uzbekistan', 'Namangan', NULL, 'NAMANGAN', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 707 14 90');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'SUPORBOYEV NODIRBEK', '+998 95 212 05 05', NULL, 'Uzbekistan', NULL, NULL, 'XORAZIM YANGI BOZOR TUMANI', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 212 05 05');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Turdiev Zavqiy', '+998 97 280 87 90', NULL, 'Uzbekistan', 'Buxoro', NULL, 'Buxoro Jondor', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 280 87 90');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Faxriddin', '+996 555655255', NULL, 'Kyrgyzstan', NULL, NULL, 'Qirgisizton', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+996 555655255');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'azizbek', '+998 94 953 94 94', NULL, 'Uzbekistan', 'Namangan', NULL, 'NAMANGAN', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 953 94 94');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Isaev Xusniddin', '+998 97 615 00 11', NULL, 'Uzbekistan', 'Samarqand', NULL, 'Samarqand toyloq', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 615 00 11');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Erkinjon', '+998 91 785 95 95', NULL, 'Uzbekistan', NULL, NULL, 'Uchkuprik', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 785 95 95');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Marufjon', '+998 93 206 98 83', NULL, 'Uzbekistan', NULL, NULL, 'Fargona', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 206 98 83');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Fozilbek', '+998 99 190 61 76', NULL, 'Uzbekistan', NULL, NULL, 'Uchkuprik', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 190 61 76');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'yusupov aminjon', '+998 93 260 32 22', NULL, 'Uzbekistan', 'Namangan', NULL, 'namangan codak', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 260 32 22');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'isaqov ibrohimjon', '+998 99 327 30 92', '+998 91 109 06 26', 'Uzbekistan', NULL, NULL, 'margilon toshloq', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 327 30 92');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Abdulbosit', '+998 93 442 22 45', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 442 22 45');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Akramjon', '+998 91 176 15 40', '+998 90 258 68 91', 'Uzbekistan', 'Andijon', NULL, 'andijon', 'import', 'Eski bazadan import — 3 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 176 15 40');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Bahromjon', '+998 88 729 23 24', NULL, 'Uzbekistan', NULL, NULL, 'Oltiariq', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 729 23 24');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Rasuljon', '+998 94 310 92 29', NULL, 'Uzbekistan', NULL, NULL, 'Margilon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 310 92 29');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'mamurjon', '+998 97 582 00 04', '+998 99 235 51 00', 'Uzbekistan', 'Andijon', NULL, 'andijon qurgontepa', 'import', 'Eski bazadan import — 2 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 582 00 04');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'arstanbek', '+996 773673200', NULL, 'Kyrgyzstan', NULL, NULL, 'Qirgisizton', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+996 773673200');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ulugbek', '+996 771343435', NULL, 'Kyrgyzstan', NULL, NULL, 'Qirgisizton', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+996 771343435');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'azamxon', '+998 93 913 70 17', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 913 70 17');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Xusniddin', '+998 88 956 00 05', NULL, 'Uzbekistan', NULL, NULL, 'Beshariq', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 956 00 05');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Oybek', '+998 90 407 39 34', NULL, 'Uzbekistan', NULL, NULL, 'Margilon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 407 39 34');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Jamshidbek', '+998 94 108 00 07', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan Norin', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 108 00 07');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Mirzaqosimjon', '+998 99 011 92 75', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 011 92 75');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'RUZMATJON', '+998 94 135 03 81', NULL, 'Uzbekistan', NULL, NULL, 'KOTTA TURK', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 135 03 81');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'farxodjon', '+998 97 580 24 42', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon asaka', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 580 24 42');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Faxriddin', '+998 97 211 17 17', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 211 17 17');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'dilshod', '+998 97 520 19 90', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 520 19 90');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'murodjon', '+998 91 398 88 45', NULL, 'Uzbekistan', NULL, NULL, 'Margilon', 'import', 'Eski bazadan import — 2 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 398 88 45');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ziyodbek', '+998 93 195 99 09', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan norin', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 195 99 09');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'nozimxon', '+998 50 575 52 44', NULL, 'Uzbekistan', NULL, NULL, 'yaypan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 50 575 52 44');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Azamatjon', '+998 91 113 57 77', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon viloyat', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 113 57 77');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Isomiddin', '+998 94 278 33 22', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 278 33 22');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'mamura', '+998 94 117 70 02', NULL, 'Uzbekistan', NULL, NULL, 'gurum saroy', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 117 70 02');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Baxtiyorjon', '+998 93 595 21 02', NULL, 'Uzbekistan', NULL, NULL, 'furqat tumani', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 595 21 02');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'eshonqulov davlat', '+998 97 926 04 39', NULL, 'Uzbekistan', 'Samarqand', NULL, 'samarqand rayon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 926 04 39');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'xaydarov baxodir', '+998 77 184 09 88', NULL, 'Uzbekistan', 'Samarqand', NULL, 'samarqand pastargon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 77 184 09 88');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Sayidullo', '+998 93 683 66 60', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan shahar', 'import', 'Eski bazadan import — 2 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 683 66 60');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'SHUXRATJON', '+998 91 115 03 03', NULL, 'Uzbekistan', NULL, NULL, 'MARGILON', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 115 03 03');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Muxtor', '+998 99 745 77 52', NULL, 'Uzbekistan', 'Buxoro', NULL, 'Buxoro Romitan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 745 77 52');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'FARXOD', '+998 99 506 90 19', '+998 99 706 90 19', 'Uzbekistan', 'Buxoro', NULL, 'BUXORO OLOT', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 506 90 19');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'OZODBEK', '+998 95 630 18 06', '+998 99 792 86 82', 'Uzbekistan', NULL, NULL, 'RISHTON', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 630 18 06');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Abdurahmon', '+998 91 497 27 28', NULL, 'Uzbekistan', NULL, NULL, 'Andilon Nurobod', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 497 27 28');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'abdullox', '+998 33 200 15 14', NULL, 'Uzbekistan', NULL, NULL, 'toshloq fargona', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 33 200 15 14');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'abduraimjon', '+998 33 718 24 89', NULL, 'Uzbekistan', NULL, NULL, 'margilon shaxar', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 33 718 24 89');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'nizomiddin', '+998 88 844 75 45', NULL, 'Uzbekistan', NULL, NULL, 'surxandaryo denov', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 844 75 45');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Sobir', '+998 94 514 12 34', NULL, 'Uzbekistan', 'Buxoro', NULL, 'buxoro Olot', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 514 12 34');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'FARRUH', '+998 90 899 89 08', NULL, 'Uzbekistan', 'Qashqadaryo', NULL, 'Qashqadaryo Kitob', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 899 89 08');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'xayrullo', '+998 90 625 50 31', NULL, 'Uzbekistan', 'Andijon', NULL, 'andijon marxamat', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 625 50 31');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Abduhamid', '+998 99 437 72 27', NULL, 'Uzbekistan', NULL, NULL, 'Margilon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 437 72 27');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'rufat', '+998 99 318 78 78', '+998 93 093 64 44', 'Uzbekistan', 'Xorazm', NULL, 'xorazm xonka tulkin', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 318 78 78');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'sobir', '+998 93 341 77 79', '+998 93 356 22 22', 'Uzbekistan', 'Samarqand', NULL, 'samarqand galla osiyo', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 341 77 79');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'MUHAMMADODIL', '+998 90 293 55 25', NULL, 'Uzbekistan', NULL, NULL, 'QO''QON SHAHAR', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 293 55 25');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Salahiddin', '+998 90 700 04 44', NULL, 'Uzbekistan', NULL, NULL, 'o''zbekiston tumani', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 700 04 44');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Bahriddin', '+998 90 039 19 63', NULL, 'Uzbekistan', 'Samarqand', NULL, 'Samarqand Payariq', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 039 19 63');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'BAXTIYOR', '+998 77 786 08 88', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON BUSTON', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 77 786 08 88');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ABDUMALIK', '+998 90 380 22 23', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON JALAQUDUQ', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 380 22 23');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'SANJAR', '+998 93 413 22 42', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON SHAXAR', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 413 22 42');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'DAVRONBEK', '+998 97 480 51 01', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON SHAXAR', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 480 51 01');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ABROR', '+998 99 673 71 23', NULL, 'Uzbekistan', 'Samarqand', NULL, 'SAMARQAND QUSHRABOT', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 673 71 23');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'NEMAT', '+998 77 500 70 40', NULL, 'Uzbekistan', NULL, NULL, 'Qoqon shahar', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 77 500 70 40');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'AVAZBEK', '+998 93 698 59 92', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON PAXTA OBOD', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 698 59 92');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'SHERZOD', '+998 91 113 77 00', '+998 94 994 69 91', 'Uzbekistan', NULL, NULL, 'QUSHTEPA TUMANI', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 113 77 00');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'RO`ZMATJON', '+998 95 155 30 30', NULL, 'Uzbekistan', NULL, NULL, 'DOIM OBOD', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 155 30 30');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'xusniddin', '+998 94 153 00 70', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 153 00 70');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Qosimjon', '+998 97 755 28 89', NULL, 'Uzbekistan', NULL, NULL, 'Bustonliq xumson', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 755 28 89');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Javlon', '+998 90 426 33 32', NULL, 'Uzbekistan', 'Qashqadaryo', NULL, 'Qashqadaryo chiroqchi', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 426 33 32');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Ravshan', '+998 94 930 80 21', NULL, 'Uzbekistan', 'Samarqand', NULL, 'Samarqand Toyloq', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 930 80 21');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Rahmatillo', '+998 99 314 91 01', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan shahar', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 314 91 01');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'MUHAMMAD', '+998 90 967 16 71', NULL, 'Uzbekistan', 'Buxoro', NULL, 'Buxoro Arabxona', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 967 16 71');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'o`tkirbek', '+998 97 964 87 00', NULL, 'Uzbekistan', 'Andijon', NULL, 'andijon xuja obod', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 964 87 00');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Egamov Ulugbek', '+998 91 995 43 44', NULL, 'Uzbekistan', NULL, NULL, 'Xiva tumani', 'import', 'Eski bazadan import — 2 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 995 43 44');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Abdulloh', '+998 99 699 27 28', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan shahar', 'import', 'Eski bazadan import — 2 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 699 27 28');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Zoxidjon', '+998 93 290 00 75', NULL, 'Uzbekistan', NULL, NULL, 'Fargona Quvasoy', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 290 00 75');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'rovshan', '+998 88 325 00 11', NULL, 'Uzbekistan', 'Jizzax', NULL, 'jizzax', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 325 00 11');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'sobirjon', '+998 99 519 88 50', NULL, 'Uzbekistan', 'Namangan', NULL, 'namangan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 519 88 50');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Ibroximjon', '+998 99 130 00 15', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 130 00 15');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Murodjon', '+998 99 826 62 47', NULL, 'Uzbekistan', NULL, NULL, 'Margilon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 826 62 47');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'adxamjon', '+998 90 854 20 06', NULL, 'Uzbekistan', NULL, NULL, 'uchkuprik', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 854 20 06');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Nodirbek', '+998 90 790 76 67', NULL, 'Uzbekistan', NULL, NULL, 'Namnagan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 790 76 67');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'bekmujrod', '+992 110200123', NULL, 'Tajikistan', NULL, NULL, 'tojikiston', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+992 110200123');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'shoaxmad', '+998 90 597 86 82', NULL, 'Uzbekistan', NULL, NULL, 'chust', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 597 86 82');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'zikirjon', '+998 95 394 32 32', NULL, 'Uzbekistan', 'Samarqand', NULL, 'samarqand urgut', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 394 32 32');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'shuxrat', '+998 93 845 46 57', NULL, 'Uzbekistan', NULL, NULL, 'tojikiston', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 845 46 57');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'muhammad sodiq', '+998 97 468 00 44', NULL, 'Uzbekistan', 'Namangan', NULL, 'namangan yangi qurg`on', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 468 00 44');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'xusniddin', '+998 99 190 45 09', NULL, 'Uzbekistan', NULL, NULL, 'Namnagan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 190 45 09');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Nodirbek', '+998 91 462 97 77', NULL, 'Uzbekistan', 'Qashqadaryo', NULL, 'Qashqadaryo', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 462 97 77');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Dilshod', '+998 50 303 31 24', NULL, 'Uzbekistan', NULL, NULL, 'RISHTON', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 50 303 31 24');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Manucher', '+998 91 532 06 06', NULL, 'Uzbekistan', 'Samarqand', NULL, 'Samarqand', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 532 06 06');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'MAHMUDJON', '+998 93 404 90 09', NULL, 'Uzbekistan', 'Namangan', NULL, 'NAMANGAN', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 404 90 09');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'AYUBXON', '+998 93 678 77 66', NULL, 'Uzbekistan', 'Namangan', NULL, 'NAMANGAN', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 678 77 66');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'barxayotjon', '+998 99 145 88 72', NULL, 'Uzbekistan', NULL, NULL, 'uzbekiston tumani', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 145 88 72');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'XIKMATILLO', '+998 93 783 79 97', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 783 79 97');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'umidjon', '+998 93 661 30 12', NULL, 'Uzbekistan', 'Navoiy', NULL, 'navoiy', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 661 30 12');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Ibrohimjon', '+998 90 217 40 00', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 217 40 00');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Akmalxon', '+998 94 035 24 24', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 035 24 24');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Otabek', '+998 97 996 52 86', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 996 52 86');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'tojiboyev m', '+998 93 870 60 07', NULL, 'Uzbekistan', 'Andijon', NULL, 'andijon bus', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 870 60 07');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'xasanov sultonbek', '+998 97 168 37 37', '+998 94 389 33 33', 'Uzbekistan', 'Andijon', NULL, 'andijon ulugnor', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 168 37 37');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'abbosxon', '+998 93 173 73 73', NULL, 'Uzbekistan', 'Namangan', NULL, 'namangan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 173 73 73');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'MUXRIDDIN', '+998 93 407 41 40', '+998 94 081 02 65', 'Uzbekistan', 'Namangan', NULL, 'namangan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 407 41 40');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'KOMIL', '+998 94 096 33 39', NULL, 'Uzbekistan', 'Samarqand', NULL, 'SAMARQAND', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 096 33 39');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'abbosxon', '+998 94 305 55 00', NULL, 'Uzbekistan', 'Buxoro', NULL, 'buxoro', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 305 55 00');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Xamroqul', '+998 99 660 19 77', NULL, 'Uzbekistan', NULL, NULL, 'Shahrisabz', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 660 19 77');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'UBAYDULLO', '+998 94 501 32 00', NULL, 'Uzbekistan', 'Namangan', NULL, 'NAMANGAN CHORTOQ', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 501 32 00');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Islomxon', '+998 99 975 91 91', NULL, 'Uzbekistan', NULL, NULL, 'pop tumani', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 975 91 91');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Masudxon', '+998 95 673 22 44', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan tumani', 'import', 'Eski bazadan import — 2 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 673 22 44');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Akbarjon', '+998 95 679 19 74', NULL, 'Uzbekistan', 'Samarqand', NULL, 'Samarqand pstargom', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 679 19 74');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Ahror', '+998 99 620 07 06', NULL, 'Uzbekistan', 'Samarqand', NULL, 'Samarqand', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 620 07 06');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Hasanov Akram', '+998 50 997 30 01', NULL, 'Uzbekistan', 'Buxoro', NULL, 'Buxoro Olot', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 50 997 30 01');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Abdusamad', '+998 90 136 76 45', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon Marhamat', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 136 76 45');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Ikramov Rustam', '+998 91 136 49 39', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon Shahrihon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 136 49 39');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'TOXIRJONOV UMIDJON', '+998 90 525 29 29', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON JALAQUDOQ', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 525 29 29');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Rahmatillo', '+998 90 534 04 09', NULL, 'Uzbekistan', NULL, NULL, 'Quva shahar', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 534 04 09');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'SIDIQJON', '+998 90 272 11 19', NULL, 'Uzbekistan', NULL, NULL, 'FURQAT TUMANI', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 272 11 19');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'RAVSHAN', '+998 93 446 04 97', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 446 04 97');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'DANOXON', '+998 90 526 20 36', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 526 20 36');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'MANSURBEK', '+998 90 773 06 89', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON ASAKA', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 773 06 89');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ISROILJON', '+998 94 389 10 07', NULL, 'Uzbekistan', NULL, NULL, 'NAMANAGN UYCHI', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 389 10 07');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'SAIDJAMOL', '+998 90 405 11 75', '+998 95 955 11 75', 'Uzbekistan', NULL, NULL, 'MARGILON QUMTEPA', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 405 11 75');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Jasur', '+998 99 447 18 55', NULL, 'Uzbekistan', 'Samarqand', NULL, 'Samarqand', 'import', 'Eski bazadan import — 2 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 447 18 55');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Ibodulla', '+998 95 038 02 51', NULL, 'Uzbekistan', 'Qashqadaryo', NULL, 'Qarshi shahar', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 038 02 51');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Alisher', '+998 94 922 70 70', NULL, 'Uzbekistan', 'Namangan', NULL, 'namangan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 922 70 70');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Dovudxon', '+998 94 453 00 07', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 453 00 07');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Elbek', '+998 90 589 83 33', NULL, 'Uzbekistan', NULL, NULL, 'Uchkuprik', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 589 83 33');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Akmal prakror', '+998 91 120 39 77', NULL, 'Uzbekistan', NULL, NULL, 'Oltiariq', 'import', 'Eski bazadan import — 2 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 120 39 77');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Murodjon', '+998 94 904 75 07', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon Qurgontepa', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 904 75 07');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Muslimbek', '+998 91 155 02 16', NULL, 'Uzbekistan', NULL, NULL, 'Uchkuprik', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 155 02 16');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Olimboy', '+998 93 912 41 12', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan', 'import', 'Eski bazadan import — 2 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 912 41 12');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Yunusjon', '+998 97 790 48 68', NULL, 'Uzbekistan', NULL, NULL, 'Xorazim', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 790 48 68');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Ashurov Sanjarbek', '+998 94 325 12 78', NULL, 'Uzbekistan', 'Buxoro', NULL, 'Buxoro', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 325 12 78');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'kimsanboyev sanjar', '+998 91 141 68 68', NULL, 'Uzbekistan', NULL, NULL, 'uchkuprik kenagaz', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 141 68 68');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Abdulboriy', '+998 90 205 55 87', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 205 55 87');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'SHUKURJON', '+998 99 515 65 03', NULL, 'Uzbekistan', NULL, NULL, 'DANGARA ISTIQOL', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 515 65 03');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'FARHOD', '+998 33 637 60 89', NULL, 'Uzbekistan', NULL, NULL, 'DANGARA ISTIQOL', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 33 637 60 89');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Abdurahim', '+998 99 190 36 33', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan Uychi', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 190 36 33');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Nuriddin', '+7 917 016 64 69', NULL, 'Russia/Kazakhstan', NULL, NULL, 'SOGK TOJIK', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+7 917 016 64 69');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Mavlonbek', '+998 90 627 57 11', NULL, 'Uzbekistan', NULL, NULL, 'Eski shildir', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 627 57 11');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Soliyev Sardor', '+998 91 244 44 15', NULL, 'Uzbekistan', 'Buxoro', NULL, 'Buxoro viloyati', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 244 44 15');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Sardorbek', '+998 88 007 17 55', NULL, 'Uzbekistan', 'Buxoro', NULL, 'Buxoro Qorakul', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 007 17 55');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Nematjon', '+998 97 600 30 07', NULL, 'Uzbekistan', NULL, NULL, 'Xorazim Bog"ot', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 600 30 07');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Adhamjon', '+998 94 603 88 22', NULL, 'Uzbekistan', NULL, NULL, 'Baliqchi tuman', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 603 88 22');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Gaziev Amon', '+998 97 214 77 02', NULL, 'Uzbekistan', NULL, NULL, 'Xujand Tojikiston', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 214 77 02');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Mansurbek', '+998 93 218 83 83', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 218 83 83');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Dilshod', '+998 93 714 30 36', NULL, 'Uzbekistan', 'Samarqand', NULL, 'Samarqand', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 714 30 36');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Fayzullo', '+998 99 603 73 03', NULL, 'Uzbekistan', NULL, NULL, 'Beshariq', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 603 73 03');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Muhriddin', '+998 94 305 50 30', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan Kosonsoy', 'import', 'Eski bazadan import — 2 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 305 50 30');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Muzaffar', '+998 91 044 84 04', NULL, 'Uzbekistan', NULL, NULL, 'Marg"ilon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 044 84 04');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Samariddin', '+998 99 575 64 22', NULL, 'Uzbekistan', 'Samarqand', NULL, 'Samarqand', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 575 64 22');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Rixsitillo', '+998 99 716 48 24', NULL, 'Uzbekistan', 'Buxoro', NULL, 'Buxoror Kogon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 716 48 24');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Habib', '+998 91 142 00 01', NULL, 'Uzbekistan', NULL, NULL, 'Marg"ilon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 142 00 01');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Asilbek', '+998 77 155 28 28', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon Baliqchi', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 77 155 28 28');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Begzodjon', '+998 50 030 11 33', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon shaxrihon', 'import', 'Eski bazadan import — 2 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 50 030 11 33');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Alimardon', '+998 90 920 64 10', NULL, 'Uzbekistan', NULL, NULL, 'Buvqayda', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 920 64 10');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Akramxuja', '+998 91 624 45 41', NULL, 'Uzbekistan', 'Sirdaryo', NULL, 'Sirdaryo Guliston', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 624 45 41');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Ravshan', '+998 93 683 08 82', NULL, 'Uzbekistan', 'Buxoro', NULL, 'Buxoro tuman', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 683 08 82');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Rahimjon', '+998 91 660 38 88', NULL, 'Uzbekistan', NULL, NULL, 'Marg''ilon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 660 38 88');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Farxodjon', '+998 91 681 38 06', NULL, 'Uzbekistan', 'Farg''ona', NULL, 'Farg''ona tuman', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 681 38 06');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ALISHER', '+998 91 606 07 06', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON BALIQCHI', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 606 07 06');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'G''anijon', '+998 77 268 85 77', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon Jalaquduq', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 77 268 85 77');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ALHAMJON', '+998 33 631 53 62', NULL, 'Uzbekistan', NULL, NULL, 'SUX TUMANI', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 33 631 53 62');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'DODAHALFA', '+998 99 990 20 33', NULL, 'Uzbekistan', NULL, NULL, 'SUX TUMANI', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 990 20 33');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Mo''minmirzo', '+998 94 414 04 04', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan shahar', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 414 04 04');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'JURAYEV ELDORBEK', '+998 92 144 08 29', NULL, 'Uzbekistan', NULL, NULL, 'BESHARIQ KAPAYANGI', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 92 144 08 29');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Salimov Akbar', '+998 91 645 52 56', NULL, 'Uzbekistan', 'Buxoro', NULL, 'Buxoro Romitan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 645 52 56');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Murodov Donyor', '+998 93 681 80 85', NULL, 'Uzbekistan', 'Buxoro', NULL, 'Buxoro tumani', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 681 80 85');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ABDULATIB', '+998 50 757 39 29', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON XUJABOT', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 50 757 39 29');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Ilhom G''ulomov', '+998 88 300 01 62', NULL, 'Uzbekistan', 'Buxoro', NULL, 'Buxoro Jondor', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 300 01 62');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'DILMUROD', '+998 97 562 71 71', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON QURQONTEPA', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 562 71 71');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Abdulla Abdusattarov', '+998 99 710 06 66', NULL, 'Uzbekistan', NULL, NULL, 'Termiz shahar', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 710 06 66');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Inamzoda Ruxullox', '+998 99 292 60 00', NULL, 'Uzbekistan', NULL, NULL, 'Tojik Iataravshan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 292 60 00');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Faridun Hakimov', '+998 93 997 77 05', NULL, 'Uzbekistan', 'Samarqand', NULL, 'Samarqand selski rayon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 997 77 05');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Dilmuradjon', '+998 70 014 88 55', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon asaka', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 70 014 88 55');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Rahmatjon', '+998 88 959 95 55', NULL, 'Uzbekistan', 'Farg''ona', NULL, 'Farg''ona shahar', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 959 95 55');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'rashidov nodir', '+998 97 826 19 19', NULL, 'Uzbekistan', 'Buxoro', NULL, 'Buxoro tumani', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 826 19 19');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Qoboljon Mamajonov', '+998 50 020 86 76', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan shahar', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 50 020 86 76');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Farxodjon', '+998 99 142 70 91', NULL, 'Uzbekistan', NULL, NULL, 'Angren shahar', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 142 70 91');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Alisherjon', '+998 91 667 90 01', NULL, 'Uzbekistan', NULL, NULL, 'Margilon shahar', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 667 90 01');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Muhabbatxon', '+998 95 887 11 00', NULL, 'Uzbekistan', NULL, NULL, 'uzb tumani yaypan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 887 11 00');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Sherxon', '+998 55 105 47 67', NULL, 'Uzbekistan', NULL, NULL, 'Qoraqalpogiston', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 55 105 47 67');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Muhammediyar', '+998 99 348 97 26', NULL, 'Uzbekistan', NULL, NULL, 'Qoraqalpogiston', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 348 97 26');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Saidislom', '+998 90 540 94 94', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan Mingbuloq', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 540 94 94');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'abbas usta', '+998 97 547 40 04', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon buloqboshi', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 547 40 04');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Mirzoxon', '+998 93 455 00 00', NULL, 'Uzbekistan', 'Buxoro', NULL, 'BUXORO diller', 'import', 'Eski bazadan import — 3 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 455 00 00');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Madaminjon', '+998 94 150 85 46', NULL, 'Uzbekistan', NULL, NULL, 'Pop tumani', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 150 85 46');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Kozimjon', '+998 90 157 25 35', NULL, 'Uzbekistan', NULL, NULL, 'Yaypan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 157 25 35');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Sherzodjon', '+998 97 331 28 68', NULL, 'Uzbekistan', 'Qashqadaryo', NULL, 'Qashqadaryo', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 331 28 68');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Jasurbek', '+998 91 181 23 01', NULL, 'Uzbekistan', NULL, NULL, 'Norin tumani', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 181 23 01');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Tolibjon', '+996 550883110', NULL, 'Kyrgyzstan', NULL, NULL, 'Qirgiziston', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+996 550883110');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Murodjon', '+998 97 230 67 67', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan Turaqurg''on', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 230 67 67');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Shohobidin', '+998 50 300 16 71', '+998 93 163 07 83', 'Uzbekistan', 'Samarqand', NULL, 'Samarqand pasturgon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 50 300 16 71');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Shuhratjon', '+998 99 593 51 53', NULL, 'Uzbekistan', 'Samarqand', NULL, 'Samarqand Jomboy', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 593 51 53');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'muhammadali', '+998 90 286 83 83', NULL, 'Uzbekistan', 'Samarqand', NULL, 'samarqand toyloq', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 286 83 83');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Vohidjon', '+998 91 129 32 10', NULL, 'Uzbekistan', NULL, NULL, 'Fargona Mingdon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 129 32 10');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Zoyirjon', '+998 90 633 06 90', NULL, 'Uzbekistan', NULL, NULL, 'Fargona Mingdon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 633 06 90');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Ikromjon', '+998 94 297 90 90', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan shahar', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 297 90 90');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'RAIMJONOV XAYRULO', '+998 91 126 20 06', NULL, 'Uzbekistan', NULL, NULL, 'QUVA TUMANI', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 126 20 06');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ABDULAYEV MUZAFFAR', '+998 95 185 31 95', NULL, 'Uzbekistan', 'Samarqand', NULL, 'SAMARQAND ISHTIXON', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 185 31 95');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ADURAHMANOV', '+998 93 058 88 72', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON V IZBOSGAN', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 058 88 72');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Ruslan', '+998 97 350 66 82', NULL, 'Uzbekistan', NULL, NULL, 'Surxandaryo Sarosiyo', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 350 66 82');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Asadbek', '+998 90 156 70 15', '+998 90 792 78 28', 'Uzbekistan', 'Namangan', NULL, 'Namangan chust', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 156 70 15');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Sherzod', '+998 93 520 01 93', NULL, 'Uzbekistan', 'Samarqand', NULL, 'Samarqand', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 520 01 93');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'AZIZBEK', '+998 94 660 54 87', NULL, 'Uzbekistan', NULL, NULL, 'NAMMANGAN QUMQURGON', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 660 54 87');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'BARXAYOTJON', '+998 93 144 86 18', NULL, 'Uzbekistan', NULL, NULL, 'DANGARA OGJAR', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 144 86 18');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Nuriddinjon', '+998 94 619 86 62', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon Buloqboshi', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 619 86 62');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'xusanboy', '+998 90 384 33 63', NULL, 'Uzbekistan', 'Andijon', NULL, 'andijon shaxrixon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 384 33 63');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Islomjon', '+998 90 507 14 19', NULL, 'Uzbekistan', NULL, NULL, 'Qoqon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 507 14 19');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Abdullo', '+998 88 911 20 00', NULL, 'Uzbekistan', 'Samarqand', NULL, 'Samarqand', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 911 20 00');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Jafar', '+998 97 391 91 66', NULL, 'Uzbekistan', 'Samarqand', NULL, 'Samarqand', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 391 91 66');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'AZIZBEK', '+998 99 518 11 26', NULL, 'Uzbekistan', NULL, NULL, 'BESHKAPA', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 518 11 26');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'jasur', '+998 97 060 81 31', NULL, 'Uzbekistan', 'Andijon', NULL, 'andijon shaxrixon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 060 81 31');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Lutfullo', '+998 90 277 78 55', NULL, 'Uzbekistan', NULL, NULL, 'Qo''shtepa tuman', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 277 78 55');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ABDUPATTO', '+998 95 859 80 99', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON BALIQCHI', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 859 80 99');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'SHOXRUX', '+998 33 989 30 30', NULL, 'Uzbekistan', 'Andijon', NULL, 'ANDIJON OLTINKUL', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 33 989 30 30');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Mirzoxid', '+998 91 143 87 57', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon Marxamat', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 143 87 57');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ZIYADILLA XAYDAROV', '+998 90 163 83 83', NULL, 'Uzbekistan', NULL, NULL, 'FARGONA TOSHLOQ', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 163 83 83');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Muhammadjon', '+998 91 652 60 66', NULL, 'Uzbekistan', 'Farg''ona', NULL, 'Farg''ona', 'import', 'Eski bazadan import — 2 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 652 60 66');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Mustafa', '+998 88 573 20 20', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 573 20 20');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'JAVOXIR', '+998 93 129 80 08', NULL, 'Uzbekistan', 'Samarqand', NULL, 'Samarqand', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 129 80 08');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Lazizbek', '+998 99 627 73 77', NULL, 'Uzbekistan', 'Samarqand', NULL, 'Samarqand', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 627 73 77');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ARSLON', '+998 90 737 37 00', NULL, 'Uzbekistan', 'Xorazm', NULL, 'Xorazm', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 737 37 00');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ARSLON', '+998 93 201 00 33', NULL, 'Uzbekistan', 'Xorazm', NULL, 'Xorazm', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 201 00 33');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Pirimqul', '+992 900889168', NULL, 'Tajikistan', NULL, NULL, 'Tojikiston', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+992 900889168');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'BUNYOD', '+998 93 046 72 22', NULL, 'Uzbekistan', 'Farg''ona', NULL, 'Farg''ona', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 046 72 22');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Ibrohim', '+998 94 278 88 18', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 278 88 18');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Bobur', '+998 33 150 50 52', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 33 150 50 52');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Sohibjon', '+998 94 303 78 05', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 303 78 05');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'nuriddin', '+998 90 155 07 11', NULL, 'Uzbekistan', 'Farg''ona', NULL, 'Farg''ona', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 155 07 11');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Masjidga', '+998 33 212 07 17', NULL, 'Uzbekistan', 'Jizzax', NULL, 'Jizzax', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 33 212 07 17');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'xamidjon', '+998 94 010 76 98', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 010 76 98');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'qaaxramon', '+998 97 661 41 14', NULL, 'Uzbekistan', 'Farg''ona', NULL, 'Farg''ona', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 661 41 14');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'abdullox', '+998 93 816 10 10', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 816 10 10');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'nodirbek', '+998 93 789 10 02', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 789 10 02');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'alijon', '+998 91 680 34 03', NULL, 'Uzbekistan', 'Farg''ona', NULL, 'Farg''ona', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 680 34 03');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'baxtiyor', '+998 97 395 31 11', NULL, 'Uzbekistan', 'Samarqand', NULL, 'Samarqand', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 395 31 11');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Ayubxon', '+998 77 577 00 62', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 77 577 00 62');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Marat', '+998 93 368 38 63', NULL, 'Uzbekistan', 'Qoraqalpog''iston', NULL, 'Qoraqalpog''iston', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 368 38 63');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Hakimov Bahrom', '+998 93 799 81 20', NULL, 'Uzbekistan', 'Surxondaryo', NULL, 'Surxondaryo', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 799 81 20');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Mansurbek', '+998 90 571 11 14', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 571 11 14');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Sayfiddin', '+998 93 645 00 20', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 645 00 20');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ilhom', '+998 70 051 78 77', NULL, 'Uzbekistan', 'Xorazm', NULL, 'Xorazm', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 70 051 78 77');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'xabibullo', '+998 94 496 17 34', NULL, 'Uzbekistan', 'Farg''ona', NULL, 'Farg''ona', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 496 17 34');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Begzodjon', '+998 91 149 50 17', NULL, 'Uzbekistan', 'Farg''ona', NULL, 'Farg''ona', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 149 50 17');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'botirjon', '+998 91 647 59 36', NULL, 'Uzbekistan', 'Buxoro', NULL, 'Buxoro', 'import', 'Eski bazadan import — 5 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 647 59 36');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'mirshod', '+998 95 480 55 65', NULL, 'Uzbekistan', 'Buxoro', NULL, 'Buxoro', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 480 55 65');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ERGASHALI', '+998 94 947 77 11', NULL, 'Uzbekistan', 'Farg''ona', NULL, 'Farg''ona', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 947 77 11');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'sardorbek', '+998 50 599 84 48', NULL, 'Uzbekistan', 'Qoraqalpog''iston', NULL, 'Qoraqalpog''iston', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 50 599 84 48');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Zoyirjon Soliyev', '+998 90 360 00 53', NULL, 'Uzbekistan', 'Farg''ona', NULL, 'Farg''ona', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 360 00 53');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ilxom', '+998 99 416 70 70', NULL, 'Uzbekistan', 'Surxondaryo', NULL, 'Surxondaryo', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 416 70 70');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'azamjon', '+998 93 219 94 26', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 219 94 26');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'IQBOLJON', '+998 91 282 08 43', NULL, 'Uzbekistan', 'Farg''ona', NULL, 'Farg''ona', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 282 08 43');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'oybek', '+998 93 730 67 76', NULL, 'Uzbekistan', NULL, NULL, 'Qirg''iziston', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 730 67 76');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'azimjon', '+998 97 030 07 69', NULL, 'Uzbekistan', 'Samarqand', NULL, 'Samarqand', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 030 07 69');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'anvar', '+998 99 157 34 34', NULL, 'Uzbekistan', 'Samarqand', NULL, 'Samarqand', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 157 34 34');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'anvar mirzo', '+998 95 665 01 01', NULL, 'Uzbekistan', 'Farg''ona', NULL, 'Farg''ona', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 665 01 01');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'abdusalom', '+998 90 221 27 62', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 221 27 62');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'saidmuxammad', '+998 91 147 51 40', NULL, 'Uzbekistan', 'Farg''ona', NULL, 'Farg''ona', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 147 51 40');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Ilyosjon', '+992 171455504', NULL, 'Tajikistan', NULL, NULL, 'Tojikiston', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+992 171455504');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Izatillo', '+998 99 864 90 24', NULL, 'Uzbekistan', 'Farg''ona', NULL, 'Farg''ona', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 864 90 24');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Alisherjon', '+998 90 549 80 37', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 549 80 37');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Olimjon', '+998 91 045 09 73', NULL, 'Uzbekistan', 'Farg''ona', NULL, 'Farg''ona', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 045 09 73');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'akramjon', '+998 91 118 43 21', NULL, 'Uzbekistan', 'Farg''ona', NULL, 'Farg''ona', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 118 43 21');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'rahmonjon', '+998 97 990 07 60', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 990 07 60');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'umid', '+998 90 552 06 07', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 552 06 07');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Dostonbek', '+998 94 407 00 23', NULL, 'Uzbekistan', 'Farg''ona', NULL, 'Farg''ona', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 407 00 23');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'sobirjon', '+998 93 482 35 00', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 482 35 00');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Rahmatillo', '+998 94 307 44 77', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 307 44 77');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'ilxomjon', '+998 93 405 51 45', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 405 51 45');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'muzaffar', '+998 77 105 37 77', NULL, 'Uzbekistan', 'Samarqand', NULL, 'Samarqand', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 77 105 37 77');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'obidxon', '+998 99 442 72 72', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan', 'import', 'Eski bazadan import — 4 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 442 72 72');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Izatillo', '+998 91 143 73 78', NULL, 'Uzbekistan', 'Farg''ona', NULL, 'Farg''ona', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 143 73 78');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'raxmatillo', '+998 94 730 71 77', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 730 71 77');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'nabijon', '+998 99 395 19 63', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 395 19 63');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'o`tkirbek', '+998 91 652 46 36', NULL, 'Uzbekistan', 'Farg''ona', NULL, 'Farg''ona', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 652 46 36');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Ruzali', '+998 88 704 05 55', NULL, 'Uzbekistan', 'Farg''ona', NULL, 'Farg''ona', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 704 05 55');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'erkinjon', '+998 94 978 54 04', NULL, 'Uzbekistan', 'Farg''ona', NULL, 'Farg''ona', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 978 54 04');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Rahmatulloh', '+998 90 278 25 75', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 278 25 75');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'xatambek', '+998 94 252 40 31', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 252 40 31');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'alisher', '+998 99 162 50 50', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 162 50 50');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'BAHODIRJON', '+998 97 050 06 87', NULL, 'Uzbekistan', 'Farg''ona', NULL, 'Farg''ona', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 050 06 87');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Umidjon', '+998 93 705 88 95', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 93 705 88 95');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Abduxamit', '+998 91 151 11 88', NULL, 'Uzbekistan', 'Farg''ona', NULL, 'Farg''ona', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 151 11 88');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'RAHMATTILO', '+998 77 253 70 66', NULL, 'Uzbekistan', 'Farg''ona', NULL, 'Farg''ona', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 77 253 70 66');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Ismai;on Ildar', '+996 702932596', NULL, 'Kyrgyzstan', NULL, NULL, 'Qirg''iziston', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+996 702932596');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'GIYOSJON', '+998 88 308 69 96', NULL, 'Uzbekistan', 'Samarqand', NULL, 'Samarqand', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 88 308 69 96');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'boburjon', '+998 97 346 44 43', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 346 44 43');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'zafar', '+992 909093632', NULL, 'Tajikistan', NULL, NULL, 'Tojikiston', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+992 909093632');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'rovshan', '+998 97 595 39 83', NULL, 'Uzbekistan', 'Farg''ona', NULL, 'Farg''ona', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 595 39 83');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'alisher', '+998 91 109 38 91', NULL, 'Uzbekistan', 'Farg''ona', NULL, 'Farg''ona', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 91 109 38 91');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'sobitxon', '+998 94 203 15 15', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 203 15 15');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Shodiev Asqar', '+998 99 196 40 60', NULL, 'Uzbekistan', 'Buxoro', NULL, 'Buxoro', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 99 196 40 60');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'yusufxon', '+998 97 271 66 54', NULL, 'Uzbekistan', 'Farg''ona', NULL, 'Farg''ona', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 97 271 66 54');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'Sardorjon Hoji', '+998 90 292 21 71', NULL, 'Uzbekistan', 'Farg''ona', NULL, 'Farg''ona', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 90 292 21 71');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'mansurxon', '+998 95 640 06 15', NULL, 'Uzbekistan', 'Andijon', NULL, 'Andijon', 'import', 'Eski bazadan import — 1 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 95 640 06 15');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'AZIZBEK USTA', '+998 94 179 43 77', NULL, 'Uzbekistan', 'Namangan', NULL, 'Namangan', 'import', 'Eski bazadan import — 2 ta buyurtma'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='+998 94 179 43 77');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'abdurahim usta', 'NOPHONE-2507-137', NULL, 'Uzbekistan', 'Andijon', NULL, 'andijon', 'import', 'DIQQAT: telefon yo''q/noto''g''ri — qo''lda to''ldirilsin. Asl: abdurahim 47 44'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='NOPHONE-2507-137');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'OTABEK TUNKA', 'NOPHONE-2511-46', NULL, 'Uzbekistan', NULL, NULL, 'QOQON', 'import', 'DIQQAT: telefon yo''q/noto''g''ri — qo''lda to''ldirilsin. Asl: —'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='NOPHONE-2511-46');
INSERT INTO customers (id, full_name, phone, phone2, country, region, city, address, source, note)
SELECT gen_random_uuid(), 'murodxon', 'NOPHONE-2605-15', NULL, 'Uzbekistan', 'Farg''ona', NULL, 'Farg''ona', 'import', 'DIQQAT: telefon yo''q/noto''g''ri — qo''lda to''ldirilsin. Asl: 0'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone='NOPHONE-2605-15');

SELECT count(*) AS import_mijoz_jami FROM customers WHERE source='import';
COMMIT;