# archmap-plugin

Claude Code plugin that generates interactive 2D codebase architecture maps with pan/zoom, module inspector, dependency graphs, and switchable themes.

## Install

```bash
claude plugin install /path/to/archmap-plugin --scope user
```

Or test locally:

```bash
claude --plugin-dir /path/to/archmap-plugin
```

## Usage

```
/archmap              # Full map of current project
/archmap <path>       # Map a specific subdirectory
/archmap --refresh    # Regenerate map (re-explore)
```

## What it produces

- `docs/architecture.html` — Interactive canvas-based visualization
- `docs/architecture-map.md` — Markdown export for version control

## Features

- Canvas-based rendering (no external dependencies)
- 4 themes: Dark, Light, Claude, OpenAI
- Click modules to inspect types, functions, dependencies
- Drag to pan, scroll to zoom
- Export to Markdown from the UI
- Automatic data flow pipeline detection
