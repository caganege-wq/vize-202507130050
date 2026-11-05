-- Hafta 4: Veriyi PostgreSQL'e yükleme ve ilk SELECT / WHERE sorguları
-- Senaryo: Kura #33, Lojistik ve teslimat × Görüntü işleyen kamera × Güvenlik ve olay takibi
-- Çalıştırma (repo kök klasöründen):  psql -d dock_safety -f sql/hafta-04.sql

SET timezone = 'Europe/Istanbul';

-- -------------------------------------------------------------------------
-- Yükleme
-- Not: Tablo oluşturma (DDL) Hafta 9 konusu. Burada sadece CSV'yi okuyabilmek
-- için en basit iki tablo açılıyor: biri temizlenmemiş (events_raw), biri
-- temizlenmiş (events). Şema tasarımı vize kapsamında değil.
-- -------------------------------------------------------------------------
DROP TABLE IF EXISTS events_raw;
CREATE TABLE events_raw (
    source_split     text,
    source_image_id  integer,
    source_object_id integer,
    detected_class   text,
    bbox_x           integer,
    bbox_y           integer,
    bbox_w           integer,
    bbox_h           integer,
    area_px          integer,
    image_w          integer,
    image_h          integer,
    event_type       text,
    severity_1_5     integer,
    dock_code        text,
    event_at         timestamptz
);
\copy events_raw FROM 'data/derived/events.csv' WITH (FORMAT csv, HEADER true)

DROP TABLE IF EXISTS events;
CREATE TABLE events (
    event_id         integer,
    dock_code        text,
    shift_name       text,
    event_type       text,
    severity_1_5     integer,
    event_at         timestamptz,
    detected_class   text,
    area_px          integer,
    bbox_w           integer,
    bbox_h           integer,
    image_w          integer,
    image_h          integer,
    source_image_id  integer,
    source_object_id integer,
    source_split     text
);
\copy events FROM 'data/clean/events_clean.csv' WITH (FORMAT csv, HEADER true)


-- 4.1 Kaç satır yüklendi? İki tablo da aynı sayıda satır içermeli.
-- Beklenen: 873 ve 873. Temizlik satır silmedi, sadece biçim düzeltti.
SELECT count(*) AS ham_satir FROM events_raw;
SELECT count(*) AS temiz_satir FROM events;


-- 4.2 İlk bakış: ilk 10 olay, zaman sırasıyla.
-- Amaç verinin doğru okunduğunu görmek: tarih sütunu gerçekten tarih mi,
-- sayılar sayı mı?
SELECT event_id, dock_code, shift_name, event_type, severity_1_5, event_at
FROM events
ORDER BY event_at
LIMIT 10;


-- 4.3 Beklenen sorun 1: rampa kodu iki farklı biçimde yazılmış.
-- Ham tabloda "R-01" ile "r4" gibi iki yazım bir arada. Eski kamera yazılımı
-- R-04, R-05 ve R-06'yı "r4", "r5", "r6" diye kaydediyor.
-- Beklenen: 6 farklı yazım (3'ü yeni, 3'ü eski biçimde).
SELECT DISTINCT dock_code
FROM events_raw
ORDER BY dock_code;

-- Temiz tabloda hepsi aynı biçimde olmalı. Beklenen: R-01 ... R-06.
SELECT DISTINCT dock_code
FROM events
ORDER BY dock_code;


-- 4.4 Beklenen sorun 2: şiddeti boş olan olaylar.
-- Kamera kutusu 400 piksel kareden küçük insanlarda şiddet belirlenemiyor
-- (kişi çok uzakta). Bu satırlar silinmedi, şiddet NULL bırakıldı.
SELECT event_id, event_type, area_px, severity_1_5
FROM events
WHERE severity_1_5 IS NULL
ORDER BY area_px;


-- 4.5 Beklenen sorun 3: gece vardiyası gece yarısını aşıyor.
-- Gece vardiyası 22:00'de başlıyor, 06:00'da bitiyor; bitiş başlangıçtan
-- küçük. Saat 01:15'teki bir olay "Gece" vardiyasına aittir, ertesi günün
-- sabahına değil. Kontrol: Gece vardiyası olaylarının saatleri 22, 23 ve
-- 0-5 arasında olmalı, başka saat görünmemeli.
SELECT DISTINCT EXTRACT(HOUR FROM event_at) AS saat
FROM events
WHERE shift_name = 'Gece'
ORDER BY saat;


-- 4.6 En yüksek şiddetli olaylar (5): yayanın forkliftin üstüne
-- yarıdan fazla bindiği kareler. Beklenen: az sayıda satır.
SELECT event_id, dock_code, shift_name, event_type, event_at
FROM events
WHERE severity_1_5 = 5
ORDER BY event_at;


-- 4.7 Kuzey bölgedeki rampalarda (R-01..R-03), gece vardiyasında,
-- şiddeti 3 ve üstü olan olaylar.
SELECT event_id, dock_code, event_type, severity_1_5, event_at
FROM events
WHERE dock_code IN ('R-01', 'R-02', 'R-03')
  AND shift_name = 'Gece'
  AND severity_1_5 >= 3
ORDER BY severity_1_5 DESC, event_at;
