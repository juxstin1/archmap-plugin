# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Archmap is a Claude Code plugin — an interactive codebase architecture platform. It generates, repairs, diffs, and provides contextual intelligence about architecture maps. Output is a self-contained HTML canvas visualization and markdown export. No build step, no runtime dependencies, no CDN.

## Plugin Structure

This is a Claude Code plugin, not a typical application. No build system, no tests, no package.json. The "code" is markdown prompts, JSON configs, bash scripts, and one HTML template.

```
.claude-plugin/plugin.json        ← Plugin manifest (name, version, component paths, hooks ref)
commands/
  archmap.md                      ← /archmap — generate full architecture map
  archmap-repair.md               ← /archmap:repair — detect and fix map issues
  archmap-focus.md                ← /archmap:focus <module> — deep-dive one module
  archmap-diff.md                 ← /archmap:diff — detect architectural drift
agents/
  archmap-explorer.md             ← Full codebase exploration (used by /archmap)
  archmap-repair-agent.md         ← Targeted re-exploration (used by repair/focus/diff)
skills/
  architecture/SKILL.md           ← Auto-activates for architecture questions
hooks/
  hooks.json                      ← SessionStart + PostToolUse hook config
  scripts/detect-unmapped.sh      ← Detects missing/stale maps on session start
  scripts/flag-stale-modules.sh   ← Flags edits to mapped modules
templates/
  archmap-template.html           ← Self-contained HTML canvas visualization (~720 lines)
```

## Command Pipeline

All commands share a common pattern: **extract map state → explore/diff → patch → rewrite**.

### /archmap (generate)
Phase 0: Load `.archmap.json` config → Phase 1: Dispatch `archmap-explorer` for full exploration → Phase 2: Layout modules/edges by tier → Phase 3: Template substitution → Phase 4: Write HTML + markdown

### /archmap:repair (fix)
Extract current map from HTML JS variables → Dispatch `archmap-repair-agent` in scan mode → Diff results → Patch staleness/layout/details/integrity → Rewrite

### /archmap:focus (scoped)
Extract map → Find target module → Dispatch `archmap-repair-agent` in focus mode → Update module + edges → Rewrite

### /archmap:diff (read-only)
Extract map → Lightweight re-explore → Compare → Report drift (does NOT modify map)

## Two Agents, Two Purposes

- **`archmap-explorer`** — Full codebase exploration from scratch. Used only by `/archmap`. Thoroughness: very thorough.
- **`archmap-repair-agent`** — Targeted re-exploration of specific modules. Two modes: "scan" (check everything for drift) and "focus" (deep-dive one module). Used by repair/focus/diff.

## Template Placeholders

The HTML template uses these exact placeholder strings (double-curly-brace format):
- `{{PROJECT_NAME}}` — project name string
- `{{STATS_HTML}}` — raw HTML for stats bar
- `{{MODULES_JSON}}` — JSON array of module objects
- `{{EDGES_JSON}}` — JSON array of edge objects
- `{{TIER_LABELS_JSON}}` — JSON array of tier label positions
- `{{PIPELINE_JSON}}` — JSON array of pipeline steps
- `{{LEGEND_JSON}}` — JSON array of legend items

## Map State Extraction

All repair/focus/diff commands extract current map state by reading `docs/architecture.html` and parsing the JS variable assignments: `const modules = [...]`, `const edges = [...]`, etc. Project name comes from the `<title>` tag.

## Theme System

Four themes in the `THEMES` object: `dark`, `light`, `claude`, `openai`. Each provides `css` (custom properties), `tiers` (color map), `canvas` (draw colors), `swatch` (picker button). Module colors are set at runtime by `applyTheme()` — never hardcode colors.

## Tier System

Valid tier keys: `entry`, `frontend`, `ir`, `codegen`, `runtime`, `lint`, `driver`, `data`, `api`, `ui`, `infra`, `util`, `test`, `config`. Every tier used in modules MUST exist in `THEMES.*.tiers`.

## Configuration (.archmap.json)

Optional per-project config in project root:
- `exclude` — paths to skip during exploration
- `tiers` — path-prefix-to-tier mapping overrides
- `pinned` — module IDs that can't be removed or re-tiered
- `output.html` / `output.markdown` — custom output paths
- `theme` — default theme

## Hooks

- **SessionStart** — `detect-unmapped.sh` checks for missing/stale `docs/architecture.html`, suggests `/archmap` or `/archmap:repair`
- **PostToolUse (Write|Edit)** — `flag-stale-modules.sh` checks if edited file appears in the map, suggests repair/focus

## Key Conventions

- All paths in hooks/scripts use `${CLAUDE_PLUGIN_ROOT}` — never hardcode absolute paths
- HTML output must remain fully self-contained (no external scripts, stylesheets, or fonts)
- Canvas rendering: `roundRect()` helper, quadratic Bezier edges, `edgePoint()` for edge-to-box intersection
- Component files use YAML frontmatter (`---` delimiters) for metadata
- File and directory names use kebab-case
- Repair/focus preserve user-customized `details.notes` — never discard without explicit replacement
- Pinned modules (from `.archmap.json`) are never removed or re-tiered
