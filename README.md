![archmap banner](https://capsule-render.vercel.app/api?type=waving&height=220&color=0:0f172a,35:1d4ed8,100:06b6d4&text=ARCHMAP&fontColor=ffffff&fontSize=54&animation=fadeIn&fontAlignY=38&desc=Interactive%20codebase%20architecture%20platform%20for%20Claude%20Code&descAlignY=58&descSize=18)

<p align="center">
  <strong>Generate, repair, diff, and explore codebase architecture maps.</strong><br/>
  Interactive canvas visualization with live staleness detection and contextual intelligence.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Claude%20Code-Plugin-111827?style=for-the-badge" alt="Claude Code Plugin" />
  <img src="https://img.shields.io/badge/Version-1.0.0-0ea5e9?style=for-the-badge" alt="v1.0.0" />
  <img src="https://img.shields.io/badge/Renderer-HTML5%20Canvas-0ea5e9?style=for-the-badge" alt="Canvas Renderer" />
  <img src="https://img.shields.io/badge/Themes-4%20Presets-f59e0b?style=for-the-badge" alt="4 themes" />
</p>

<p align="center">
  <a href="https://juxstin1.github.io/archmap-plugin/"><strong>Live site & demo →</strong></a>
</p>

## What is Archmap?

A Claude Code plugin that turns any codebase into an interactive architecture map. Pan, zoom, inspect modules, trace dependencies, switch themes, and keep your architecture docs up to date — automatically.

**Output:**
- `docs/architecture.html` — interactive canvas visualization
- `docs/architecture-map.md` — versionable architecture documentation

## Install

Install from the marketplace (recommended) inside Claude Code:

```text
/plugin marketplace add juxstin1/archmap-plugin
/plugin install archmap@archmap
```

The first command registers this repository as a plugin marketplace; the second installs the `archmap` plugin from it. Both commands are Claude Code slash commands — type them into the Claude Code interface, not a shell.

### Local development

Clone the repo and point Claude Code at your working copy:

```bash
git clone https://github.com/juxstin1/archmap-plugin.git
cd archmap-plugin
claude --plugin-dir "$(pwd)"
```

### Requirements

- Claude Code
- `bash` (git-bash or WSL on Windows)
- `jq` recommended for full `.archmap.json` parsing; hooks fall back gracefully without it

## Quickstart

1. Open Claude Code in any repo: `cd your-project && claude`
2. Run `/archmap` — a few seconds later, `docs/architecture.html` opens in your browser
3. Edit some code, then run `/archmap:repair` to surgically patch just what changed
4. Run `/archmap:diff` any time you want a drift report without modifying the map

## Commands

| Command | What it does |
|---|---|
| `/archmap` | Generate a full architecture map from scratch |
| `/archmap <path>` | Map a specific subdirectory or project |
| `/archmap --refresh` | Regenerate map (full re-explore) |
| `/archmap:repair` | Detect and fix stale/broken maps surgically |
| `/archmap:repair --layout` | Fix only layout issues (overlaps, spacing) |
| `/archmap:repair --details` | Fix only missing module details |
| `/archmap:focus <module>` | Deep-dive and repair a specific module |
| `/archmap:diff` | Show architectural drift since last map |
| `/archmap:diff --output docs/` | Write drift report to file |

## How it works

### Generate (`/archmap`)
Dispatches an explorer agent to deeply analyze the codebase, builds a tier-based layout with module nodes and dependency edges, renders to a self-contained HTML canvas, and exports structured markdown.

### Repair (`/archmap:repair`)
Reads the existing map's embedded data, dispatches a targeted repair agent to scan for drift, then surgically patches — stale modules, broken edges, layout overlaps, missing details — without regenerating from scratch.

### Focus (`/archmap:focus`)
Same repair intelligence, scoped to one module. Re-explores that module deeply, updates its types/functions/edges, and patches the map in-place.

### Diff (`/archmap:diff`)
Read-only comparison between the current codebase and existing map. Shows added/removed modules, new/broken dependencies, tier changes. Outputs a verdict: current, slightly stale, or needs repair.

## Smart features

- **Architecture skill** — auto-activates when you ask "how does this codebase work?" and answers from existing map data
- **SessionStart hook** — detects unmapped or stale repos when you start a session
- **PostToolUse hook** — flags when you edit files that are part of a mapped module
- **Per-project config** — `.archmap.json` for exclude paths, tier overrides, pinned modules, output locations

## Configuration

Create `.archmap.json` in your project root (optional — every field has a sensible default):

```json
{
  "exclude": ["node_modules", "dist", ".git"],
  "tiers": { "src/api/": "api", "src/models/": "data" },
  "pinned": ["config-module"],
  "output": {
    "html": "docs/architecture.html",
    "markdown": "docs/architecture-map.md"
  },
  "theme": "dark",
  "hooks": {
    "sessionStart": false
  }
}
```

| Field | Type | Default | Purpose |
|---|---|---|---|
| `exclude` | `string[]` | `[]` | Paths or globs to skip during exploration (e.g. `node_modules`, `dist`, `vendor`). |
| `tiers` | `object` | `{}` | Override the auto-detected tier for specific path prefixes. Keys are path prefixes, values are tier keys (see tier list below). |
| `pinned` | `string[]` | `[]` | Module IDs that are never removed or re-tiered by `/archmap:repair`. |
| `output.html` | `string` | `docs/architecture.html` | Custom HTML output path. Hooks read this to watch the right file. |
| `output.markdown` | `string` | `docs/architecture-map.md` | Custom markdown output path. |
| `theme` | `string` | `dark` | Default theme. One of: `dark`, `light`, `claude`, `openai`. |
| `hooks.sessionStart` | `boolean` | `true` | Set to `false` to silence the session-start staleness nudge. |

**Available tier keys:** `entry`, `frontend`, `ir`, `codegen`, `runtime`, `lint`, `driver`, `data`, `api`, `ui`, `infra`, `util`, `test`, `config`.

## Visualization features

- Pan, zoom, click-to-inspect module nodes
- Dependency edge graph with curved Bezier arrows
- Sidebar inspector with types, functions, imports, notes
- Data flow pipeline visualization
- Complexity bar per module (based on line count)
- 4 theme presets: Dark, Light, Claude, OpenAI
- Markdown export from the UI (Export MD button)

## Repository layout

```text
archmap-plugin/
|- .claude-plugin/
|  |- plugin.json
|  `- marketplace.json
|- commands/
|  |- archmap.md
|  |- archmap-repair.md
|  |- archmap-focus.md
|  `- archmap-diff.md
|- agents/
|  |- archmap-explorer.md
|  `- archmap-repair-agent.md
|- skills/architecture/SKILL.md
|- hooks/
|  |- hooks.json
|  `- scripts/
|     |- detect-unmapped.sh
|     `- flag-stale-modules.sh
|- templates/archmap-template.html
|- CHANGELOG.md
|- CONTRIBUTING.md
|- SECURITY.md
|- LICENSE
`- README.md
```

## Why teams use it

- Faster onboarding for new contributors
- Clearer system-level reviews in pull requests
- Better visibility into coupling and dependency spread
- Living architecture docs that stay close to code
- Automatic drift detection keeps maps honest

## Troubleshooting

| Symptom | Fix |
|---|---|
| `/archmap` produced a broken map | `rm docs/architecture.html && /archmap` — regen from scratch |
| SessionStart nudge is too chatty | Set `hooks.sessionStart: false` in `.archmap.json` |
| `docs/` conflicts with GitHub Pages | Change `output.html` to a different path in `.archmap.json` |
| Hook warnings on Windows | Ensure bash is available (git-bash or WSL) |

## Contributing & feedback

- Bugs & feature requests: [open an issue](https://github.com/juxstin1/archmap-plugin/issues/new/choose)
- Discussions: [GitHub Discussions](https://github.com/juxstin1/archmap-plugin/discussions)
- See [CONTRIBUTING.md](./CONTRIBUTING.md) before opening a PR
- Security reports: see [SECURITY.md](./SECURITY.md)

![archmap footer](https://capsule-render.vercel.app/api?type=rect&height=120&color=0:0b1220,100:0f172a&text=Map%20it.%20Repair%20it.%20Ship%20it.&fontColor=e2e8f0&fontSize=28&animation=fadeIn)
