# Veri Kartı

## Kaynak

| Alan | Değer |
|---|---|
| Veri seti | keremberke/forklift-object-detection |
| Adres | https://huggingface.co/datasets/keremberke/forklift-object-detection |
| Asıl kaynak | Roboflow Universe, "Forklift Dataset", Mohamed Traore (2022): https://universe.roboflow.com/mohamed-traore-2ekkp/forklift-dsitv |
| Lisans | CC BY 4.0 (atıf vererek kullanım serbest) |
| İndirme yolu | Hugging Face datasets-server API (`/rows`, config `full`, train + validation + test) |
| İndirme tarihi | 5 Kasım 2026, 19:17 (İstanbul) |
| Ham dosya | `raw/forklift_hf_rows_raw.json`, SHA-256 `40c05acf7092c398ceaade07976a1f7595745fe4cf5e4b4a8f6bb697c7f080c7` |

Ham dosya API yanıtının kendisidir. İndirme sırasında yalnızca `image` alanı (görüntünün geçici indirme linki) çıkarıldı; görüntüler bu projede kullanılmıyor. Ham dosya bundan sonra hiç değiştirilmedi.

## Boyut

| Dosya | Satır | Sütun | Ne |
|---|---|---|---|
| `raw/forklift_hf_rows_raw.json` | 421 görüntü, 873 tespit | - | Gerçek anotasyonlar |
| `derived/events.csv` | 873 | 15 | Ham dosyadan betikle üretilen olay tablosu (temizlenmemiş) |
| `clean/events_clean.csv` | 873 | 15 | Temizlenmiş olay tablosu |
| `docks.csv` | 6 | 3 | Rampa listesi (senaryo gereği tanımlandı) |
| `shifts.csv` | 3 | 4 | Vardiya listesi (senaryo gereği tanımlandı) |

**Sayısal sütunlar (en az 4):** severity_1_5, area_px, bbox_w, bbox_h, image_w, image_h
**Tarih/zaman sütunu:** event_at

## Hangi sütun gerçek, hangisi üretildi

| Sütun | Kaynak |
|---|---|
| detected_class, bbox_x, bbox_y, bbox_w, bbox_h, area_px, image_w, image_h, source_* | **Gerçek** (anotasyondan aynen) |
| event_type, severity_1_5 | **Gerçek veriden hesaplandı** (kural `../SCENARIO.md` içinde) |
| dock_code, event_at, shift_name | **Simülasyon**: kaynakta yok, `scripts/build_events.py` eşit olasılıkla atadı (tohum 202507130050) |

873 satırın tamamı gerçek bir tespitten geliyor; uydurulmuş satır yok. Dil modeliyle üretilmiş satır yok. Rampa ve zaman sütunları ise her satırda üretilmiş; bu yüzden rampa, vardiya ve saat analizleri bulgu olarak yorumlanmamalı.

## Beklenen sorunlar ve temizleme adımları

`scripts/clean_events.py`, `derived/events.csv` dosyasını okuyup `clean/events_clean.csv` dosyasını yazar:

1. **Rampa kodu iki biçimde.** R-01..R-03 "R-01" biçiminde, R-04..R-06 eski kamera yazılımı biçiminde "r4". Hepsi "R-04" biçimine çevrildi. (Sorun simülasyonun parçası: senaryonun öngördüğü durumu temsil ediyor.)
2. **Gece vardiyası gece yarısını aşıyor.** Bitiş (06:00) başlangıçtan (22:00) küçük. Vardiya, olay saatine göre atandı: saat 22 ve üstü VEYA 6'dan küçükse "Gece".
3. **Şiddeti boş olaylar (18 satır).** İnsan kutusu 400 piksel kareden küçükse şiddet belirlenemiyor. Bu satırlar silinmedi, 0 da yazılmadı; NULL bırakıldı.
4. **Kalıcı kimlik.** Her satıra 1'den başlayan `event_id` verildi.

Temizlik satır silmedi: ham ve temiz tabloda 873 satır var.

## Yeniden üretme

```
python3 scripts/build_events.py      # raw  -> derived/events.csv
python3 scripts/clean_events.py      # derived -> clean/events_clean.csv
psql -d dock_safety -f sql/hafta-04.sql
psql -d dock_safety -f sql/hafta-05.sql
```

Aynı ham dosya ve aynı tohumla herkes aynı CSV'leri elde eder.
