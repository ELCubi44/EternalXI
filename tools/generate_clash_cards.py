#!/usr/bin/env python3
"""Genera cards.json Clash (N/R/SR) desde export TSV de MySQL Eterno Campeon."""
from __future__ import annotations

import json
import math
import re
import unicodedata
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PLAYERS_TSV = ROOT / ".local" / "tools" / "clash_players.tsv"
ST_TSV = ROOT / ".local" / "tools" / "clash_st.tsv"
OUT_JSON = ROOT / "eternalxi_front" / "assets" / "data" / "clash" / "cards.json"
MANIFEST_JSON = ROOT / "eternalxi_front" / "assets" / "data" / "clash" / "cards_manifest.json"

STYLE_MAP = {
    "PICARO": "picaro",
    "PRECISO": "preciso",
    "POTENTE": "potente",
    "VALIENTE": "valiente",
    "AGIL": "agil",
}

ST_TYPE_MAP = {
    "PARADA": "save",
    "DEFENSA": "defense",
    "REGATE": "dribble",
    "TIRO": "shot",
}

# Perfiles finos por subposición Clash (base, spread) a valoración 70→92.
POS_PROFILE = {
    "goalkeeper": {
        "save": (30, 14),
        "defense": (16, 8),
        "pass": (12, 6),
        "dribble": (6, 4),
        "shot": (4, 2),
        "techniquePoints": (16, 8),
        "stamina": (100, 8),
    },
    "centreBack": {
        "save": (4, 2),
        "defense": (31, 12),
        "pass": (13, 6),
        "dribble": (8, 4),
        "shot": (7, 3),
        "techniquePoints": (16, 8),
        "stamina": (102, 8),
    },
    "fullBack": {
        "save": (4, 2),
        "defense": (25, 11),
        "pass": (16, 7),
        "dribble": (13, 6),
        "shot": (9, 4),
        "techniquePoints": (16, 8),
        "stamina": (103, 8),
    },
    "defensiveMidfielder": {
        "save": (3, 1),
        "defense": (21, 9),
        "pass": (22, 10),
        "dribble": (15, 7),
        "shot": (12, 5),
        "techniquePoints": (18, 8),
        "stamina": (104, 8),
    },
    "attackingMidfielder": {
        "save": (3, 1),
        "defense": (13, 7),
        "pass": (23, 10),
        "dribble": (20, 9),
        "shot": (17, 7),
        "techniquePoints": (18, 8),
        "stamina": (104, 8),
    },
    "winger": {
        "save": (3, 1),
        "defense": (11, 5),
        "pass": (16, 7),
        "dribble": (24, 11),
        "shot": (22, 10),
        "techniquePoints": (18, 8),
        "stamina": (106, 10),
    },
    "striker": {
        "save": (3, 1),
        "defense": (12, 6),
        "pass": (12, 5),
        "dribble": (18, 8),
        "shot": (28, 13),
        "techniquePoints": (18, 8),
        "stamina": (105, 10),
    },
}

RARITY_MULT = {"n": 1.0, "r": 1.08, "sr": 1.18}
RARITY_ST_COUNT = {"n": 1, "r": 2, "sr": 3}
PT_COST_BY_POWER = [(70, 12), (55, 10), (40, 9), (0, 8)]


def slugify(text: str) -> str:
    text = unicodedata.normalize("NFKD", text)
    text = text.encode("ascii", "ignore").decode("ascii")
    text = re.sub(r"[^a-zA-Z0-9]+", "-", text).strip("-").lower()
    return text or "player"


def clash_position(pos: str, dorsal: int) -> str:
    if pos == "POR":
        return "goalkeeper"
    if pos == "DEF":
        return "fullBack" if dorsal % 2 == 0 else "centreBack"
    if pos == "MED":
        return "defensiveMidfielder" if dorsal <= 8 else "attackingMidfielder"
    return "winger" if dorsal % 2 == 0 else "striker"


def pos_code(position: str) -> str:
    return {
        "goalkeeper": "gk",
        "centreBack": "cb",
        "fullBack": "fb",
        "defensiveMidfielder": "dm",
        "attackingMidfielder": "am",
        "winger": "wg",
        "striker": "st",
    }[position]


def stat_value(base: float, spread: float, scale: float, mult: float) -> int:
    return max(1, int(round((base + spread * scale) * mult)))


def build_stats(clash_pos: str, valoracion: int, rarity: str) -> dict:
    profile = POS_PROFILE[clash_pos]
    scale = max(0.0, min(1.0, (valoracion - 70) / 22.0))
    mult = RARITY_MULT[rarity]
    return {
        key: stat_value(base, spread, scale, mult)
        for key, (base, spread) in profile.items()
    }


