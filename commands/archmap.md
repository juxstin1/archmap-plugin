# /archmap - Interactive Codebase Architecture Map

Generate an interactive 2D web visualization of any codebase's architecture with pan/zoom, module inspector, dependency edges, and 4 switchable themes (Dark, Light, Claude, OpenAI).

## Usage

```
/archmap              # Full map of current project
/archmap <path>       # Map a specific subdirectory or project
/archmap --refresh    # Regenerate map for current project (re-explore)
```

## Behavior

When user runs `/archmap`:

### Phase 1: Explore the Codebase

Use the Task tool with `subagent_type: Explore` to **thoroughly** analyze the codebase. The agent must discover:

1. **All source files** — file paths, approximate line counts
2. **Module structure** — how the project is organized (directories, packages, modules)
3. **Inter-module dependencies** — which modules import/use which (e.g., `use crate::`, `import`, `require`, `from ... import`)
4. **Key types per module** — structs, classes, enums, interfaces, traits
5. **Key functions per module** — public API, entry points, important methods
6. **Data flow pipeline** — how data moves through the system (e.g., input → parse → transform → output)
7. **External dependencies** — major crates, packages, libraries used

The Explore agent prompt should be:
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
2. **Replace the placeholders** with the actual data:
   - `{{PROJECT_NAME}}` → project name (e.g., "Annie", "My App")
   - `{{STATS_HTML}}` → stats divs like: `<div><span class="stat-val">~8,700</span> lines</div><div><span class="stat-val">23</span> files</div>`
   - `{{MODULES_JSON}}` → the modules array as JSON
   - `{{EDGES_JSON}}` → the edges array as JSON
   - `{{TIER_LABELS_JSON}}` → tier label positions as JSON
   - `{{PIPELINE_JSON}}` → pipeline steps as JSON
   - `{{LEGEND_JSON}}` → legend items as JSON
3. **Write** the result to `docs/architecture.html` in the project root (create `docs/` if needed)
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
