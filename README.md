# Agent Rules & Skills [WIP]

> A vendor-agnostic repository of AI agent behavioral blueprints for Dart & Flutter projects.

Agent Rules & Skills is the single source of truth for expert-level agent configurations. It maintains a canonical set of rules and skills that can be programmatically compiled into vendor-specific configurations — keeping behavior consistent across all AI-assisted development environments.

---

## Why This Exists

Different AI coding agents (Cursor, Antigravity, etc.) each have their own configuration formats. Managing them independently leads to drift and inconsistency. This project solves that by:

- Authoring rules and skills **once**, in a clean Markdown format
- Compiling them to agent-specific formats via a CLI tool
- Separating **core** (always-on) content from **exclusive** (opt-in) content

---

## Repository Structure

```
agent_rules/
│
├── rules/                    # Core rules — always included
│   ├── core/                 # Fundamental agent behavior
│   ├── flutter/              # Flutter-specific rules
│   └── packages/             # Package-specific guidance
│
├── skills/                   # Core skills — always included
│   └── <skill-name>/
│       └── SKILL.md
│
├── exclusive/                # Opt-in content (Launchpad)
│   ├── rules/                # Launchpad rules
│   └── skills/               # Launchpad skills
│       └── <skill-name>/
│           └── SKILL.md
│
├── templates/                # Bootstrap files emitted with -B
│   ├── test/flutter_test_config.dart
│   ├── .github/workflows/{tests,goldens}.yml
│   ├── AGENTS.md
│   └── BOOTSTRAP.sh
│
├── .github/workflows/
│   └── test.yml              # Repo CI for generator smoke tests
│
├── bin/
│   ├── agentx.sh             # Main CLI entrypoint
│   └── _agents/
│       ├── antigravity.sh    # Antigravity generator
│       ├── cursor.sh         # Cursor generator
│       └── bootstrap.sh      # Bootstrap files generator (-B mode)
│
└── scripts/
    ├── release.sh            # Bundles into self-extracting agentx
    └── test.sh               # Smoke test (CI)
```

---

## Portable Installation

