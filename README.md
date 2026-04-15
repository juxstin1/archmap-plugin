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

- Claude Code (primary target) — or any markdown-skill-aware runtime (see Runtime support below)
- `bash` (git-bash or WSL on Windows)
- `jq` recommended for full `.archmap.json` parsing; hooks fall back gracefully without it

### Runtime support

Archmap was designed as a Claude Code plugin, but every `commands/*.md` file opens with a **Runtime adapter** section that keeps behavior identical under other markdown-skill-aware runtimes.

| Runtime | `archmap:*` commands | `architecture` skill | Hooks |
|---|---|---|---|
| **Claude Code** | Native (`/archmap:<cmd>`) | Native auto-activation | SessionStart + PostToolUse |
| **OpenAI Codex CLI** | `~/.codex/skills/archmap-<cmd>/SKILL.md` → invoke as `$archmap-<cmd>` | `~/.codex/skills/archmap/SKILL.md` | Not portable (different hook format) |
| **Other skill-aware runtimes** | Follow the Runtime adapter rules in each command file | SKILL.md is standard markdown | — |

**What the Runtime adapter handles:**

1. **Template path** — resolves `archmap-template.html` via `${ARCHMAP_TEMPLATE_PATH}` → `${ARCHMAP_ROOT}/templates/archmap-template.html` → `${CLAUDE_PLUGIN_ROOT}/templates/archmap-template.html`, first hit wins.
2. **Agent prompts** — resolves `agents/<name>.md` via `${ARCHMAP_ROOT}/agents/` → `${CLAUDE_PLUGIN_ROOT}/agents/`, first hit wins. Used only when the runtime has no `Task` subagent (see rule 3).
3. **Agent dispatch** — if the runtime has a `Task` tool with `subagent_type` support (Claude Code), subagents spawn as `archmap:archmap-explorer` / `archmap:archmap-repair-agent`. Otherwise the command reads the agent prompt (via rule 2) and executes it inline in the current session.

`${ARCHMAP_ROOT}` points at the plugin's installation directory (where `templates/`, `agents/`, and `commands/` all live). Claude Code users don't need it — the loader sets `${CLAUDE_PLUGIN_ROOT}` automatically. Other runtimes set `${ARCHMAP_ROOT}` once, at install time.

**Codex install (recommended flow):**

```bash
# 1. Clone the plugin once, to a stable location
git clone https://github.com/juxstin1/archmap-plugin.git ~/.archmap-plugin

# 2. Tell the adapter where the plugin lives (add to your shell rc file to make it persistent)
export ARCHMAP_ROOT="$HOME/.archmap-plugin"

# 3. Symlink each command file into ~/.codex/skills/
for cmd in generate diff focus repair snapshot; do
  mkdir -p "$HOME/.codex/skills/archmap-$cmd"
  ln -sf "$ARCHMAP_ROOT/commands/$cmd.md" "$HOME/.codex/skills/archmap-$cmd/SKILL.md"
done

# 4. Symlink the architecture skill
mkdir -p "$HOME/.codex/skills/archmap"
ln -sf "$ARCHMAP_ROOT/skills/architecture/SKILL.md" "$HOME/.codex/skills/archmap/SKILL.md"
```

With `${ARCHMAP_ROOT}` exported, both the template (rule 1) and the agent prompts (rule 2) resolve correctly regardless of where the individual SKILL.md files end up. Symlinks keep the Codex install in sync with `git pull` in the plugin directory.

## Quickstart

1. Open Claude Code in any repo: `cd your-project && claude`
2. Run `/archmap:generate` — a few seconds later, `docs/architecture.html` opens in your browser
3. Edit some code, then run `/archmap:repair` to surgically patch just what changed
4. Run `/archmap:diff` any time you want a drift report without modifying the map

## Commands

| Command | What it does |
|---|---|
| `/archmap:generate` | Generate a full architecture map from scratch |
| `/archmap:generate <path>` | Map a specific subdirectory or project |
| `/archmap:generate --refresh` | Regenerate map (full re-explore) |
| `/archmap:repair` | Detect and fix stale/broken maps surgically |
| `/archmap:repair --layout` | Fix only layout issues (overlaps, spacing) |
| `/archmap:repair --details` | Fix only missing module details |
| `/archmap:focus <module>` | Deep-dive and repair a specific module |
| `/archmap:diff` | Show architectural drift since last map |
| `/archmap:diff --output docs/` | Write drift report to file |
| `/archmap:snapshot` | Save a version snapshot to the map's history |
| `/archmap:snapshot --name v1.0 --note "..."` | Named snapshot with custom note |

## How it works

### Generate (`/archmap:generate`)
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
  "$schema": "https://raw.githubusercontent.com/juxstin1/archmap-plugin/main/schemas/archmap.schema.json",
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

