"""
Build quiz bank from external data. NOTE: API-Football integration was removed.
This script previously used API-Football for teams/squads; it now does nothing
unless you plug in another data source. Kept for structure reference.
"""
import json
import os
import random
import urllib.request

API_BASE = ""
API_KEY_ENV = ""


def api_get(path, params):
    raise RuntimeError("API-Football was removed. No external API is configured.")


def build_logo_questions(teams, mask_count=2):
    questions = []
    for team in teams:
        name = team["team"]["name"]
        logo_url = team["team"]["logo"]
        mask_rects = []
        for _ in range(mask_count):
            x = round(random.uniform(0.05, 0.6), 2)
            y = round(random.uniform(0.05, 0.6), 2)
            width = round(random.uniform(0.2, 0.45), 2)
            height = round(random.uniform(0.2, 0.45), 2)
            mask_rects.append({"x": x, "y": y, "width": width, "height": height})
        questions.append(
            {
                "id": f"logo_{team['team']['id']}",
                "type": "logo_partial",
                "text": "Identify the club crest",
                "options": [name],
                "correctAnswer": 0,
                "category": "Logo",
                "difficulty": "medium",
                "logo": {
                    "teamName": name,
                    "imageURL": logo_url,
                    "imageAssetName": None,
                    "maskRects": mask_rects,
                },
            }
        )
    return questions


def build_lineup_questions(squads, missing_count=4):
    questions = []
    for squad in squads:
        team = squad["team"]["name"]
        players = [p["name"] for p in squad.get("players", [])]
        if len(players) < missing_count + 6:
            continue
        missing = random.sample(players, missing_count)
        options = list(set(missing + random.sample(players, missing_count)))
        random.shuffle(options)
        questions.append(
            {
                "id": f"lineup_{squad['team']['id']}",
                "type": "lineup",
                "text": f"Complete the lineup for {team}",
                "options": options,
                "correctAnswer": 0,
                "category": "Lineup",
                "difficulty": "hard",
                "lineup": {
                    "teamName": team,
                    "formation": "4-3-3",
                    "missingPlayers": missing,
                    "options": options,
                },
            }
        )
    return questions


def main():
    print("API-Football was removed. This script does not call any external API.")
    print("Exiting without generating quiz_bank.json.")
    return

    league = os.environ.get("API_LEAGUE", "39")
    season = os.environ.get("API_SEASON", "2025")

    teams_response = api_get("teams", {"league": league, "season": season})
    teams = teams_response.get("response", [])

    squads_response = api_get("players/squads", {"league": league, "season": season})
    squads = squads_response.get("response", [])

    quiz_items = []
    quiz_items.extend(build_logo_questions(teams))
    quiz_items.extend(build_lineup_questions(squads))

    output_path = os.environ.get("OUTPUT_PATH", "quiz_bank.json")
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(quiz_items, f, indent=2)

    print(f"Generated {len(quiz_items)} items in {output_path}")


if __name__ == "__main__":
    main()

