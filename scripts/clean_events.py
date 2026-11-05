"""
data/derived/events.csv -> data/clean/events_clean.csv

Temizleme adimlari (veri kartinda da yazili):
  1. dock_code tek bicime: "r4" ve "R-04" -> "R-04"
  2. shift_name eklenir: olay saatine gore Sabah (06-14), Aksam (14-22),
     Gece (22-06). Gece vardiyasi gece yarisini astigi icin bitis (06:00)
     baslangictan (22:00) kucuk; saat >= 22 VEYA saat < 6 kurali kullanilir.
  3. severity_1_5 bos ise bos birakilir (NULL). Bos siddet 0 YAPILMAZ:
     siddet sifir degil, bilinmiyor.
  4. Satira kalici bir event_id verilir (1'den baslar).

Ham ve turetilmis dosyalar degistirilmez.
Calistirma:  python3 scripts/clean_events.py
"""

import csv
import re
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "data" / "derived" / "events.csv"
OUT = ROOT / "data" / "clean" / "events_clean.csv"


def normalize_dock(code):
    digits = re.sub(r"\D", "", code)
    return f"R-{int(digits):02d}"


def shift_of(hour):
    if 6 <= hour < 14:
        return "Sabah"
    if 14 <= hour < 22:
        return "Aksam"
    return "Gece"


def main():
    with SRC.open(encoding="utf-8") as f:
        rows = list(csv.DictReader(f))

    out = []
    for i, r in enumerate(rows, start=1):
        at = datetime.fromisoformat(r["event_at"])
        out.append({
            "event_id": i,
            "dock_code": normalize_dock(r["dock_code"]),
            "shift_name": shift_of(at.hour),
            "event_type": r["event_type"],
            "severity_1_5": r["severity_1_5"],
            "event_at": r["event_at"],
            "detected_class": r["detected_class"],
            "area_px": r["area_px"],
            "bbox_w": r["bbox_w"],
            "bbox_h": r["bbox_h"],
            "image_w": r["image_w"],
            "image_h": r["image_h"],
            "source_image_id": r["source_image_id"],
            "source_object_id": r["source_object_id"],
            "source_split": r["source_split"],
        })

    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(out[0]))
        w.writeheader()
        w.writerows(out)
    print(f"{len(out)} satir yazildi: {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
