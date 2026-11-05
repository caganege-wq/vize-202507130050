"""
Ham anotasyon dosyasindan (data/raw/forklift_hf_rows_raw.json) rampa olay
tablosunu uretir: data/derived/events.csv

Ham dosya hicbir zaman degistirilmez; bu betik onu sadece okur.

GERCEK olan kisim (kaynaktan gelir):
  - her satir, gercek bir goruntudeki gercek bir tespittir (forklift ya da insan)
  - detected_class, bbox_x, bbox_y, bbox_w, bbox_h, area_px, image_w, image_h
  - event_type ve severity_1_5, yalnizca bu gercek kutulardan kurala gore hesaplanir

SIMULASYON olan kisim (kaynakta yok, bu betik atar, sabit tohumla):
  - dock_code  (hangi rampa)
  - event_at   (olay zamani; vardiya bu zamandan turetilir)
  Ayni karedeki tespitler ayni rampa ve zamani alir. Rampa ve zaman, dagilim hakkinda bir varsayim yapmamak icin ESIT olasilikla
  atanir. Bu yuzden rampa/vardiya/saat sorgularinin sonucu bir bulgu degil,
  sorgunun dogru calistiginin gosterimidir.

Calistirma:  python3 scripts/build_events.py
"""

import csv
import json
import random
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "data" / "raw" / "forklift_hf_rows_raw.json"
OUT = ROOT / "data" / "derived" / "events.csv"

SEED = 202507130050          # ogrenci numarasi; herkes ayni dosyayi uretir
CATEGORY = {0: "forklift", 1: "person"}
MIN_PERSON_AREA = 400        # piksel^2; daha kucuk insan kutusunda siddet NULL
DOCKS = ["R-01", "R-02", "R-03", "R-04", "R-05", "R-06"]
LEGACY_DOCKS = {"R-04", "R-05", "R-06"}   # eski kamera yazilimi: "r4" bicimi
START = datetime(2026, 9, 28, 0, 0, tzinfo=timezone(timedelta(hours=3)))
DAYS = 28                    # 4 hafta


def intersection(a, b):
    ax, ay, aw, ah = a
    bx, by, bw, bh = b
    w = min(ax + aw, bx + bw) - max(ax, bx)
    h = min(ay + ah, by + bh) - max(ay, by)
    return max(w, 0) * max(h, 0)


def overlap_ratio(box, area, forklifts):
    """Insan kutusunun yuzde kaci bir forklift kutusunun icinde."""
    if not area:
        return 0
    return max((intersection(box, f[1]) for f in forklifts), default=0) / area


def classify(obj, others):
    """Gercek kutulardan olay turu ve siddet. Kural SCENARIO.md'de yazili."""
    cls, box, area = obj
    forklifts = [o for o in others if o[0] == "forklift"]

    if cls == "person":
        ratio = overlap_ratio(box, area, forklifts)
        if ratio >= 0.9:                    # kutu tamamen forkliftin icinde: surucu
            etype, sev = "forklift_operatoru", 1
        elif ratio >= 0.25:                 # kismen forkliftin ustunde: temas
            etype, sev = "yaya_forklift_temas", (5 if ratio >= 0.5 else 4)
        elif forklifts:                     # ayni karede, temas yok
            etype, sev = "yaya_forklift_alaninda", 3
        else:
            etype, sev = "rampada_yaya", 2
        if area < MIN_PERSON_AREA:          # cok uzak/kucuk: siddet belirlenemez
            sev = None
        return etype, sev

    # forklift tespiti: karede operator disinda bir insan var mi?
    pedestrians = [
        o for o in others
        if o[0] == "person" and overlap_ratio(o[1], o[2], [(cls, box, area)]) < 0.9
    ]
    if pedestrians:
        return "forklift_yaya_yaninda", 2
    return "forklift_hareketi", 1


def main():
    data = json.loads(RAW.read_text(encoding="utf-8"))
    rng = random.Random(SEED)
    rows = []
    for page in data["pages"]:
        for r in page["rows"]:
            img = r["row"]
            o = img["objects"]
            objs = [
                (CATEGORY[o["category"][i]], [round(v) for v in o["bbox"][i]], o["area"][i], o["id"][i])
                for i in range(len(o["id"]))
            ]
            # ayni karedeki tespitler ayni rampa ve ayni zamani paylasir (SIMULASYON)
            dock = rng.choice(DOCKS)
            dock_code = f"r{int(dock[2:])}" if dock in LEGACY_DOCKS else dock
            event_at = START + timedelta(minutes=rng.randrange(DAYS * 24 * 60))

            for cls, box, area, oid in objs:
                others = [(c, b, a) for c, b, a, x in objs if x != oid]
                etype, sev = classify((cls, box, area), others)

                rows.append({
                    "source_split": page["split"],
                    "source_image_id": img["image_id"],
                    "source_object_id": oid,
                    "detected_class": cls,
                    "bbox_x": box[0], "bbox_y": box[1], "bbox_w": box[2], "bbox_h": box[3],
                    "area_px": area,
                    "image_w": img["width"], "image_h": img["height"],
                    "event_type": etype,
                    "severity_1_5": "" if sev is None else sev,
                    "dock_code": dock_code,
                    "event_at": event_at.isoformat(timespec="minutes"),
                })

    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)
    print(f"{len(rows)} satir yazildi: {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
