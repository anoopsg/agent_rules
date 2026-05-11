# Agent Rules [WIP]

A canonical repository for AI agent behavioral blueprints. This serves as the single source of truth for generic, high-performance agent rules optimized for token efficiency and technical precision.

The goal of this project is to maintain a core set of rules that can be programmatically transformed into vendor-specific configurations (such as `.cursor` or `.agents` directories). This allows us to enforce consistent, expert-level behavior across different AI-assisted development environments and specific project architectures.

## Usage

```bash
# Interactive menu (arrow keys to select)
./bin/tool.sh

# Generate specific agent rules
./bin/tool.sh -a    # Antigravity only
./bin/tool.sh -c    # Cursor only

# Custom output directory
./bin/tool.sh -o gen -a
```

## Output Structure

- **Cursor**: `.cursor/rules/**/*.mdc`
- **Antigravity**: `.agents/rules/*.md`


