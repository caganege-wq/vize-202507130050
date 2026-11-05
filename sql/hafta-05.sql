-- Hafta 5: GROUP BY, NULL, CASE WHEN, tarih fonksiyonları
-- Senaryo: Kura #33, kargo merkezi rampa kameraları ve güvenlik olayları
-- Önce:  psql -d dock_safety -f sql/hafta-04.sql   (tabloları yükler)
-- Sonra: psql -d dock_safety -f sql/hafta-05.sql
--
-- ÖNEMLİ: Olay türü ve şiddet gerçek kamera anotasyonlarından hesaplandı.
-- Rampa (dock_code) ve zaman (event_at, dolayısıyla shift_name) kaynakta
-- yoktu; scripts/build_events.py bunları EŞİT OLASILIKLA atadı (simülasyon).
-- Bu yüzden rampa, vardiya ve saat karşılaştırmalarındaki farklar bir bulgu
-- değil, rastgele dalgalanmadır. Bu sorgular, gerçek kamera kaydı geldiğinde
-- aynen çalışacak analizin hazırlığıdır.

SET timezone = 'Europe/Istanbul';


-- Sorgu 1 (GROUP BY, ROUND): Rampa bazında olay sayısı ve ortalama şiddet.
-- Ne soruyor: Hangi rampada kaç olay var ve olaylar ortalama ne kadar ciddi?
-- Beklenen: Rampa simülasyonla eşit dağıtıldığı için her rampada yaklaşık
-- 873 / 6 = 145 olay ve birbirine yakın ortalamalar.
-- Sonuç: 112 (R-06) ile 170 (R-05) arasında olay, ortalama şiddet 1.36-1.56.
-- Anlamı: Fark rastgele; aynı karedeki tüm tespitler aynı rampaya düştüğü
-- için kalabalık bir kare bir rampanın sayısını tek başına artırabiliyor.
-- Ortalamalar düşük çünkü olayların çoğu forklift hareketi ve operatör
-- kaydı (şiddet 1). avg() şiddeti boş olan 18 olayı hesaba katmıyor; o
-- yüzden "siddetli" sütunu da ayrıca gösteriliyor.
SELECT dock_code,
       count(*)                      AS olay_sayisi,
       count(severity_1_5)           AS siddeti_bilinen,
       round(avg(severity_1_5), 2)   AS ort_siddet
FROM events
GROUP BY dock_code
ORDER BY dock_code;


-- Sorgu 2 (COUNT(*) ile COUNT(severity_1_5) farkı): Şiddeti boş olan
-- olayların sayısı ve olay türüne göre dağılımı.
-- Ne soruyor: Kaç olayda kamera şiddet belirleyemedi ve bunlar hangi tür?
-- Beklenen: Az sayıda; sadece insan tespitlerinde, çünkü kural küçük insan
-- kutularında (400 piksel kareden küçük) şiddeti boş bırakıyor.
-- Sonuç: 873 olayın 855'inde şiddet var, 18'inde yok. Boşların 13'ü
-- forklift_operatoru, 5'i yaya_forklift_alaninda. Forklift tespitlerinde
-- hiç boş yok.
-- Anlamı: Boş şiddet "sıfır" değil, "bilinmiyor" demek. Bu 18 olayı 0 ya da
-- 1 kabul etseydik ortalama şiddet yapay olarak düşerdi. 5 yaya olayı
-- önemli: yaya forkliftin yanında ama kişi çok uzakta olduğu için ne kadar
-- tehlikeli olduğu bilinmiyor; bunlar insan incelemesine gitmeli.
SELECT count(*)                         AS toplam,
       count(severity_1_5)              AS siddet_dolu,
       count(*) - count(severity_1_5)   AS siddet_bos
FROM events;

SELECT event_type,
       count(*) AS siddet_bos
FROM events
WHERE severity_1_5 IS NULL
GROUP BY event_type
ORDER BY siddet_bos DESC;


