# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Archmap is a Claude Code plugin — an interactive codebase architecture platform. It generates, repairs, diffs, and provides contextual intelligence about architecture maps. Output is a self-contained HTML canvas visualization and markdown export. No build step, no runtime dependencies, no CDN.

## Plugin Structure

This is a Claude Code plugin, not a typical application. No build system, no tests, no package.json. The "code" is markdown prompts, JSON configs, bash scripts, and one HTML template.

```
.claude-plugin/plugin.json        ← Plugin manifest (name, version, author, repo/homepage metadata)
commands/
  generate.md                     ← /archmap:generate — generate full architecture map
  repair.md                       ← /archmap:repair — detect and fix map issues
  focus.md                        ← /archmap:focus <module> — deep-dive one module
  diff.md                         ← /archmap:diff — detect architectural drift
  snapshot.md                     ← /archmap:snapshot — save a version snapshot to history
agents/
  archmap-explorer.md             ← Full codebase exploration (used by /archmap:generate)
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

### /archmap:generate
Phase 0: Load `.archmap.json` config → Phase 1: Dispatch `archmap-explorer` for full exploration → Phase 2: Layout modules/edges by tier → Phase 3: Template substitution → Phase 4: Write HTML + markdown

### /archmap:repair (fix)
Extract current map from HTML JS variables → Dispatch `archmap-repair-agent` in scan mode → Diff results → Patch staleness/layout/details/integrity → Rewrite

### /archmap:focus (scoped)
Extract map → Find target module → Dispatch `archmap-repair-agent` in focus mode → Update module + edges → Rewrite

### /archmap:diff (read-only)
Extract map → Lightweight re-explore → Compare → Report drift (does NOT modify map)

## Two Agents, Two Purposes

- **`archmap-explorer`** — Full codebase exploration from scratch. Used only by `/archmap:generate`. Thoroughness: very thorough.
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
- `{{LAYOUT_JSON}}` — JSON object mapping module IDs to `{x, y}` user-arranged positions (loaded from `.archmap/layout.json` at generation time; `{}` when absent)
- `{{HISTORY_JSON}}` — JSON array of prior-version snapshots. Seeded with one initial entry by `/archmap:generate`; appended by `/archmap:snapshot` and by the auto-snapshot hooks in `/archmap:repair` and `/archmap:focus`

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
- `output.html` / `output.markdown` — custom output paths (hooks read `output.html` when deciding which file to watch for staleness)
- `theme` — default theme
- `hooks.sessionStart` — set to `false` to silence the SessionStart staleness nudge

## Hooks

Both hook scripts are `set -euo pipefail`, exit 0 on any failure path so a broken hook can never block a session, and honour `.archmap.json` (output path override + sessionStart opt-out). `jq` is used when available; scripts fall back to conservative regex parsing when it isn't.

- **SessionStart** — `detect-unmapped.sh` checks for missing/stale map file (`docs/architecture.html` by default), suggests `/archmap:generate` or `/archmap:repair`. Uses `git ls-files` for fast, `.gitignore`-aware staleness detection on git repos; falls back to a depth-capped `find` otherwise.
- **PostToolUse (Write|Edit)** — `flag-stale-modules.sh` receives the tool payload on STDIN (per Claude Code hook spec), extracts `tool_input.file_path`, and scopes its search to the modules block of the map so it can't false-match on CSS/comments.

## Key Conventions

- All paths in hooks/scripts use `${CLAUDE_PLUGIN_ROOT}` — never hardcode absolute paths
- HTML output must remain fully self-contained (no external scripts, stylesheets, or fonts)
- Canvas rendering: `roundRect()` helper, quadratic Bezier edges, `edgePoint()` for edge-to-box intersection
- Component files use YAML frontmatter (`---` delimiters) for metadata
- File and directory names use kebab-case
- Repair/focus preserve user-customized `details.notes` — never discard without explicit replacement
- Pinned modules (from `.archmap.json`) are never removed or re-tiered
