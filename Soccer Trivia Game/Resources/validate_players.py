#!/usr/bin/env python3
"""
Validate players.json: each entry must have name, photo, and photo must be an http(s) URL.
"""

import json
import sys


def validate(path: str = "players.json") -> bool:
    ok = True
    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
    except FileNotFoundError:
        print("Error: %s not found" % path)
        return False
    except json.JSONDecodeError as e:
        print("Error: invalid JSON in %s: %s" % (path, e))
        return False

    if not isinstance(data, list):
        print("Error: root must be a list")
        return False

    for i, entry in enumerate(data):
        if not isinstance(entry, dict):
            print("Entry %d: not an object" % i)
            ok = False
            continue
        name = entry.get("name")
        photo = entry.get("photo")
        if not name or not isinstance(name, str) or not name.strip():
            print("Entry %d (id=%s): missing or empty 'name'" % (i, entry.get("id", "?")))
            ok = False
        if not photo or not isinstance(photo, str) or not photo.strip():
            print("Entry %d (id=%s): missing or empty 'photo'" % (i, entry.get("id", "?")))
            ok = False
        else:
            if not (photo.startswith("http://") or photo.startswith("https://")):
                print("Entry %d (id=%s): 'photo' is not an http(s) URL: %s" % (i, entry.get("id", "?"), photo[:50]))
                ok = False

    if ok:
        print("OK: %d entries in %s have name and valid photo URL" % (len(data), path))
    return ok


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else "players.json"
    sys.exit(0 if validate(path) else 1)


if __name__ == "__main__":
    main()
