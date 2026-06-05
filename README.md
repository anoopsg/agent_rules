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
├── src/                      # Source directory containing all rules & skills
│   ├── rules/                # Core rules — always included
│   │   ├── core/             # Fundamental agent behavior
│   │   ├── flutter/          # Flutter-specific rules
│   │   └── packages/         # Package-specific guidance
│   │
│   ├── skills/               # Core skills — always included
│   │   └── <skill-name>/
│   │       └── SKILL.md
│   │
│   └── exclusive/            # Opt-in content (Launchpad)
│       ├── rules/            # Launchpad rules
│       └── skills/           # Launchpad skills
│           └── <skill-name>/
│               └── SKILL.md
│
└── bin/
    ├── agentx.sh             # Main CLI entrypoint
    └── _agents/
        ├── antigravity.sh    # Antigravity generator
        └── cursor.sh         # Cursor generator
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

Both the source script (`bin/agentx.sh`) and the portable release asset
(`agentx`) share the same CLI interface.

> [!IMPORTANT]
> For development/contribution, use the source script (`bin/agentx.sh`).
> Otherwise, always use the released bundle single-file CLI (`agentx`).

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
| `-u` | `--update` | Update agentx binary to the latest release |
| `-v` | `--version` | Show the version of agentx and exit |
| `-h` | `--help` | Show help and exit |

### Examples

```bash
# Generate rules for a specific agent in the current directory
bin/agentx.sh -a .
bin/agentx.sh -c .

# Generate for all agents in a custom output directory
bin/agentx.sh -A ~/my-project

# Include exclusive skills and rules
bin/agentx.sh -A --exclusive .

# Update the bundled agentx binary to the latest release
./agentx --update
```

---

## Testing & Development

```bash
bin/agentx.sh -A -e gen
```

---

## Output Structure

Rules and skills are compiled into the following output directories:

| Agent | Rules | Skills |
|---|---|---|
| **Antigravity** | `.agents/rules/*.md` | `.agents/skills/*.md` |
| **Cursor** | `.cursor/rules/**/*.mdc` | `.cursor/skills/*.md` |

> Core rules under `src/rules/core/` are automatically annotated with
> `trigger: always_on` in the Antigravity output.

---

## Authoring Content

### Rules

Rules are plain Markdown files placed under `src/rules/` (core) or
`src/exclusive/rules/` (Launchpad). Organize them into topic subdirectories.

```
src/rules/
└── flutter/
    └── performance.md   # A core rule document
```

### Skills

Skills are directories containing a single `SKILL.md` file. The directory
name becomes the skill identifier in the output.

```
src/skills/
└── <skill-name>/
    └── SKILL.md         # Core skill instructions

src/exclusive/skills/
└── create-client/
    └── SKILL.md         # Launchpad skill
```

---

## Exclusive Content (Launchpad)

The `src/exclusive/` directory is reserved for content tailored specifically for Launchpad.

This includes:
- **`src/exclusive/skills/`** — implementation patterns specific to the Launchpad architecture.
- **`src/exclusive/rules/`** — behavioral rules that assume Launchpad conventions.

This content is opt-in via the `--exclusive` flag, allowing the repository to remain flexible for general Dart & Flutter projects while providing specialized support for Launchpad.