def pt_cost(power: int) -> int:
    for threshold, cost in PT_COST_BY_POWER:
        if power >= threshold:
            return cost
    return 8


def load_players() -> list[dict]:
    rows = []
    for line in PLAYERS_TSV.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        parts = line.split("\t")
        if len(parts) < 10:
            continue
        rows.append(
            {
                "id": int(parts[0]),
                "teamId": int(parts[1]),
                "team": parts[2],
                "name": parts[3],
                "pila": parts[4],
                "dorsal": int(parts[5]),
                "posicion": parts[6],
                "estilo": parts[7],
                "valoracion": int(float(parts[8])),
                "foto": parts[9] if len(parts) > 9 else "",
            }
        )
    return rows


def load_supertechniques() -> dict[int, list[dict]]:
    by_player: dict[int, list[dict]] = defaultdict(list)
    for line in ST_TSV.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        parts = line.split("\t")
        if len(parts) < 8:
            continue
        player_id = int(parts[0])
        by_player[player_id].append(
            {
                "orden": int(parts[2]),
                "clave": parts[3],
                "potencia": int(parts[4]),
                "tipo": parts[5],
                "estilo": parts[6],
                "nombre": parts[7],
            }
        )
    for st_list in by_player.values():
        st_list.sort(key=lambda x: x["orden"])
    return by_player


def build_st_entries(player_id: int, st_list: list[dict], rarity: str, card_id: str) -> list[dict]:
    count = RARITY_ST_COUNT[rarity]
    entries = []
    for idx, st in enumerate(st_list[:count], start=1):
        power = st["potencia"]
        entries.append(
            {
                "id": f"{card_id}-st{idx}",
                "name": st["nombre"],
                "description": st["nombre"],
                "type": ST_TYPE_MAP[st["tipo"]],
                "style": STYLE_MAP[st["estilo"]],
                "basePower": power,
                "ptCost": pt_cost(power),
                "level": "normal",
            }
        )
    return entries


def main() -> None:
    players = load_players()
    st_by_player = load_supertechniques()
    cards = []

    team_counters: dict[str, int] = defaultdict(int)

    for player in players:
        pid = player["id"]
        pos = player["posicion"]
        dorsal = player["dorsal"]
        position = clash_position(pos, dorsal)
        pcode = pos_code(position)
        team_slug = slugify(player["team"])
        team_counters[team_slug] += 1
        seq = team_counters[team_slug]

        style = STYLE_MAP[player["estilo"]]
        st_list = st_by_player.get(pid, [])

        for rarity in ("n", "r", "sr"):
            card_id = f"{team_slug}-{rarity}-{pcode}-{seq:03d}"
            stats = build_stats(position, player["valoracion"], rarity)
            card = {
                "id": card_id,
                "playerId": pid,
                "name": player["name"],
                "team": player["team"],
                "dorsal": dorsal,
                "teamId": player["teamId"],
                "rarity": rarity,
                "level": 1,
                "style": style,
                "position": position,
                "basicPortraitPath": "network",
                "stats": stats,
                "superTechniques": build_st_entries(pid, st_list, rarity, card_id),
            }
            cards.append(card)

    payload = {"schemaVersion": 1, "cards": cards}
    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    raw = json.dumps(payload, ensure_ascii=False, indent=2)
    OUT_JSON.write_text(raw, encoding="utf-8")

    size_bytes = OUT_JSON.stat().st_size
    manifest = {
        "schemaVersion": 1,
        "cardsVersion": 1,
        "cardsUrl": "https://api.eternalxi.com/api/v1/assets/clash/cards.json",
        "cardsBytes": size_bytes,
        "cardsSha256": None,
        "playerCount": len(players),
        "cardCount": len(cards),
        "portraitsBaseUrl": "https://api.eternalxi.com/api/v1/assets/players",
        "portraitsBytesEstimate": len(players) * 1650000,
        "portraitsVersion": 1,
    }
    MANIFEST_JSON.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    eternal_xi_n = sum(
        1 for c in cards if c["team"] == "Eternal XI" and c["rarity"] == "n"
    )
    print(f"Generated {len(cards)} cards for {len(players)} players")
    print(f"Eternal XI N cards: {eternal_xi_n}")
    print(f"Output: {OUT_JSON} ({size_bytes / 1024 / 1024:.2f} MB)")


if __name__ == "__main__":
    main()
