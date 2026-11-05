# Yapay Zekâ Kullanım Beyanı

**Öğrenci:** Çağan Ege Akışık · 202507130050
**Kullandım:** Evet

## Kullanılan araç

| Araç | Sağlayıcı | Ne zaman |
|---|---|---|
| Claude | Anthropic | 5 Kasım 2026 |

GitHub web arayüzünün önerdiği Copilot commit mesajları kullanılmadı; commit mesajlarını ben yazdım.

## Ne için kullandım

| Dosya | YZ ne yaptı | Benim payım / nasıl doğruladım |
|---|---|---|
| Veri bulma | Senaryoya uyan gerçek veri setini (Hugging Face forklift anotasyonları) buldu ve ham dosyayı indirdi | Lisansın CC BY 4.0 olduğunu veri seti sayfasından kontrol ettim |
| `scripts/build_events.py` | Kutulardan olay türü ve şiddet çıkaran kuralı ve rampa/zaman simülasyonunu yazdı | Kuralı okudum; birkaç görüntünün koordinatlarını elle hesaplayıp sonuçla karşılaştırdım |
| `scripts/clean_events.py` | Rampa kodu düzeltme ve vardiya atama betiğini yazdı | Temiz dosyada 6 farklı rampa kodu ve 3 vardiya olduğunu sorguyla kontrol ettim |
| `SCENARIO.md`, `data/README.md` | Taslağı yazdı | Senaryo belgesindeki Kura #33 metniyle karşılaştırdım |
| `sql/hafta-04.sql`, `sql/hafta-05.sql` | Sorguları ve yorum paragraflarını yazdı | Dosyaları kendi PostgreSQL'imde çalıştırıp her sorgunun sonucunu yorumdaki sayıyla karşılaştırdım |
| Rapor | Taslağı yazdı | Kendi cümlelerimle düzelttim |

## YZ'nin bulduğu ve düzelttiği hata

İlk sürümde forkliftin içindeki her insan "temas" olayı sayıldı (309 olay). Kutulara bakılınca bunların çoğunun forklifti süren operatör olduğu anlaşıldı. Operatör ayrı bir tür yapıldı, gerçek temas sayısı 28'e indi.

## Sınırlılık beyanı

Rampa ve zaman bilgisi kaynak veride olmadığı için simülasyonla atandı. Bunu SCENARIO.md, veri kartı, sorgu yorumları ve raporda açıkça yazdım. Rampa, vardiya ve saat sonuçlarını bulgu olarak sunmuyorum.
