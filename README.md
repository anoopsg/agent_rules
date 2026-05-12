# Agent Rules (Dart & Flutter) [WIP]

A canonical repository for AI agent behavioral blueprints. This serves as the single source of truth for generic, high-performance agent rules optimized for token efficiency and technical precision.

The goal of this project is to maintain a core set of rules that can be programmatically transformed into vendor-specific configurations (such as `.cursor` or `.agents` directories). This allows us to enforce consistent, expert-level behavior across different AI-assisted development environments and specific project architectures.

## Usage

```bash
# Generate specific agent rules (output directory is mandatory)
tool.sh -a .    # Antigravity only, current directory
tool.sh -c .    # Cursor only, current directory
tool.sh -A .    # All agents, current directory

# Custom output directory
tool.sh -A gen  # Generate all in 'gen' directory
```

## Output Structure

- **Cursor**: `.cursor/rules/**/*.mdc`
- **Antigravity**: `.agents/rules/*.md`
