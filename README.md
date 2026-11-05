# Rampa Güvenlik Olayları: BLP 105 Vize (Kura #33)

Çağan Ege Akışık · 202507130050 · Doğuş Üniversitesi MYO, Robotik ve Yapay Zekâ

Kargo merkezi rampalarındaki kamera tespitlerinden (forklift ve yaya) güvenlik olayı tablosu üretip PostgreSQL'de analiz eden dönem projesinin Hafta 3-5 çıktısı.

## İçerik

| Dosya | Hafta | Ne |
|---|---|---|
| `SCENARIO.md` | 3 | Problem, kullanıcı, tablo adayları, olay kuralı, YZ bileşeni |
| `data/raw/` | 4 | Ham veri (hiç değiştirilmez) |
| `data/README.md` | 4 | Veri kartı |
| `scripts/` | 4 | Ham veriden olay tablosu üretme ve temizleme |
| `sql/hafta-04.sql` | 4 | Yükleme ve ilk SELECT / WHERE sorguları |
| `sql/hafta-05.sql` | 5 | Beş analiz sorgusu (GROUP BY, NULL, HAVING, CASE WHEN, tarih) |
| `AI_BEYAN.md` | - | Yapay zekâ kullanım beyanı |

## Çalıştırma

```
createdb dock_safety
python3 scripts/build_events.py
python3 scripts/clean_events.py
psql -d dock_safety -f sql/hafta-04.sql
psql -d dock_safety -f sql/hafta-05.sql
```

## Veri lisansı

Anotasyonlar: Mohamed Traore, "Forklift Dataset", Roboflow Universe (2022), Hugging Face'te keremberke/forklift-object-detection, CC BY 4.0.
