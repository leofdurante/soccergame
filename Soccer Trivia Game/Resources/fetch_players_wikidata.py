#!/usr/bin/env python3
"""
Fetch association football players from Wikidata Query Service (SPARQL).
Generates players.json with: id (QID), name, photo (Wikimedia URL), optionally nationality/position.
No API key required. Images come from Wikimedia Commons (see README for attribution).
"""

import argparse
import json
import re
import sys
import time
import urllib.parse
import urllib.request

SPARQL_ENDPOINT = "https://query.wikidata.org/sparql"
USER_AGENT = "GuessThePlayerApp/1.0 (https://github.com/guess-the-player; Python)"
MIN_PLAYERS_TO_REPLACE = 50  # Only replace players.json if we get at least this many


def sparql_query(query: str) -> list[dict]:
    """Run a SPARQL query against Wikidata; return list of bindings (JSON)."""
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


def image_url_from_value(binding: dict) -> str | None:
    """Extract image URL; use HTTPS so iOS loads (ATS)."""
    if "image" not in binding:
        return None
    node = binding["image"]
    val = node.get("value") or ""
    if not val or not val.startswith("http"):
        return None
    if val.startswith("http://"):
        val = "https://" + val[7:]
    return val


def main_query(limit: int) -> list[dict]:
    """
    SPARQL: association football players with image, restricted to players who have
    been in a top league (so we get recognizable players, not random small-league ones).
    P54 = member of sports team, P118 = league. Top leagues: Premier League, La Liga,
    Bundesliga, Serie A, Ligue 1, Liga Portugal, Eredivisie, Belgian Pro League, etc.
    """
    # Top league QIDs: Premier League, La Liga, Bundesliga, Serie A, Ligue 1, Liga Portugal,
    # Eredivisie, Belgian Pro League, Scottish Premiership, Süper Lig, Argentine Primera, Brasileirão, MLS
    query = """
    SELECT DISTINCT ?player ?playerLabel ?image ?nationalityLabel ?positionLabel WHERE {
      ?player wdt:P31 wd:Q5 .
      ?player wdt:P106 wd:Q937857 .
      ?player wdt:P18 ?image .
      ?player wdt:P54 ?team .
      ?team wdt:P118 ?league .
      VALUES ?league {
        wd:Q9448 wd:Q3247 wd:Q12916 wd:Q13114 wd:Q13975 wd:Q57336 wd:Q32102
        wd:Q134964 wd:Q19522 wd:Q3482 wd:Q7020 wd:Q1144612 wd:Q2530
      }
      OPTIONAL { ?player wdt:P27 ?nationality . }
      OPTIONAL { ?player wdt:P413 ?position . }
      SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
    }
    ORDER BY ?player
    LIMIT %d
    """ % (
        min(limit + 500, 5000),
    )
    return sparql_query(query)


def row_to_player(row: dict) -> dict | None:
    """Convert one SPARQL binding to game player entry."""
    qid = None
    for key in ("player", "playerLabel", "image"):
        if key not in row:
            return None
    player_uri = row["player"]["value"]
    m = re.search(r"Q\d+$", player_uri)
    if not m:
        return None
    qid = m.group(0)
    name = row["playerLabel"].get("value") or ""
    name = name.strip()
    if not name:
        return None
    photo = image_url_from_value(row)
    if not photo or not photo.startswith("http"):
        return None
    rec = {
        "id": qid,
        "name": name,
        "photo": photo,
        "source": "wikidata",
    }
    if "nationalityLabel" in row and row["nationalityLabel"].get("value"):
        rec["nationality"] = row["nationalityLabel"]["value"].strip()
    if "positionLabel" in row and row["positionLabel"].get("value"):
        rec["position"] = row["positionLabel"]["value"].strip()
    return rec


def dedupe_by_id(players: list[dict]) -> list[dict]:
    """Deduplicate by id (QID); keep first occurrence."""
    seen = set()
    out = []
    for p in players:
        pid = p.get("id") or ""
        if pid and pid not in seen:
            seen.add(pid)
            out.append(p)
    return out


def merge_into_existing(new_players: list[dict], existing_path: str) -> list[dict]:
    """Load existing players.json and merge new by id (no duplicate id)."""
    try:
        with open(existing_path, "r", encoding="utf-8") as f:
            existing = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return new_players
    if not isinstance(existing, list):
        return new_players
    by_id = {str(p.get("id") or ""): p for p in existing if p.get("id")}
    for p in new_players:
        pid = str(p.get("id") or "")
        if pid and pid not in by_id:
            by_id[pid] = p
    return list(by_id.values())


def run_search(search_term: str) -> list[dict]:
    """Optional --search: find entities matching name with image (for debugging)."""
    # Simple search: same SPARQL but filter by label
    query = """
    SELECT ?player ?playerLabel ?image WHERE {
      ?player wdt:P31 wd:Q5 .
      ?player wdt:P106 wd:Q937857 .
      ?player wdt:P18 ?image .
      ?player rdfs:label ?playerLabel .
      FILTER(LANG(?playerLabel) = "en") .
      FILTER(CONTAINS(LCASE(?playerLabel), LCASE("%s"))) .
    }
    ORDER BY ?player
    LIMIT 20
    """ % (
        search_term.replace('"', '\\"')[:100],
    )
    rows = sparql_query(query)
    return [row_to_player(r) for r in rows if row_to_player(r)]


def main():
    parser = argparse.ArgumentParser(description="Fetch football players from Wikidata into players.json")
    parser.add_argument("--limit", type=int, default=200, help="Max number of players to fetch (default 200)")
    parser.add_argument("--out", default="players.json", help="Output JSON file (default players.json)")
    parser.add_argument("--merge", action="store_true", help="Merge results into existing --out by id")
    parser.add_argument("--search", type=str, metavar="NAME", help="Optional: return best matches for NAME with images")
    parser.add_argument("--min-replace", type=int, default=MIN_PLAYERS_TO_REPLACE, help="Min players to replace --out (default %d)" % MIN_PLAYERS_TO_REPLACE)
    args = parser.parse_args()

    if args.search:
        print("Searching Wikidata for:", args.search)
        time.sleep(0.5)
        results = run_search(args.search)
        print(json.dumps(results, indent=2, ensure_ascii=False))
        return 0

    print("Fetching up to %d association football players from Wikidata..." % args.limit)
    time.sleep(0.3)
    rows = main_query(args.limit)
    players = []
    for row in rows:
        p = row_to_player(row)
        if p:
            players.append(p)
    players = dedupe_by_id(players)
    # Deterministic: sort by id (QID) then take first args.limit
    players.sort(key=lambda x: (x.get("id") or ""))
    players = players[: args.limit]

    if args.merge and args.out:
        players = merge_into_existing(players, args.out)
        players.sort(key=lambda x: (x.get("id") or ""))

    raw_path = "players_wikidata_raw.json"
    with open(raw_path, "w", encoding="utf-8") as f:
        json.dump(players, f, indent=2, ensure_ascii=False)
    print("Wrote %d players to %s" % (len(players), raw_path))

    if len(players) >= args.min_replace:
        with open(args.out, "w", encoding="utf-8") as f:
            json.dump(players, f, indent=2, ensure_ascii=False)
        print("Wrote %d players to %s (>= %d)" % (len(players), args.out, args.min_replace))
    else:
        print("Did not replace %s (only %d players; need >= %d)" % (args.out, len(players), args.min_replace))

    return 0


if __name__ == "__main__":
    sys.exit(main())
