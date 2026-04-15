---
description: Generate an interactive 2D codebase architecture map and markdown export.
argument-hint: "[path] [--refresh]"
---

# /archmap:generate — Interactive Codebase Architecture Map

Generate an interactive 2D web visualization of any codebase's architecture with pan/zoom, module inspector, dependency edges, and 4 switchable themes (Dark, Light, Claude, OpenAI).

## Usage

```
/archmap:generate              # Full map of current project
/archmap:generate <path>       # Map a specific subdirectory or project
/archmap:generate --refresh    # Regenerate map for current project (re-explore)
```

## Runtime adapter

This command was originally written for Claude Code. The phases below are runtime-agnostic when the agent follows these two rules — Claude Code, Codex (via `~/.codex/skills/`), and any other markdown-skill-aware runtime then execute identically.

**1. Template path resolution.** Wherever a phase says *"read the template"* or references `${CLAUDE_PLUGIN_ROOT}/templates/archmap-template.html`, resolve the template in this order and use the first hit:

  a. `${ARCHMAP_TEMPLATE_PATH}` — direct path override
  b. `${ARCHMAP_ROOT}/templates/archmap-template.html` — plugin-root override (recommended for non-Claude-Code runtimes; set `${ARCHMAP_ROOT}` once to the directory containing this plugin's `templates/`, `agents/`, `commands/`)
  c. `${CLAUDE_PLUGIN_ROOT}/templates/archmap-template.html` — Claude Code fallback (the `${CLAUDE_PLUGIN_ROOT}` env var is set only by Claude Code's plugin loader)

**2. Agent dispatch.** Wherever a phase says *"Dispatch `archmap:archmap-explorer` (or `archmap-repair-agent`) via the Task tool"*:

  a. If your runtime has a `Task` tool with `subagent_type` support (Claude Code): dispatch as specified.
  b. Otherwise (Codex, etc.): read the agent prompt file and execute it inline in the current session with the inputs the phase would have passed. Resolve the agent prompt path in this order, first hit wins: `${ARCHMAP_ROOT}/agents/archmap-explorer.md` (or `archmap-repair-agent.md`) → `${CLAUDE_PLUGIN_ROOT}/agents/<name>.md`.

## Execution directives

These rules apply to all phases below. They exist so the agent spends model cycles on judgment, not on re-deriving how to enumerate a filesystem or parse this template.

1. **Existence checks: batch all artifact paths into ONE `Test-Path`/`test` call.** Never use `Get-ChildItem docs` or `ls docs` to check if a file exists — those error loudly on missing directories and waste a round-trip on follow-up probes.

   - Windows: `Test-Path docs/architecture-map.md, docs/architecture.html, .archmap.json, .archmap/layout.json`
   - POSIX: `for f in docs/architecture-map.md docs/architecture.html .archmap.json .archmap/layout.json; do [ -e "$f" ] && echo "$f"; done`

2. **HTML map extraction: read `docs/architecture.html` ONCE, in full, then extract all `const` arrays in-memory via regex.** Do not run `Select-String` (or `grep`) once per variable. One full read + one regex pass is correct; seven sequential greps of the same file are not. Variables to extract in a single pass: `const modules`, `const edges`, `const tierLabels`, `const pipelineSteps`, `const legendItems`, `const layoutOverrides`, `const history`.

3. **Independent reads run in parallel.** When a phase lists reads that do not depend on each other (e.g., loading `.archmap.json` and `.archmap/layout.json`), issue them as concurrent tool calls.

4. **Probe once per phase.** If the `Test-Path` batch in rule 1 already told you a file exists, don't re-check later.

## Behavior

When user runs `/archmap:generate`:

### Phase 0: Load Configuration

Before exploring, check for `.archmap.json` in the project root (or target path root). If present, load:

- **`exclude`** — array of paths/patterns to skip during exploration (e.g., `["node_modules", "dist", ".git", "vendor"]`)
- **`layout`** — object; `{"respectOverrides": true}` (default) means generation reads `.archmap/layout.json` (or the path in `layout.overridePath`) and preserves user-arranged positions.
- **`tiers`** — object mapping path prefixes to tier assignments (e.g., `{"src/api/": "api", "src/models/": "data"}`)
- **`pinned`** — array of module IDs that should never be removed or re-tiered
- **`output.html`** — custom output path for HTML (default: `docs/architecture.html`)
- **`output.markdown`** — custom output path for markdown (default: `docs/architecture-map.md`)
- **`theme`** — default theme to apply (default: `dark`)

If no `.archmap.json` exists, use defaults. Pass exclude paths and tier overrides to the explorer agent.

Also load **`.archmap/layout.json`** if present (or the path in `.archmap.json` `layout.overridePath`). Expected shape:

```json
{
  "version": 1,
  "positions": {
    "module-id-1": { "x": 340, "y": 160 },
    "module-id-2": { "x": 520, "y": 240 }
  }
}
```

Keep the `positions` object in memory for Phase 3 substitution. If the file is absent or malformed, treat as `{}` and continue. Positions in this file are user-arranged via the interactive Edit mode in the HTML UI; preserving them across regeneration is the whole point of the file existing.

### Phase 1: Explore the Codebase

#### Phase 1.0 — Enumerate the filesystem (ONE call)

Before any targeted reads, dump the full file inventory in a single bulk call:

- Windows (`cmd`): `tree /F /A <path>`
- PowerShell: `Get-ChildItem -Recurse -File -Name <path>`
- POSIX: `find <path> -type f` (or `tree -F <path>` if installed)

Filter the output in-memory against `.archmap.json` `exclude` patterns (and default exclusions: `node_modules`, `dist`, `.git`, `vendor`, `target`, `build`, `.next`, `.venv`, `__pycache__`). Do NOT repeat directory listing during Phase 1.1+ — everything you need to know about what exists is in this one dump.

#### Phase 1.1 — Targeted reads

From the filtered file list, select source files (by extension and path heuristic) and read them in parallel batches (10–20 at a time). For each file, extract: line count, types, public functions, internal imports, role/responsibility.

Use the Task tool with `subagent_type: archmap:archmap-explorer` to **thoroughly** analyze the codebase. The agent must discover:

1. **All source files** — file paths, approximate line counts
2. **Module structure** — how the project is organized (directories, packages, modules)
3. **Inter-module dependencies** — which modules import/use which (e.g., `use crate::`, `import`, `require`, `from ... import`)
4. **Key types per module** — structs, classes, enums, interfaces, traits
5. **Key functions per module** — public API, entry points, important methods
6. **Data flow pipeline** — how data moves through the system (e.g., input → parse → transform → output)
7. **External dependencies** — major crates, packages, libraries used

The agent prompt is defined in `agents/archmap-explorer.md`.

If you must fall back to built-in `Explore`, use this prompt:
```
Thoroughly explore the codebase at <path>. For every source file, report:
- File path and approximate line count
- Key types defined (structs, classes, enums, interfaces)
- Key functions (public API, entry points)
- What it imports from other modules in this project (internal deps only)
- Its role/responsibility (1 sentence)

Also identify:
- The overall data flow pipeline (how input becomes output)
- Module groupings / tiers (which modules form logical layers)
- The project name and language/framework
```

### Phase 2: Design the Graph Layout

From the exploration results, build the visualization data structures. Each module becomes a node, each dependency becomes an edge.

**Module object shape:**
```javascript
{
  id: 'unique_id',           // kebab-case, e.g. 'auth-service'
  label: 'auth/',            // display name (short, fits in box)
  tier: 'api',               // one of the tier keys below
  lines: 420,                // approximate line count
  x: 340, y: 160,            // position on canvas (laid out by tier)
  w: 150, h: 60,             // box dimensions
  desc: 'JWT authentication', // one-line description
  subtitle: '420 lines',     // optional override for the sub-label
  details: {
    types: ['User', 'Token', 'Claims'],
    functions: ['authenticate()', 'refresh()'],
    imports: ['database', 'config'],
    notes: 'Handles JWT token issuance and validation...'
  }
}
```

**Available tier keys** (mapped to colors by each theme):
- `entry` — entry points, CLI, main
- `frontend` — parsing, lexing, UI components
- `ir` — intermediate representations, AST, core types
- `codegen` — code generation, output, rendering
- `runtime` — runtime systems, allocators, execution
- `lint` — analysis, linting, validation
- `driver` — orchestrators, controllers, routers
- `data` — database, storage, models
- `api` — API layer, endpoints, routes
- `ui` — user interface components
- `infra` — infrastructure, deployment, config loading
- `util` — utilities, helpers, shared code
- `test` — test infrastructure, fixtures
- `config` — configuration, settings

**Layout strategy:**
- Arrange modules in columns by tier/layer (left-to-right = input-to-output or top-to-bottom = abstraction layers)
- Entry points on the left, output/runtime on the right
- Larger modules get taller boxes
- Leave ~40px gap between tier columns, ~20px between modules vertically
- Start positions around x:80 for first column, increment by ~240 per column
- Each module's y position stacks within its column with ~20px gaps

**Edge object shape:**
```javascript
{ from: 'source_id', to: 'target_id', label: 'uses auth' }
```

**Tier labels** (canvas overlay):
```javascript
{ label: 'API LAYER', x: 340, y: 40 }  // positioned above each column
```

**Legend items:**
```javascript
{ tier: 'api', label: 'API / Endpoints' }  // one per tier used
```

**Pipeline steps** (sidebar data flow):
```javascript
{ type: 'label', text: 'HTTP request' }   // a box step
{ type: 'arrow', text: 'route + auth' }    // an arrow step
```

### Phase 3: Generate the HTML

1. **Read the template** from `${CLAUDE_PLUGIN_ROOT}/templates/archmap-template.html`
2. **Replace the placeholders** with the actual data. Substitution is strict find-and-replace, so each placeholder value MUST be pre-escaped for its context before the swap:

   **HTML-context placeholders** — HTML-escape `& < > " '` before substitution:
   - `{{PROJECT_NAME}}` → project name (e.g., `"Annie"`, `"My App"`). Used in `<title>`, `<h1>`, and a `data-project-name` attribute on `<body>`. HTML-escape only — do NOT wrap in quotes.
   - `{{STATS_HTML}}` → stats divs like `<div><span class="stat-val">~8,700</span> lines</div><div><span class="stat-val">23</span> files</div>`. This is raw HTML by design; escape the *values* inside (line counts, file counts) before composing the HTML.

   **JS-context placeholders** — produce valid JSON via `JSON.stringify(...)`. `JSON.stringify` handles embedded quotes, newlines, and unicode. Additionally, any string that could contain `</` (script closer) must be JSON-encoded with `</` escaped as `<\/` to avoid prematurely closing the enclosing `<script>` tag. Example replacement helper:
   ```
   const safeJson = obj => JSON.stringify(obj).replace(/<\/(script)/gi, '<\\/$1');
   ```
   - `{{MODULES_JSON}}` → `safeJson(modules)` — modules array
   - `{{EDGES_JSON}}` → `safeJson(edges)` — edges array
   - `{{TIER_LABELS_JSON}}` → `safeJson(tierLabels)` — tier label positions
   - `{{PIPELINE_JSON}}` → `safeJson(pipelineSteps)` — pipeline steps
   - `{{LEGEND_JSON}}` → `safeJson(legendItems)` — legend items
   - `{{LAYOUT_JSON}}` → `safeJson(layoutData.positions || {})` — user-arranged position overrides loaded from `.archmap/layout.json` in Phase 0, or `{}` if absent
   - `{{HISTORY_JSON}}` → `safeJson(history)` — version history array. For a fresh generation, seed this with one initial snapshot (version `v0.1`, note `"initial map"`) containing clones of the current `modules`/`edges`/`tierLabels`/`pipelineSteps`/`legendItems`/`layoutOverrides`. If re-running `/archmap:generate` on an existing map, read its current `history` and append a new auto-versioned snapshot with note `"regenerated from scratch"`.

   Never interpolate raw project-data strings directly into JS source. The template reads the project name from the `<body data-project-name="...">` attribute at runtime, so there is no need to embed it as a JS string literal.
3. **Write** the result to `docs/architecture.html` in the project root (create `docs/` if needed). Write atomically: write to `docs/architecture.html.tmp` then rename, so a concurrent reader never sees a half-written file.
4. **Open** in browser: `start "" "docs/architecture.html"` (Windows) or `open docs/architecture.html` (Mac) or `xdg-open docs/architecture.html` (Linux)

### Phase 3.5: Generate Markdown Export

Automatically generate a `docs/architecture-map.md` file with the complete architecture analysis:

**Structure:**
1. **Header** — Project name, generation date
2. **Overview** — Total files, lines, layers, dependencies
3. **Data Flow Pipeline** — Pipeline steps in code block
4. **Architecture Layers** — Grouped modules by tier with descriptions
5. **Module Details** — For each module:
   - Layer, size, description
   - Types, functions, imports
   - Dependencies (used by, depends on)
   - Architectural notes
6. **Dependency Graph** — Complete list of all edges

**Example markdown structure:**
```markdown
# ProjectName — Architecture Map

**Generated:** 2026-02-10

## Overview
- **Total Files:** 35
- **Total Lines:** ~5,500
- **Architecture Layers:** 6
- **Dependencies:** 38

## Data Flow Pipeline
[pipeline steps here]

## Architecture Layers

### Entry Points
- **module** (lines) — description

[... more layers ...]

## Module Details

### module-name

**Layer:** Entry Points
**Size:** 100 lines
**Description:** [description]

**Types:**
- `TypeName`

**Key Functions:**
- `functionName()`

**Used By:**
- other-module (uses)

**Depends On:**
- dependency-module (imports)

**Notes:**
[architectural notes]

---

[... more modules ...]

## Dependency Graph
- **from** → **to** (relationship)
```

Write this markdown file to `docs/architecture-map.md` using the same data structures created in Phase 2.

### Phase 4: Announce

Tell the user:
- Where both files were saved (`docs/architecture.html` and `docs/architecture-map.md`)
- How many modules and edges were mapped
- What tiers/layers were identified
- Remind them:
  - Interactive HTML: click modules to inspect, drag to pan, scroll to zoom, theme picker top-right, export button for on-demand MD generation
  - Markdown file: automatically generated for version control and documentation

## Layout Tips

- For a Rust project: entry → lexer/parser → AST/IR → codegen → runtime
- For a web app: routes → controllers → services → models → database
- For a React app: pages → components → hooks → context → api → utils
- For a Python package: __main__ → cli → core → helpers → config
- Scale box widths: 130-170px. Heights: 50 (small) to 80 (large files)
- Don't exceed ~6 columns horizontally or ~8 rows vertically (fits on screen)
- If a project has 30+ modules, group small related files into aggregate nodes

## Important

- The template HTML is self-contained (no external dependencies, no CDN)
- All rendering is canvas-based (fast, works offline)
- Theme state persists via localStorage
- The `details.notes` field should contain genuinely useful architectural notes, not generic descriptions
- Module `color` properties are set at runtime by `applyTheme()` — do NOT hardcode colors on modules
- Every `tier` value used in modules MUST exist as a key in the THEMES.*.tiers objects (the template includes: entry, frontend, ir, codegen, runtime, lint, driver, data, api, ui, infra, util, test, config)
