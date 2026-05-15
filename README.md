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
├── bin/
│   ├── tool.sh               # Main CLI entrypoint
│   └── _agents/
│       ├── antigravity.sh    # Antigravity generator
│       └── cursor.sh         # Cursor generator
│
└── docs/                     # Additional documentation
```

---

## CLI Tool

Use `bin/tool.sh` to compile rules and skills into agent-specific directories.

### Usage

```bash
bin/tool.sh [OPTIONS] <OUTPUT_DIR>
```

`OUTPUT_DIR` is the base directory of your project. The tool creates the
appropriate hidden directories (`.agents/`, `.cursor/`) inside it.

### Options

| Flag | Long Form | Description |
|---|---|---|
| `-a` | `--antigravity` | Generate Antigravity rules & skills (`.agents/`) |
| `-c` | `--cursor` | Generate Cursor rules & skills (`.cursor/`) |
| `-A` | `--all` | Generate content for all supported agents |
| `-e` | `--exclusive` | Include opt-in content from `exclusive/` |
| `-v` | `--verbose` | Show detailed per-file processing logs |
| `-h` | `--help` | Show help and exit |

### Examples

```bash
# Generate rules for a specific agent in the current directory
bin/tool.sh -a .
bin/tool.sh -c .

# Generate for all agents in a custom output directory
bin/tool.sh -A ~/my-project

# Include exclusive skills and rules
bin/tool.sh -A --exclusive .

# Full verbose run for all agents with exclusive content
bin/tool.sh -A -e -v .
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

---

## Exclusive Content (Launchpad)

The `exclusive/` directory is reserved for content tailored specifically for Launchpad.

This includes:
- **`exclusive/skills/`** — implementation patterns specific to the Launchpad architecture.
- **`exclusive/rules/`** — behavioral rules that assume Launchpad conventions.

This content is opt-in via the `--exclusive` flag, allowing the repository to remain flexible for general Dart & Flutter projects while providing specialized support for Launchpad.