To run without cloning the repository, a single-file portable executable is available as a [GitHub Release](https://github.com/anoopsg/agent_rules/releases) asset.

This `agentx` binary is a self-extracting shell script that bundles the entire project (rules, skills, and logic). It is designed to be "download-and-run" with zero external dependencies.

```bash
# Download and make executable
curl -L https://github.com/anoopsg/agent_rules/releases/latest/download/agentx -o agentx
chmod +x agentx

# Run directly
./agentx -A .
```

---

## CLI Tool

You can use either the source script (`bin/agentx.sh`) or the portable release asset (`agentx`). Both share the same CLI interface.

### Usage

```bash
agentx [OPTIONS] <OUTPUT_DIR>
```

> Note: If using the source script, use `bin/agentx.sh`. If using the release asset, use `./agentx`.

`OUTPUT_DIR` is the base directory of your project. The tool creates the
appropriate hidden directories (`.agents/`, `.cursor/`) inside it.

### Options

| Flag | Long Form | Description |
|---|---|---|
| `-a` | `--antigravity` | Generate Antigravity rules & skills (`.agents/`) |
| `-c` | `--cursor` | Generate Cursor rules & skills (`.cursor/`) |
| `-A` | `--all` | Generate content for all supported agents |
| `-e` | `--exclusive` | Include opt-in content from `exclusive/` |
| `-B` | `--bootstrap` | Emit bootstrap files (test config, CI workflows, AGENTS.md, BOOTSTRAP.sh) **and** install dev deps via `flutter pub add`. Zero-touch setup. |
|      | `--no-auto-deps` | When `-B` is set, skip the `flutter pub add` step. Emit `BOOTSTRAP.sh` only. |
| `-v` | `--verbose` | Show detailed per-file processing logs |
| `-h` | `--help` | Show help and exit |

### Recommended: zero-touch setup

```bash
# Single command: rules, skills, exclusive content, bootstrap files,
# and dev deps. After this, the project is fully set up — the agent
# never asks the user to add alchemist/mocktail/fake_async on first task.
bin/agentx.sh -A -e -B .
```

### Examples

```bash
# Generate rules for a specific agent in the current directory
bin/agentx.sh -a .
bin/agentx.sh -c .

# Generate for all agents in a custom output directory
bin/agentx.sh -A ~/my-project

# Include exclusive skills and rules
bin/agentx.sh -A --exclusive .

# Bootstrap without modifying pubspec.yaml (BOOTSTRAP.sh emitted instead)
bin/agentx.sh -A -e -B --no-auto-deps .

# Full verbose run for all agents with exclusive content and bootstrap
bin/agentx.sh -A -e -B -v .
```

---

## Output Structure

Rules and skills are compiled into the following output directories:

| Agent | Rules | Skills |
|---|---|---|
| **Antigravity** | `.agents/rules/*.md` | `.agents/skills/*.md` |
| **Cursor** | `.cursor/rules/**/*.mdc` | `.cursor/skills/*.md` |

> Core rules under `rules/core/` are automatically annotated with
> `trigger: always_on` in the Antigravity output.
>
> Cursor output receives generated frontmatter: `rules/core/*` is
> `alwaysApply: true`, `rules/flutter/*` attaches to `**/*.dart`, and
> package or other rules remain agent-requested via description.

Generators abort on duplicate outputs. Keep skill directory names unique
across `skills/` and `exclusive/skills/`; avoid rule paths that compile
to the same destination, especially Antigravity paths that flatten `/`
to `_`.

### Bootstrap mode (`-B`) additionally emits

These files are materialized into the consumer project root with
**skip-if-exists** semantics, so user customizations survive re-runs:

| File | Purpose |
|---|---|
| `test/flutter_test_config.dart` | Pins golden-test determinism (locale, text scale, shadow rendering) — required by the `golden-sandbox` skill |
| `.github/workflows/tests.yml` | CI gate enforcing the `testable-code` skill |
| `.github/workflows/goldens.yml` | CI gate enforcing the `golden-sandbox` skill |
| `AGENTS.md` | Project-root primer that points agents at the active rules and the disclosure contract |
| `BOOTSTRAP.sh` | Always regenerated. Idempotent dep installer. Run once, or let the agent run it on first task. |

When `--auto-deps` is in effect (the default with `-B`), `agentx`
also runs `BOOTSTRAP.sh` at the end of generation, which executes
`flutter pub add --dev alchemist mocktail fake_async`. If `flutter`
is not on `PATH` or `pubspec.yaml` is missing, this step is skipped
gracefully and the script remains for the user to run later.

---

## Authoring Content

### Rules

Rules are plain Markdown files placed under `rules/` (core) or
`exclusive/rules/` (Launchpad). Organize them into topic subdirectories.

```
rules/
└── flutter/
    └── performance.md   # A core rule document
```

### Skills

Skills are directories containing a single `SKILL.md` file. The directory
name becomes the skill identifier in the output.

```
skills/
└── <skill-name>/
    └── SKILL.md         # Core skill instructions

exclusive/skills/
└── create-client/
    └── SKILL.md         # Launchpad skill
```

Skill identifiers must be unique across core and exclusive content. A
duplicate name is treated as a configuration error instead of silently
overwriting output.

---

## Verification

The repository includes a smoke test used by CI:

```bash
bash scripts/test.sh
```

It generates Antigravity and Cursor outputs, checks generated
frontmatter, verifies bootstrap files, and guards against duplicate
skill names.

---

## Exclusive Content (Launchpad)

The `exclusive/` directory is reserved for content tailored specifically for Launchpad.

This includes:
- **`exclusive/skills/`** — implementation patterns specific to the Launchpad architecture.
- **`exclusive/rules/`** — behavioral rules that assume Launchpad conventions.

This content is opt-in via the `--exclusive` flag, allowing the repository to remain flexible for general Dart & Flutter projects while providing specialized support for Launchpad.
