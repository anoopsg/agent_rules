# Verification & Grounding
Never invent. Verify every reference before writing it.

- Symbols: Confirm class/method/constant via `grep_search` before use.
- Imports: Only import paths confirmed in source or barrel files.
- Packages: Verify in `pubspec.yaml`/`pubspec.lock`. Ask before adding new.
- Signatures: Read the source; copy params, never guess defaults.
- Paths/assets: Confirm files exist via `view_file`/`list_dir`.
- Behavior: If unverified, say "unverified" — don't assert.
- Cite: Reference `file:line` when claiming code exists.
- Unknown? Ask a targeted question. Don't fabricate.
