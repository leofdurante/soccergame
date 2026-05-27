# Players Database Setup (Wikidata)

The "Guess the Player" mode uses a local `players.json` built from **Wikidata**. No API key is required; Wikidata and the Query Service are free.

## How to Run the Script

From the `Resources` folder:

```bash
cd "Soccer Trivia Game/Resources"
python3 fetch_players_wikidata.py
```

Options:

- `--limit N` — Max players to fetch (default 200).
- `--out FILE` — Output file (default `players.json`).
- `--merge` — Merge new results into existing `players.json` by unique id (QID).
- `--search "Name"` — Optional: print best-matching Wikidata entities with images (for testing).
- `--min-replace N` — Only replace `players.json` if the fetch returns at least N players (default 50).

Examples:

```bash
python3 fetch_players_wikidata.py --limit 300
python3 fetch_players_wikidata.py --out players.json --merge
python3 fetch_players_wikidata.py --search "Messi"
```

## How to Update players.json

1. Run the script (see above). It always writes `players_wikidata_raw.json`.
2. If the number of players is at least `--min-replace` (default 50), it also overwrites `players.json`.
3. If the fetch fails or returns too few players, `players.json` is **not** overwritten (your existing file is kept).
4. Use `--merge` to add new Wikidata players to your current `players.json` without removing existing entries (deduplicated by id).

## No API Key Needed

Wikidata Query Service does not require authentication. Use a proper User-Agent (the script sets one). Be respectful with rate limits; the script uses a short delay between requests when applicable.

## Attribution and Credits

- Player data and labels come from **Wikidata** (CC0 / public domain where applicable).
- **Images** come from **Wikimedia Commons** and may have different licenses (e.g. CC BY-SA). We recommend adding a **Credits** or **Attributions** page in the app that:
  - States that player images are from Wikimedia Commons.
  - Links to [commons.wikimedia.org](https://commons.wikimedia.org) and [wikidata.org](https://www.wikidata.org).
  - Notes that individual image licenses may apply.

## Validation

To check that every entry has `name` and a valid `photo` URL:

```bash
python3 validate_players.py players.json
```

## File Location

`players.json` must be in:

```
Soccer Trivia Game/Resources/players.json
```

Ensure it is included in your Xcode target’s **Copy Bundle Resources** build phase.
