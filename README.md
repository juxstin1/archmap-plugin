![archmap banner](https://capsule-render.vercel.app/api?type=waving&height=220&color=0:0f172a,35:1d4ed8,100:06b6d4&text=ARCHMAP%20PLUGIN&fontColor=ffffff&fontSize=54&animation=fadeIn&fontAlignY=38&desc=Interactive%20codebase%20architecture%20maps%20for%20Claude%20Code&descAlignY=58&descSize=18)

<p align="center">
  <strong>Turn any codebase into an interactive architecture map.</strong><br/>
  Analyze modules, dependencies, and data flow in seconds with a polished canvas UI.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Claude%20Code-Plugin-111827?style=for-the-badge" alt="Claude Code Plugin" />
  <img src="https://img.shields.io/badge/Renderer-HTML5%20Canvas-0ea5e9?style=for-the-badge" alt="Canvas Renderer" />
  <img src="https://img.shields.io/badge/Output-HTML%20%2B%20Markdown-16a34a?style=for-the-badge" alt="HTML and Markdown output" />
  <img src="https://img.shields.io/badge/Themes-4%20Presets-f59e0b?style=for-the-badge" alt="4 themes" />
</p>

## What is Archmap?

`archmap-plugin` is a Claude Code plugin that generates:

- `docs/architecture.html` - interactive architecture graph
- `docs/architecture-map.md` - versionable architecture documentation

It is built for real code navigation, not static diagrams. You can pan, zoom, inspect modules, trace edges, switch themes, and export docs directly from the UI.

## Install

```bash
claude plugin install /path/to/archmap-plugin --scope user
```

Local test mode:

```bash
claude --plugin-dir /path/to/archmap-plugin
```

## Quick start

```bash
/archmap
/archmap <path>
/archmap --refresh
```

## Product highlights

- Deep project exploration with a dedicated plugin subagent (`archmap:archmap-explorer`)
- Module nodes with file size, role, key types, key functions, and internal imports
- Dependency edge graph with layer/tier-aware layout
- Data flow pipeline sidebar for input-to-output reasoning
- Built-in theme switcher: Dark, Light, Claude, OpenAI
- Self-contained HTML output (no CDN, no runtime dependencies)
- Automatic Markdown export for documentation and PR reviews

## Output files

| File | Purpose |
|---|---|
| `docs/architecture.html` | Interactive map for visual exploration |
| `docs/architecture-map.md` | Structured architecture report for version control |

## Typical workflow

1. Run `/archmap` at repo root.
2. Review `docs/architecture.html` and inspect hotspots.
3. Commit `docs/architecture-map.md` alongside code changes to keep architecture docs current.

## Repository layout

```text
archmap-plugin/
|- .claude-plugin/plugin.json
|- commands/archmap.md
|- agents/archmap-explorer.md
|- templates/archmap-template.html
```

## Why teams use it

- Faster onboarding for new contributors
- Clearer system-level reviews in pull requests
- Better visibility into coupling and dependency spread
- Living architecture docs that stay close to code

![archmap footer](https://capsule-render.vercel.app/api?type=rect&height=120&color=0:0b1220,100:0f172a&text=Map%20it.%20Inspect%20it.%20Ship%20it.&fontColor=e2e8f0&fontSize=28&animation=fadeIn)
