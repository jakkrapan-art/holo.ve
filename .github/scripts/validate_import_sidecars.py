#!/usr/bin/env python3

import re
import sys
from pathlib import Path


SOURCE_PATTERN = re.compile(r'source_file="(res://[^"]+)"')
UID_PATTERN = re.compile(r'\buid="uid://[^"]+"')


def main() -> int:
    root = Path(sys.argv[1] if len(sys.argv) > 1 else Path(__file__).parents[2]).resolve()
    if not (root / "project.godot").is_file():
        print(f"INVALID-ROOT {root}: project.godot not found", file=sys.stderr)
        return 2

    errors = 0
    for sidecar in sorted(root.rglob("*.import")):
        relative_sidecar = sidecar.relative_to(root)
        if any(part in {".git", ".godot"} for part in relative_sidecar.parts):
            continue

        source = Path(str(sidecar)[: -len(".import")])
        expected_source = "res://" + source.relative_to(root).as_posix()
        if not source.is_file():
            errors += 1
            print(f"ORPHAN-IMPORT {relative_sidecar.as_posix()}: {expected_source}")

        text = sidecar.read_text(encoding="utf-8")
        if UID_PATTERN.search(text) is None:
            errors += 1
            print(f"INVALID-IMPORT {relative_sidecar.as_posix()}: uid missing or invalid")

        match = SOURCE_PATTERN.search(text)
        if match is None:
            errors += 1
            print(f"INVALID-IMPORT {relative_sidecar.as_posix()}: source_file missing")
        elif match.group(1) != expected_source:
            errors += 1
            print(
                f"INVALID-IMPORT {relative_sidecar.as_posix()}: "
                f"source_file={match.group(1)} expected={expected_source}"
            )

    print(f"--- import sidecar errors: {errors}")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
