#!/usr/bin/env python3
"""Compares contracts/openapi.json with the ApiClient contract, the adapter
and its mock routes. Usage: python3 -I api_coverage.py [project_dir]
Exit 1 if anything is missing, extra or marked TODO(dev); 2 on bad input."""
import json
import pathlib
import re
import sys

METHODS = {"get", "post", "put", "patch", "delete"}


def dart_files(root, marker):
    """Dart files under lib/ whose source contains marker."""
    return [p for p in (root / "lib").rglob("*.dart")
            if marker in p.read_text(encoding="utf-8")]


def one(root, marker):
    found = dart_files(root, marker)
    if len(found) != 1:
        print(f"expected one file with '{marker}', found {len(found)}", file=sys.stderr)
        sys.exit(2)
    return found[0]


def main():
    root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else ".")
    spec_file = root / "contracts" / "openapi.json"
    if not spec_file.is_file():
        print(f"not found: {spec_file}", file=sys.stderr)
        return 2
    spec = json.loads(spec_file.read_text(encoding="utf-8"))
    ops = [(m.upper(), path, op.get("operationId", ""))
           for path, item in spec.get("paths", {}).items()
           for m, op in item.items() if m in METHODS]

    contract = one(root, "abstract interface class ApiClient").read_text()
    client_methods = set(re.findall(r"Future<[^;{]*?>\s+(\w+)\s*\(", contract))

    adapter_dir = one(root, "implements ApiClient").parent
    sources = {p: p.read_text(encoding="utf-8") for p in adapter_dir.rglob("*.dart")
               if not p.name.endswith((".g.dart", ".chopper.dart", ".mapper.dart"))}
    mock_src = "".join(s for s in sources.values() if "extends http.BaseClient" in s)
    mock_routes = set(re.findall(r"'(GET|POST|PUT|PATCH|DELETE) (/[^']*)'", mock_src))
    adapter_paths = {p for s in sources.values() if "extends http.BaseClient" not in s
                     for p in re.findall(r"'(/[^'\s]*)'", s)}

    issues = 0
    print("| Method | Path | operationId | ApiClient | Adapter | Mock |")
    print("|---|---|---|---|---|---|")
    for method, path, op_id in ops:
        in_adapter = path in adapter_paths
        mocked = (method, path) in mock_routes
        # No ApiClient method is fine for adapter-internal calls (token refresh).
        client = "yes" if op_id in client_methods else "internal" if in_adapter else "**no**"
        issues += not (in_adapter and mocked)
        print(f"| {method} | {path} | {op_id} | {client} "
              f"| {'yes' if in_adapter else '**no**'} | {'yes' if mocked else '**no**'} |")

    spec_ids = {op_id for _, _, op_id in ops}
    for name in sorted(client_methods - spec_ids - {"dispose"}):
        print(f"ApiClient.{name} has no operationId in the spec")
        issues += 1
    spec_routes = {(m, p) for m, p, _ in ops}
    for method, path in sorted(mock_routes - spec_routes):
        print(f"mock route {method} {path} is not in the spec")
        issues += 1
    for path, src in sources.items():
        for n, line in enumerate(src.splitlines(), 1):
            if "TODO(dev)" in line:
                print(f"{path.relative_to(root)}:{n}: {line.strip()}")
                issues += 1
    return 1 if issues else 0


if __name__ == "__main__":
    sys.exit(main())
