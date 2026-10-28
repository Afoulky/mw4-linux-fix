#!/usr/bin/env python3
"""Give the Steam emulator a fixed account ID so save files keep loading.

With an empty `account_steamid` the emulator picks a new random ID on every game
exit, and the save folder named after the old ID is never found again. This sets
the value once. It never overwrites an ID that is already set.

Source of the ID, in order: the ID already set in either settings file, the oldest
numeric folder under the game's `players` directory, then a newly generated ID. It
is written to each of the two settings files that has none; an ID that is set is
never changed.
"""

import argparse
from pathlib import Path
import random
import re
import shutil
import sys

STEAM_ID = re.compile(r"7656119\d{10}")
ID_LINE = re.compile(r"^(\s*account_steamid\s*=)(.*)$")
SECTION = "[user::general]"


def id_in(path: Path) -> str | None:
    if not path.is_file():
        return None
    for line in path.read_text(errors="replace").splitlines():
        match = ID_LINE.match(line)
        if match and STEAM_ID.fullmatch(match.group(2).strip()):
            return match.group(2).strip()
    return None


def oldest_player_id(players: Path) -> str | None:
    if not players.is_dir():
        return None
    folders = [
        entry for entry in players.iterdir()
        if entry.is_dir() and STEAM_ID.fullmatch(entry.name)
    ]
    if not folders:
        return None
    return min(folders, key=lambda entry: entry.stat().st_mtime).name


def with_id(text: str, steam_id: str) -> str:
    lines = text.splitlines()
    for index, line in enumerate(lines):
        match = ID_LINE.match(line)
        if match:
            lines[index] = f"{match.group(1)}{steam_id}"
            return "\n".join(lines) + "\n"
    for index, line in enumerate(lines):
        if line.strip() == SECTION:
            lines.insert(index + 1, f"account_steamid={steam_id}")
            return "\n".join(lines) + "\n"
    return "\n".join([SECTION, f"account_steamid={steam_id}", "", *lines]) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--ini", type=Path, required=True)
    parser.add_argument("--local-ini", type=Path, required=True)
    parser.add_argument("--players", type=Path, required=True)
    args = parser.parse_args()

    if not args.ini.is_file():
        return 0
    # Both settings files need the same ID; only a file without one is touched.
    targets = [path for path in (args.ini, args.local_ini) if path.is_file() and not id_in(path)]
    if not targets:
        return 0

    steam_id = (
        id_in(args.ini)
        or id_in(args.local_ini)
        or oldest_player_id(args.players)
        or f"76561198{random.randrange(10**9):09d}"
    )
    for path in targets:
        backup = Path(str(path) + ".pre-mw4-launch")
        if not backup.exists():
            shutil.copy2(path, backup)
        path.write_text(with_id(path.read_text(errors="replace"), steam_id))
        print(f"mw4-launch: set account_steamid={steam_id} in {path}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
