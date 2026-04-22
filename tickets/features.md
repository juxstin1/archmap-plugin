# Features — Round 2

New capabilities. 11 items. Bigger than enhancements — each adds new surface area.

---

### F1. `/archmap:compare <a> <b>`
**Severity:** medium
**Status:** open (queued per `commands/snapshot.md` non-goals)
**Location:** new `commands/compare.md`
**Problem:** Users can list snapshots and scrub between them visually, but there's no structured side-by-side comparison. "What changed from v0.2 to v0.5?" has no direct answer.
**Fix:** Command reads two snapshots from `history[]` (or spilled files), produces a diff structurally identical to `/archmap:diff` output: added/removed/modified modules, new/broken edges, tier changes, between the two points. Inline or file output.
**Done when:** `/archmap:compare v0.2 v0.5` produces a readable diff between those snapshots; `--json` mode yields the same structure as `/archmap:diff --json` (after E17 lands).

---

### F2. `/archmap:at <ref>`
**Severity:** medium
**Status:** open (queued per `commands/snapshot.md` non-goals)
**Location:** new `commands/at.md`
**Problem:** The map only shows current state (or scrubbed snapshots baked in the HTML). Asking "what did the architecture look like on the 1.1.0 release?" requires manually regenerating the map against a git ref.
**Fix:** Command accepts a git ref (commit, tag, branch), checks out the repo at that ref in a temp worktree, dispatches the explorer agent against it, renders the map to a temp path (or opens inline). Cleanup after.
**Done when:** `/archmap:at v1.1.0` renders the v1.1.0-era architecture without disturbing the current workspace.

---

### F3. In-canvas snapshot diff animation
**Severity:** low
**Status:** open (queued Phase 2b per CHANGELOG)
**Location:** `templates/archmap-template.html` (timeline handler)
**Problem:** Scrubbing between snapshots is a hard cut. For adjacent snapshots with few changes, users can't see *what* changed at a glance.
**Fix:** When `setSnapshot` transitions, animate: fade in new modules (green glow), fade out removed (red), tween repositioned modules to their new XY, morph edges. Skip for large deltas (>50% of nodes changed).
**Done when:** Stepping from v0.2 to v0.3 where one module was added shows that module fading in with a green accent.

---

### F4. `/archmap:theme <name>`
**Severity:** medium
**Status:** open
**Location:** new `commands/theme.md`
**Problem:** The template bakes in four themes. Users can't add custom themes without forking. No CLI way to swap the default theme post-generation.
**Fix:** Command accepts either a built-in name or a path to a JSON theme file. Swaps the default theme attribute in the existing HTML's initial `applyTheme()` call. Opens door to a community theme catalog. Pair with Anthropic's `theme-factory` skill pattern.
**Done when:** `/archmap:theme forest` (after shipping a forest theme) swaps the map to forest colors on reload, and persists as default for new generations.

---

### F5. `/archmap:query "<question>"`
**Severity:** low
**Status:** open
**Location:** new `commands/query.md`
**Problem:** The `architecture` skill handles free-form questions, but structured graph queries ("transitive deps of X", "modules with no incoming edges", "cycle detection") require Claude to reason from scratch each time.
**Fix:** Command ingests the baked map JSON, runs explicit graph algorithms. Query grammar: `depends-on X`, `used-by X`, `transitive-deps X`, `orphans`, `cycles`, `tier <name>`. Output both human-readable text and optionally a filtered sub-map HTML showing only queried nodes.
**Done when:** `/archmap:query "transitive deps of auth"` returns a correct transitive dependency list in under a second and writes an optional filtered HTML.

---

### F6. `/archmap:export png|svg|pdf`
**Severity:** medium
**Status:** open
**Location:** new `commands/export.md`
**Problem:** The in-UI Export button (PNG+MD) works only when the HTML is open in a browser. CI pipelines, doc generators, and headless flows can't produce images.
**Fix:** CLI command that reads the baked map JSON, renders server-side to the requested format. Scope for v1: PNG via headless canvas (`canvas` npm package or playwright headless), SVG via a pure-JS reimplementation of the draw helpers, PDF via `html-to-pdf`. Ship without any runtime deps if possible — skip PDF in v1 if it requires heavy tooling.
**Done when:** `/archmap:export png` writes `docs/architecture.png` matching the UI export pixel-for-pixel.

---

### F7. Git history overlay — module churn heatmap
**Severity:** low
**Status:** open
**Location:** `templates/archmap-template.html` + generator enrichment
**Problem:** Maps show structure but not activity. Teams want "which modules are changing the most."
**Fix:** Add a toggle button that tints modules by churn (commits touching their files in last N days). Requires the explorer agent to populate a `churn` field per module via `git log --numstat`. Tint via opacity/saturation overlay on top of tier color.
**Done when:** Toggling "Activity" mode in a map of this plugin highlights high-churn files (e.g., the template) distinctly from quiet ones (e.g., SKILL.md).

---

### F8. Module grouping / collapsible subgraphs
**Severity:** low
**Status:** open
**Location:** `templates/archmap-template.html` + module schema
**Problem:** 50+ module maps become visual noise. Users want to collapse related modules into an aggregate node, expand on demand.
**Fix:** Extend module schema with optional `parent: 'group-id'`. Group nodes render as larger containers with a collapse/expand toggle. Layout engine treats expanded groups as column-spanning blocks.
**Done when:** A 50-module map can be rendered with top-level domain groups (e.g., `auth/*`, `billing/*`) collapsed by default; clicking a group expands it.

---

### F9. In-UI notes editor
**Severity:** low
**Status:** open
**Location:** `templates/archmap-template.html`
**Problem:** `details.notes` is read-only in the HTML. Users who want to annotate a module have to edit the source JSON by hand and regenerate.
**Fix:** Edit mode on the inspector: click into the Notes section, inline textarea, Save writes to localStorage and shows a "Download notes.json" button. Merge-on-next-generate pipeline matches the layout override pattern.
**Done when:** A user can edit a module's notes in the browser, download a patch, commit it, and have the next `/archmap:generate` preserve the edit.

---

### F10. Auto-PNG sidecar on `/archmap:snapshot`
**Severity:** low
**Status:** open
**Location:** `commands/snapshot.md`
**Problem:** Snapshots are JSON structural data only. Visual drift (colors, layouts, user drags) isn't captured. Rendering a historical snapshot requires loading the HTML and scrubbing.
**Fix:** Optional config flag `history.autoPng: true`. On snapshot creation, render to `.archmap/snapshots/<version>.png` alongside the JSON. F3's animation and F1's compare can then embed those PNGs in reports.
**Done when:** `/archmap:snapshot` with `autoPng: true` produces a matching PNG in the spill directory.

---

### F11. Multi-map workspace
**Severity:** low
**Status:** open
**Location:** spec + new `commands/workspace.md`
**Problem:** Large organizations often have many related services. Rendering all in one map is overwhelming. Currently one project = one map; no cross-linking.
**Fix:** Workspace manifest (e.g., `.archmap.workspace.json`) lists N repos + cross-service edges. Each repo gets its own map, but modules can link to external maps via click. A workspace overview page shows service-level nodes with drill-down.
**Done when:** A workspace config covering 3 related repos generates 3 maps plus an overview; clicking a module that links to another repo opens that repo's map focused on the referenced module.
