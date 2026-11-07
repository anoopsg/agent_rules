#!/usr/bin/env python3
"""Report translation keys missing from or extra in each locale vs the base.

Usage: python3 -I check_keys.py [i18n_dir] [base_locale]
Defaults: lib/i18n, and base_locale from slang.yaml (else en).
Exits 1 if any locale is out of sync, 2 on bad input.
"""
import json
import pathlib
import re
import sys


def keys(node, prefix=""):
    out = set()
    for k, v in node.items():
        path = f"{prefix}.{k}" if prefix else k
        if isinstance(v, dict):
            out |= keys(v, path)
        else:
            out.add(path)
    return out


def slang_base(i18n_dir):
    """base_locale from slang.yaml in the project root (two levels up)."""
    for config in (i18n_dir.parent.parent / "slang.yaml", pathlib.Path("slang.yaml")):
        if config.is_file():
            match = re.search(r"^base_locale:\s*(\S+)", config.read_text(), re.M)
            if match:
                return match.group(1)
    return "en"


def main():
    root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "lib/i18n")
    base = sys.argv[2] if len(sys.argv) > 2 else slang_base(root)
    files = {p.name.split(".")[0]: p for p in root.glob("*.i18n.json")}
    if base not in files:
        print(f"base locale file {base}.i18n.json not found in {root}", file=sys.stderr)
        sys.exit(2)
    base_keys = keys(json.loads(files[base].read_text(encoding="utf-8")))
    bad = False
    for loc, path in sorted(files.items()):
        if loc == base:
            continue
        k = keys(json.loads(path.read_text(encoding="utf-8")))
        for label, diff in (("missing", base_keys - k), ("extra", k - base_keys)):
            for key in sorted(diff):
                bad = True
                print(f"{loc}: {label} {key}")
    if not bad:
        print(f"{len(files)} locales in sync ({len(base_keys)} keys)")
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
