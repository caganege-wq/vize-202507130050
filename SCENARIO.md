# Senaryo Kartı: Kura #33

**Öğrenci:** Çağan Ege Akışık · 202507130050 · BLP 105 Robotik ve Yapay Zekâ
**Kura:** Lojistik ve teslimat × Görüntü işleyen kamera × Güvenlik ve olay takibi

## Problem

Bir kargo merkezinde kamyonların yanaştığı boşaltma rampalarını kameralar izliyor. Rampa, forkliftlerle yayaların aynı alanı paylaştığı bir yer; en ciddi kaza türü forkliftin bir yayaya çarpması. Kamera görüntüsündeki forklift ve insanları tespit edip bunları olay olarak kaydeden bir sistem var. Vardiya amiri, olayların hangi rampada ve hangi vardiyada toplandığını görmek istiyor.

## Ana soru

Güvenlik olayları rampa ve vardiya kombinasyonuna göre nasıl dağılıyor ve bu dağılım yoğun iş saatleriyle ilişkili mi?

## Hedef kullanıcı

- **Vardiya amiri:** hangi rampaya ek gözetmen koyacağına karar verir.
- **İş güvenliği uzmanı:** yüksek şiddetli olayları inceler.

## Tablo adayları

| Tablo | Sütunlar | Not |
|---|---|---|
| `docks` | id, dock_code, warehouse_zone | 6 rampa, Kuzey ve Güney bölge (`data/docks.csv`) |
| `shifts` | id, name, start_time, end_time | Sabah 06-14, Akşam 14-22, Gece 22-06 (`data/shifts.csv`) |
| `events` | id, dock_id, shift_id, event_type, severity_1_5, event_at | Kamera olayları (`data/clean/events_clean.csv`) |

Vizede tablolar arası bağlantı (JOIN, Hafta 6) ve şema tasarımı (ERD, Hafta 7) yok. Bu yüzden `events` tablosunda rampa kodu ve vardiya adı şimdilik doğrudan metin olarak tutuluyor. Dönem sonunda `dock_id` ve `shift_id` yabancı anahtarlarına dönüşecek.

## Veri kaynağı

Gerçek kaynak: Hugging Face'teki **keremberke/forklift-object-detection** veri seti (Roboflow Universe, Mohamed Traore, CC BY 4.0). 421 gerçek depo/rampa görüntüsünde insan ve forklift için çizilmiş 873 tespit kutusu var. Ayrıntılar `data/README.md` dosyasında.

Senaryo belgesinin önerdiği "COCO üzerinden insan ve forklift etiketli görüntülerin anotasyonlarından olay kayıtlarına dönüştürme" yöntemi kullanıldı; bu veri seti de COCO biçiminde etiketlenmiş.

## Olay kuralı (kamera tespiti → güvenlik olayı)

Her tespit kutusu bir olay satırı oluyor. Olay türü ve şiddet yalnızca gerçek kutu koordinatlarından hesaplanıyor (`scripts/build_events.py`):

| Olay türü | Kural | Şiddet |
|---|---|---|
| `yaya_forklift_temas` | İnsan kutusunun %25-90'ı bir forklift kutusunun içinde | 4; %50 ve üstü ise 5 |
| `yaya_forklift_alaninda` | Karede forklift var, insan onunla temas etmiyor | 3 |
| `rampada_yaya` | Karede insan var, forklift yok | 2 |
| `forklift_yaya_yaninda` | Forklift tespiti, karede operatör dışında bir insan var | 2 |
| `forklift_operatoru` | İnsan kutusunun %90'dan fazlası forkliftin içinde: büyük ihtimalle sürücü | 1 |
| `forklift_hareketi` | Forklift tespiti, karede yaya yok | 1 |

- **Şiddet NULL:** İnsan kutusu 400 piksel kareden küçükse kişi çok uzakta, şiddet belirlenemiyor ve boş bırakılıyor.
- **Neden operatör ayrı:** İlk denemede forkliftin içindeki herkesi "temas" saymıştım ve 309 temas olayı çıktı. Kutulara bakınca bunların çoğunun forklifti süren kişi olduğunu gördüm. Operatörü ayırınca gerçek temas sayısı 28'e indi. Bu ayrım, dönem sonundaki "yanlış alarm" konusunun ilk örneği.
- **Kapsam dışı:** Senaryodaki "yanlış yönde forklift" ve "kapı açık kaldı" olayları tek bir fotoğraftan çıkarılamıyor; bunlar için video ya da kapı sensörü gerekir. Vizede bu türler yok.

## Kişi değil, olay

Kamerada görülen kişi çalışan da olabilir, ziyaretçi de. Analizde kişi değil, olay sayılıyor. Veri setinde kimlik, yüz ya da plaka bilgisi yok; kimlik çıkarımı ve bireysel izleme bu projenin kapsamı dışında.

## Sınırlılık: rampa ve zaman simülasyon

Kaynak veri setinde görüntünün hangi rampada ve ne zaman çekildiği yok. Bu iki bilgi `scripts/build_events.py` tarafından sabit bir tohumla (öğrenci no) **eşit olasılıkla** atandı; aynı karedeki tespitler aynı rampa ve zamanı paylaşıyor. Bu yüzden:

- Olay türü ve şiddet sonuçları gerçek veriye dayanıyor.
- Rampa, vardiya ve saat karşılaştırmaları bir bulgu değil. Sorgular, gerçek kamera kaydı geldiğinde aynen çalışacak biçimde hazırlandı.
- Ana sorunun "yoğun iş saatleriyle ilişkili mi?" kısmı bu veriyle cevaplanamıyor. Bunu sonuç raporunda açıkça yazıyorum.

## YZ bileşeni (dönem sonu)

Kameranın ürettiği olay etiketini insan incelemesiyle karşılaştıran bir kayıt yapısı: her olay için `camera_label`, `reviewer_label`, `reviewed_at`. Bununla yanlış alarm oranı (ör. operatörü yaya sanma) rampa ve olay türüne göre izlenecek.

## Kalan haftalar için plan

- Hafta 6: `events` ile `docks` / `shifts` arasında JOIN.
- Hafta 7: ERD; `events.dock_id` ve `events.shift_id` ilişkileri.
- Hafta 9: DDL; metin sütunlarını yabancı anahtara çevirme, `severity_1_5` için CHECK (1-5).
- Hafta 11: İnsan inceleme tablosu ve yanlış alarm oranı için view.
