#!/usr/bin/env python3
"""
Fetch association football clubs (Q476028) with logo (P154) from Wikidata.
Output: clubs.json with id (QID), name, logo URL. Optional popularity tier for difficulty.
No API key required.
"""

import argparse
import json
import re
import sys
import time
import urllib.parse
import urllib.request
import urllib.error

SPARQL_ENDPOINT = "https://query.wikidata.org/sparql"
USER_AGENT = "GuessTheClubLogo/1.0 (Python)"
MIN_TO_REPLACE = 30
LOGOS_VALIDATE_TIMEOUT = 10
LOGOS_VALIDATE_DELAY = 0.35


def sparql_query(query: str) -> list:
    params = {"query": query, "format": "json"}
    data = urllib.parse.urlencode(params).encode("utf-8")
    req = urllib.request.Request(
        SPARQL_ENDPOINT,
        data=data,
        method="POST",
        headers={
            "User-Agent": USER_AGENT,
            "Content-Type": "application/x-www-form-urlencoded",
            "Accept": "application/sparql-results+json",
        },
    )
    with urllib.request.urlopen(req, timeout=60) as resp:
        out = json.loads(resp.read().decode("utf-8"))
    return out.get("results", {}).get("bindings", [])


# Top first-division leagues (P118): same set as players for recognizable clubs.
TOP_LEAGUE_QIDS = [
    "Q9448", "Q3247", "Q12916", "Q13114", "Q13975", "Q57336", "Q32102",
    "Q134964", "Q19522", "Q3482", "Q7020", "Q1144612", "Q2530",
]
# Major football nations (P17): clubs in these countries are more likely first-division / recognizable.
# England, Spain, Germany, Italy, France, Brazil, Argentina, Portugal, Netherlands, Belgium, Scotland, Turkey, USA, Mexico.
MAJOR_COUNTRY_QIDS = [
    "Q21", "Q29", "Q183", "Q38", "Q142", "Q155", "Q414", "Q45", "Q36", "Q31",
    "Q22", "Q43", "Q30", "Q96",
]


def main_query(limit: int, first_division_only: bool) -> list:
    # Association football club Q476028, has logo P154.
    cap = min(limit + 500, 3500)
    query = """
    SELECT ?club ?clubLabel ?logo WHERE {
      ?club wdt:P31/wdt:P279* wd:Q476028 .
      ?club wdt:P154 ?logo .
      SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
    }
    ORDER BY ?club
    LIMIT %d
    """ % cap
    return sparql_query(query)


def first_division_query(limit: int) -> list:
    """Clubs that play/have played in a top league (P118). May return few results in Wikidata."""
    values = " ".join("wd:" + q for q in TOP_LEAGUE_QIDS)
    cap = min(limit + 500, 3500)
    query = """
    SELECT ?club ?clubLabel ?logo WHERE {
      ?club wdt:P31/wdt:P279* wd:Q476028 .
      ?club wdt:P154 ?logo .
      ?club wdt:P118 ?league .
      VALUES ?league { %s }
      SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
    }
    ORDER BY ?club
    LIMIT %d
    """ % (values, cap)
    return sparql_query(query)


def major_country_query(limit: int) -> list:
    """Clubs in major football nations (P17). More likely first-division / recognizable."""
    values = " ".join("wd:" + q for q in MAJOR_COUNTRY_QIDS)
    cap = min(limit + 500, 3500)
    query = """
    SELECT ?club ?clubLabel ?logo WHERE {
      ?club wdt:P31/wdt:P279* wd:Q476028 .
      ?club wdt:P154 ?logo .
      ?club wdt:P17 ?country .
      VALUES ?country { %s }
      SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
    }
    ORDER BY ?club
    LIMIT %d
    """ % (values, cap)
    return sparql_query(query)


def is_real_club_name(name: str, qid: str) -> bool:
    """Reject labels that are just the QID or look like an ID."""
    if not name or len(name) < 3:
        return False
    if name == qid or re.match(r"^Q\d+$", name.strip()):
        return False
    return True


def logo_to_https_direct(logo_url: str) -> str:
    """Use HTTPS; iOS may not load http. Keep Commons URL (redirects to direct)."""
    if not logo_url:
        return logo_url
    s = logo_url.strip()
    if s.startswith("http://"):
        s = "https://" + s[7:]
    return s


def is_raster_logo(logo_url: str) -> bool:
    """True if logo is a raster format that iOS AsyncImage can display (.png, .jpg, .webp). SVG does not load in AsyncImage."""
    if not logo_url:
        return False
    u = logo_url.split("?")[0].strip().lower()
    return u.endswith(".png") or u.endswith(".jpg") or u.endswith(".jpeg") or u.endswith(".webp")


def validate_logo_url(logo_url: str) -> bool:
    """HEAD request to check logo URL is reachable and returns image content. Returns True if loadable."""
    if not logo_url or not logo_url.startswith("http"):
        return False
    req = urllib.request.Request(
        logo_url,
        method="HEAD",
        headers={"User-Agent": USER_AGENT},
    )
    try:
        with urllib.request.urlopen(req, timeout=LOGOS_VALIDATE_TIMEOUT) as resp:
            if resp.status != 200:
                return False
            ct = (resp.headers.get("Content-Type") or "").lower()
            if ct.startswith("image/"):
                return True
            # Some servers don't send Content-Type on HEAD; accept 200 as likely image
            return True
    except (urllib.error.URLError, urllib.error.HTTPError, OSError, TimeoutError):
        return False