The `$schema` field is optional — adding it gives you **autocomplete, validation, and hover docs** in editors that support JSON Schema (VS Code, JetBrains IDEs, Helix, Zed).

| Field | Type | Default | Purpose |
|---|---|---|---|
| `exclude` | `string[]` | `[]` | Paths or globs to skip during exploration (e.g. `node_modules`, `dist`, `vendor`). |
| `tiers` | `object` | `{}` | Override the auto-detected tier for specific path prefixes. Keys are path prefixes, values are tier keys (see tier list below). |
| `pinned` | `string[]` | `[]` | Module IDs that are never removed or re-tiered by `/archmap:repair`. |
| `output.html` | `string` | `docs/architecture.html` | Custom HTML output path. Hooks read this to watch the right file. |
| `output.markdown` | `string` | `docs/architecture-map.md` | Custom markdown output path. |
| `theme` | `string` | `dark` | Default theme. One of: `dark`, `light`, `claude`, `openai`. |
| `hooks.sessionStart` | `boolean` | `true` | Set to `false` to silence the session-start staleness nudge. |
| `layout.respectOverrides` | `boolean` | `true` | When `true`, generation reads `.archmap/layout.json` and preserves your manually-arranged module positions. |
| `layout.overridePath` | `string` | `.archmap/layout.json` | Path the generator reads for user-arranged positions. Produced by the Edit mode's "Save → Download layout.json" button in the HTML UI. |
| `history.enabled` | `boolean` | `true` | Master switch for version history. When `false`, `/archmap:snapshot` errors out. |
| `history.autoSnapshotOnRepair` | `boolean` | `true` | When `true`, `/archmap:repair` auto-snapshots before mutating. |
| `history.autoSnapshotOnFocus` | `boolean` | `true` | When `true`, `/archmap:focus` auto-snapshots before mutating. |
| `history.maxInlineSnapshots` | `integer` | `50` | Number of most-recent snapshots kept inline in the HTML before older ones spill to sibling JSON files. |
| `history.spillPath` | `string` | `.archmap/snapshots` | Directory for overflow snapshot files. |

**Available tier keys:** `entry`, `frontend`, `ir`, `codegen`, `runtime`, `lint`, `driver`, `data`, `api`, `ui`, `infra`, `util`, `test`, `config`.

### Arranging the map manually

The HTML canvas has an **Edit** button (shortcut: `E`) that lets you drag modules to reposition them. Positions are auto-saved to your browser's localStorage per project. To share your layout with teammates or bake it permanently:

1. Click **Edit** → rearrange modules → click **Save** when the button appears
2. Pick **Download `layout.json`** in the modal → commit the file to `.archmap/layout.json` in your project root
3. Next time anyone runs `/archmap:generate` or `/archmap:repair`, the generator respects your positions

Drags snap to a 10 px grid. Hold `Shift` while dragging to bypass the snap for fine-tuning. The **Reset Layout** button restores the generator's default positions.

## Visualization features

- Pan, zoom, click-to-inspect module nodes
- **Drag-to-reposition** in Edit mode, with localStorage persistence + shareable `layout.json`
- Dependency edge graph with curved Bezier arrows
- Sidebar inspector with types, functions, imports, notes
- Data flow pipeline visualization
- Complexity bar per module (based on line count)
- 4 theme presets: Dark, Light, Claude, OpenAI
- **One-click Export** — PNG of the full graph + markdown referencing it, ready to paste anywhere

## Repository layout

```text
archmap-plugin/
|- .claude-plugin/
|  |- plugin.json
|  `- marketplace.json
|- commands/
|  |- generate.md
|  |- repair.md
|  |- focus.md
|  |- diff.md
|  `- snapshot.md
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
| `/archmap:generate` produced a broken map | `rm docs/architecture.html && /archmap:generate` — regen from scratch |
| SessionStart nudge is too chatty | Set `hooks.sessionStart: false` in `.archmap.json` |
| `docs/` conflicts with GitHub Pages | Change `output.html` to a different path in `.archmap.json` |
| Hook warnings on Windows | Ensure bash is available (git-bash or WSL) |

## Contributing & feedback

- Bugs & feature requests: [open an issue](https://github.com/juxstin1/archmap-plugin/issues/new/choose)
- Discussions: [GitHub Discussions](https://github.com/juxstin1/archmap-plugin/discussions)
- See [CONTRIBUTING.md](./CONTRIBUTING.md) before opening a PR
- Security reports: see [SECURITY.md](./SECURITY.md)

![archmap footer](https://capsule-render.vercel.app/api?type=rect&height=120&color=0:0b1220,100:0f172a&text=Map%20it.%20Repair%20it.%20Ship%20it.&fontColor=e2e8f0&fontSize=28&animation=fadeIn)
