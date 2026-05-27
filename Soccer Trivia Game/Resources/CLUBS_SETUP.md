# Guess the Club Logo – Clubs Data

The "Guess the Club Logo" mode uses a local `clubs.json` built from **Wikidata** (association football clubs with logo image P154). No API key required.

## Generate/update clubs.json

From the `Resources` folder:

```bash
cd "Soccer Trivia Game/Resources"
python3 fetch_clubs_wikidata.py --limit 150
```

**First-division only (default: on)**  
By default the script only fetches clubs that play or have played in a **top first-division league** (Premier League, La Liga, Bundesliga, Serie A, Ligue 1, Liga Portugal, Eredivisie, Belgian Pro League, Scottish Premiership, Süper Lig, Argentine Primera, Brasileirão, MLS). That keeps logos recognizable. To include all clubs from Wikidata (including lower divisions and obscure leagues), use:

```bash
python3 fetch_clubs_wikidata.py --limit 150 --no-first-division
```

**Logo validation (default: on)**  
By default the script checks each logo URL with a HEAD request and **only includes clubs whose logo actually loads**. That way the game never shows blank logos. This takes a bit longer (a few seconds per 50 clubs). To skip validation:

```bash
python3 fetch_clubs_wikidata.py --limit 150 --no-validate-logos
```

Options: `--limit N`, `--out clubs.json`, `--min-replace N`, `--first-division` (default), `--no-first-division`, `--validate-logos` (default), `--no-validate-logos`.

## Difficulty and blur

- **Blur:** The logo is shown with a blur effect during the round; after you answer, the blur is removed. Difficulty can be increased by using a higher blur radius (see `GuessLogoGameViewModel.blurRadius`).
- **Popularity:** Clubs in `clubs.json` can have a `popularity` field (1 = very popular, 2 = medium, 3 = less known). You can filter by popularity for easier games (e.g. only popular clubs) or mix for harder games. The fetch script currently sets all to `popularity: 2`; you can edit the JSON or extend the script to assign tiers from Wikidata (e.g. by league or sitelinks).

## File location

`clubs.json` must be in `Soccer Trivia Game/Resources/` and included in your Xcode target’s **Copy Bundle Resources**.