-- Sorgu 3 (HAVING): Her vardiyada en az 25 olayı olan rampalar.
-- Ne soruyor: Hangi rampa-vardiya ikilisi "yoğun" sayılacak kadar olay
-- üretiyor?
-- Beklenen: 6 rampa x 3 vardiya = 18 ikili; ortalama 48 olay olduğu için
-- çoğu eşiği geçer.
-- Sonuç: 18 ikiliden 17'si geçti. Eşiğin altında kalan tek ikili Gece /
-- R-06 (20 olay). En yüksek Akşam / R-05 (73).
-- Anlamı: Gece vardiyası gece yarısını aştığı için saat 22, 23 ve 0-5
-- birlikte "Gece" sayıldı (clean_events.py). Gerçek veride bu sorgu
-- amirin hangi rampa-vardiya ikilisine öncelik vermesi gerektiğini
-- gösterir; burada sadece yöntemin çalıştığını gösteriyor.
SELECT shift_name,
       dock_code,
       count(*) AS olay_sayisi
FROM events
GROUP BY shift_name, dock_code
HAVING count(*) >= 25
ORDER BY shift_name, olay_sayisi DESC;


-- Sorgu 4 (CASE WHEN): Şiddeti low / medium / high yapan sınıflandırma ve
-- olay türüne göre dağılım.
-- Ne soruyor: Olayların ne kadarı gerçekten ciddi ve ciddi olanlar hangi
-- türden?
-- Eşikler: 1-2 low, 3 medium, 4-5 high. NULL için ayrı "unknown" dalı
-- var ve EN BAŞTA: olmasaydı NULL'lar ELSE dalına düşüp "high" olurdu.
-- Beklenen: Çoğu low; high sadece yayanın forkliftle temas ettiği kareler.
-- Sonuç: low 740, medium 87, high 28, unknown 18. High'ın tamamı
-- (28) yaya_forklift_temas; medium'un tamamı yaya_forklift_alaninda.
-- Anlamı: Bu sorgu, şiddet ve olay türü sütunlarının gerçek kutulardan
-- tutarlı hesaplandığını da doğruluyor. Bu bölüm simülasyondan
-- ETKİLENMEZ; olayların yalnızca %3'ü (28/873) yüksek şiddetli.
SELECT event_type,
       CASE
           WHEN severity_1_5 IS NULL THEN 'unknown'
           WHEN severity_1_5 <= 2    THEN 'low'
           WHEN severity_1_5 = 3     THEN 'medium'
           ELSE                           'high'
       END AS siddet_seviyesi,
       count(*) AS olay_sayisi
FROM events
GROUP BY event_type, siddet_seviyesi
ORDER BY event_type, siddet_seviyesi;


-- Sorgu 5a (EXTRACT(HOUR ...)): Olay saatine göre yoğunluk.
-- Ne soruyor: Olaylar günün belirli saatlerinde toplanıyor mu?
-- Beklenen: Zaman eşit dağıtıldığı için saat başına yaklaşık 873 / 24 = 36.
-- Sonuç: En yoğun saat 14 (56 olay), en sakin 4 ve 16 (23 olay).
-- Anlamı: 23-56 arası fark rastgele. Ana sorunun ikinci yarısı ("yoğun iş
-- saatleriyle ilişkili mi?") bu veriyle CEVAPLANAMAZ, çünkü saatleri biz
-- atadık. Gerçek bir kamera kaydında bu sorgu aynen kullanılabilir.
SELECT EXTRACT(HOUR FROM event_at) AS saat,
       count(*)                    AS olay_sayisi
FROM events
GROUP BY saat
ORDER BY saat;


-- Sorgu 5b (date_trunc('week', ...)): Haftalık toplam ve yüksek şiddetli
-- olay sayısı.
-- Ne soruyor: Olay sayısı haftadan haftaya değişiyor mu?
-- Beklenen: 4 hafta, her biri yaklaşık 218 olay.
-- Sonuç: 205, 219, 219, 230 olay; yüksek şiddetli (4-5) olaylar 6, 10,
-- 2, 10.
-- Anlamı: Toplam sabit. Yüksek şiddetli olay sayısı daha çok oynuyor,
-- çünkü toplamı küçük (28): birkaç kalabalık kare bir haftayı tek başına
-- değiştiriyor. Küçük sayılardaki haftalık değişimi trend sanmamak gerek.
SELECT date_trunc('week', event_at)::date        AS hafta_baslangici,
       count(*)                                  AS olay_sayisi,
       count(*) FILTER (WHERE severity_1_5 >= 4) AS yuksek_siddet
FROM events
GROUP BY hafta_baslangici
ORDER BY hafta_baslangici;
