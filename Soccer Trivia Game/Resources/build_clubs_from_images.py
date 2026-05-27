#!/usr/bin/env python3
"""
Build clubs.json and club-logos/ from images/club logos/.
- Uses 512x512 PNGs (best size for display); copies to Resources/club-logos/{slug}.png.
- Club name from filename: e.g. arsenal.football-logos.cc.png -> "Arsenal".
- Alternatives for multiple choice are other club names (handled by the app).
- Deletes other size folders and SVG files under images/club logos/.
"""

import json
import os
import shutil
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
IMAGES_BASE = os.path.join(SCRIPT_DIR, "..", "images", "club logos")
OUT_LOGOS_DIR = os.path.join(SCRIPT_DIR, "club-logos")
CLUBS_JSON = os.path.join(SCRIPT_DIR, "clubs.json")
SIZE_DIR = "512x512"
SUFFIX = ".football-logos.cc.png"


def slug_to_display_name(slug: str) -> str:
    """e.g. manchester-city -> Manchester City, arsenal -> Arsenal."""
    s = slug.replace("-", " ")
    return s.title() if s else slug


def main() -> int:
    if not os.path.isdir(IMAGES_BASE):
        print("Missing folder: %s" % IMAGES_BASE)
        return 1
    os.makedirs(OUT_LOGOS_DIR, exist_ok=True)
    seen_slugs = set()
    clubs = []
    for league_dir in sorted(os.listdir(IMAGES_BASE)):
        path = os.path.join(IMAGES_BASE, league_dir)
        if not os.path.isdir(path):
            continue
        size_dir = os.path.join(path, SIZE_DIR)
        if not os.path.isdir(size_dir):
            continue
        for f in os.listdir(size_dir):
            if not f.endswith(SUFFIX):
                continue
            slug = f[: -len(SUFFIX)]
            if slug in seen_slugs:
                continue
            seen_slugs.add(slug)
            src = os.path.join(size_dir, f)
            dst = os.path.join(OUT_LOGOS_DIR, slug + ".png")
            shutil.copy2(src, dst)
            name = slug_to_display_name(slug)
            clubs.append({
                "id": slug,
                "name": name,
                "logo": "club-logos/" + slug,
                "source": "local",
                "popularity": 2,
            })
    clubs.sort(key=lambda x: x["name"])
    with open(CLUBS_JSON, "w", encoding="utf-8") as f:
        json.dump(clubs, f, indent=2, ensure_ascii=False)
    print("Wrote %d clubs to %s and %s" % (len(clubs), OUT_LOGOS_DIR, CLUBS_JSON))
    # Delete other sizes and SVGs under images/club logos/
    for league_dir in os.listdir(IMAGES_BASE):
        path = os.path.join(IMAGES_BASE, league_dir)
        if not os.path.isdir(path):
            continue
        for name in os.listdir(path):
            item = os.path.join(path, name)
            if name == SIZE_DIR:
                continue
            if os.path.isdir(item):
                shutil.rmtree(item, ignore_errors=True)
                print("  Removed folder: %s" % os.path.join(league_dir, name))
            elif name.endswith(".svg"):
                try:
                    os.remove(item)
                    print("  Removed: %s" % os.path.join(league_dir, name))
                except OSError:
                    pass
    # Remove now-empty 512x512 folders and empty league dirs
    for league_dir in list(os.listdir(IMAGES_BASE)):
        path = os.path.join(IMAGES_BASE, league_dir)
        if not os.path.isdir(path):
            continue
        size_dir = os.path.join(path, SIZE_DIR)
        if os.path.isdir(size_dir):
            shutil.rmtree(size_dir, ignore_errors=True)
        if not os.listdir(path):
            os.rmdir(path)
            print("  Removed empty league dir: %s" % league_dir)
    return 0


if __name__ == "__main__":
    sys.exit(main())