def row_to_club(row: dict) -> dict | None:
    for key in ("club", "clubLabel", "logo"):
        if key not in row:
            return None
    uri = row["club"]["value"]
    m = re.search(r"Q\d+$", uri)
    if not m:
        return None
    qid = m.group(0)
    name = (row["clubLabel"].get("value") or "").strip()
    logo = (row["logo"].get("value") or "").strip()
    if not logo or not logo.startswith("http"):
        return None
    if not is_real_club_name(name, qid):
        return None
    logo = logo_to_https_direct(logo)
    return {
        "id": qid,
        "name": name,
        "logo": logo,
        "source": "wikidata",
        "popularity": 2,
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--limit", type=int, default=150)
    parser.add_argument("--out", default="clubs.json")
    parser.add_argument("--min-replace", type=int, default=MIN_TO_REPLACE)
    parser.add_argument(
        "--validate-logos",
        action="store_true",
        default=True,
        help="Verify each logo URL loads (HEAD request). Only include clubs with loadable logos. Default: True.",
    )
    parser.add_argument("--no-validate-logos", action="store_false", dest="validate_logos")
    parser.add_argument(
        "--first-division",
        action="store_true",
        default=True,
        help="Only clubs that play or have played in a top first-division league (Premier League, La Liga, Bundesliga, etc.). Default: True.",
    )
    parser.add_argument("--no-first-division", action="store_false", dest="first_division")
    parser.add_argument(
        "--major-countries-only",
        action="store_true",
        help="Only clubs in major football nations (faster, no P118 query). Overrides --first-division logic.",
    )
    parser.add_argument(
        "--raster-only",
        action="store_true",
        default=True,
        help="Only clubs whose logo is PNG/JPG/WebP (iOS AsyncImage cannot display SVG). Default: True.",
    )
    parser.add_argument("--no-raster-only", action="store_false", dest="raster_only")
    args = parser.parse_args()
    # Fetch extra so after validation we still have enough; when raster_only we need more candidates (many logos are SVG)
    fetch_limit = args.limit * 3 if args.validate_logos else args.limit + 500
    if args.raster_only:
        fetch_limit = max(fetch_limit, 2500)
    fetch_limit = min(fetch_limit, 3500)
    scope = "first-division " if args.first_division and not args.major_countries_only else ""
    if args.major_countries_only:
        scope = "major-countries "
    if args.raster_only:
        scope = scope + "raster-logo "
    print("Fetching up to %d %sfootball clubs from Wikidata..." % (fetch_limit, scope))
    time.sleep(0.3)
    clubs = []
    seen = set()
    def ok(c):
        return c and c["id"] not in seen and (not args.raster_only or is_raster_logo(c["logo"]))
    if args.major_countries_only:
        rows_country = major_country_query(fetch_limit)
        for row in rows_country:
            c = row_to_club(row)
            if ok(c):
                seen.add(c["id"])
                clubs.append(c)
        print("  Major-country clubs: %d" % len(clubs))
        if len(clubs) < args.limit:
            rows_all = main_query(fetch_limit, first_division_only=False)
            for row in rows_all:
                if len(clubs) >= args.limit:
                    break
                c = row_to_club(row)
                if ok(c):
                    seen.add(c["id"])
                    clubs.append(c)
            print("  Filled: %d total" % len(clubs))
    elif args.first_division:
        rows_fd = first_division_query(fetch_limit)
        for row in rows_fd:
            c = row_to_club(row)
            if ok(c):
                seen.add(c["id"])
                clubs.append(c)
        print("  First-division leagues: %d clubs" % len(clubs))
        if len(clubs) < args.limit:
            rows_country = major_country_query(fetch_limit)
            for row in rows_country:
                if len(clubs) >= args.limit:
                    break
                c = row_to_club(row)
                if ok(c):
                    seen.add(c["id"])
                    clubs.append(c)
            print("  Major-country clubs: %d total" % len(clubs))
        if len(clubs) < args.limit:
            rows_all = main_query(fetch_limit, first_division_only=False)
            for row in rows_all:
                if len(clubs) >= args.limit:
                    break
                c = row_to_club(row)
                if ok(c):
                    seen.add(c["id"])
                    clubs.append(c)
            print("  Filled with other clubs: %d total" % len(clubs))
    else:
        rows = main_query(fetch_limit, first_division_only=False)
        for row in rows:
            c = row_to_club(row)
            if ok(c):
                seen.add(c["id"])
                clubs.append(c)
    clubs.sort(key=lambda x: x["id"])
    clubs = clubs[: args.limit]
    if args.validate_logos and clubs:
        print("Validating logo URLs (HEAD request, only keeping clubs with loadable logos)...")
        validated = []
        for i, c in enumerate(clubs):
            if len(validated) >= args.limit:
                break
            time.sleep(LOGOS_VALIDATE_DELAY)
            if validate_logo_url(c["logo"]):
                validated.append(c)
            if (i + 1) % 50 == 0:
                print("  Checked %d, kept %d so far..." % (i + 1, len(validated)))
        clubs = validated
        print("Kept %d clubs with loadable logos." % len(clubs))
    else:
        clubs = clubs[: args.limit]
    raw_path = "clubs_wikidata_raw.json"
    with open(raw_path, "w", encoding="utf-8") as f:
        json.dump(clubs, f, indent=2, ensure_ascii=False)
    print("Wrote %d clubs to %s" % (len(clubs), raw_path))
    min_ok = min(args.min_replace, 20) if args.raster_only else args.min_replace
    if len(clubs) >= min_ok:
        with open(args.out, "w", encoding="utf-8") as f:
            json.dump(clubs, f, indent=2, ensure_ascii=False)
        print("Wrote %d clubs to %s" % (len(clubs), args.out))
    else:
        print("Did not replace %s (got %d, need >= %d)" % (args.out, len(clubs), min_ok))
    return 0


if __name__ == "__main__":
    sys.exit(main())
