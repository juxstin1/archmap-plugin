---
description: Detect architectural drift between the current codebase and existing architecture map.
argument-hint: "[--output <path>] [--summary]"
---

# /archmap:diff — Architectural Drift Detection

Compare the current state of the codebase against the existing architecture map to detect what's changed structurally. Shows added/removed/renamed modules, new/broken dependencies, and tier changes.

## Usage

```
/archmap:diff                    # Full diff, output inline
/archmap:diff --summary          # Compact summary only
/archmap:diff --output docs/     # Write detailed diff to docs/architecture-diff.md
```

## Runtime adapter

This command was originally written for Claude Code. The phases below are runtime-agnostic when the agent follows this rule — Claude Code, Codex (via `~/.codex/skills/`), and any other markdown-skill-aware runtime then execute identically.

**Agent dispatch.** Wherever a phase says *"Dispatch `archmap:archmap-repair-agent` via the Task tool"*:

  a. If your runtime has a `Task` tool with `subagent_type` support (Claude Code): dispatch as specified.
  b. Otherwise (Codex, etc.): read the agent prompt file and execute it inline in the current session with the inputs the phase would have passed. Resolve the agent prompt path in this order, first hit wins: `${ARCHMAP_ROOT}/agents/archmap-repair-agent.md` → `${CLAUDE_PLUGIN_ROOT}/agents/archmap-repair-agent.md`. (`${ARCHMAP_ROOT}` should be set once, at install time, to the plugin's install directory; Claude Code sets `${CLAUDE_PLUGIN_ROOT}` automatically.)

(`/archmap:diff` does not read the HTML template, so the template-path rule from sibling commands doesn't apply here.)

## Execution directives

These rules apply to all phases below. They exist so the agent spends model cycles on judgment, not on re-deriving how to enumerate a filesystem or parse this template.

1. **Existence checks: batch all artifact paths into ONE `Test-Path`/`test` call.** Never use `Get-ChildItem docs` or `ls docs` to check if a file exists — those error loudly on missing directories and waste a round-trip on follow-up probes.

   - Windows: `Test-Path docs/architecture-map.md, docs/architecture.html, .archmap.json, .archmap/layout.json`
   - POSIX: `for f in docs/architecture-map.md docs/architecture.html .archmap.json .archmap/layout.json; do [ -e "$f" ] && echo "$f"; done`

2. **HTML map extraction: read `docs/architecture.html` ONCE, in full, then extract all `const` arrays in-memory via regex.** Do not run `Select-String` (or `grep`) once per variable. One full read + one regex pass is correct; seven sequential greps of the same file are not. Variables to extract in a single pass: `const modules`, `const edges`, `const tierLabels`, `const pipelineSteps`, `const legendItems`, `const layoutOverrides`, `const history`.

3. **Independent reads run in parallel.** When a phase lists reads that do not depend on each other, issue them as concurrent tool calls.

4. **Probe once per phase.** If the `Test-Path` batch in rule 1 already told you a file exists, don't re-check later.

## Prerequisites

An existing `docs/architecture.html` must exist. If no map exists, tell the user there's nothing to diff against — suggest `/archmap:generate` first.

## Behavior

### Phase 1: Extract Map State

1. **Read** `docs/architecture.html` and parse the embedded map data:
   - Extract `modules`, `edges`, `tierLabels`, `pipelineSteps`, `legendItems`
   - Extract project name from `<title>` tag
2. **Record** the module inventory: id, label, tier, lines, file paths

### Phase 2: Lightweight Re-exploration

1. **Check** for `.archmap.json` — load exclude paths
2. **Enumerate the filesystem in ONE call** so new-file detection doesn't require exploratory directory-walking. Use `tree /F /A` / `Get-ChildItem -Recurse -File -Name` / `find -type f` depending on runtime. Filter the output in-memory against `.archmap.json` `exclude` (plus defaults: `node_modules`, `dist`, `.git`, `vendor`, `target`, `build`, `.next`, `.venv`, `__pycache__`). Pass this list to the scan agent.
3. **Dispatch** `archmap:archmap-repair-agent` in **scan mode** via the Task tool:
   ```
   subagent_type: archmap:archmap-repair-agent
   ```
   Provide the agent with the full module list, project root, and the filtered filesystem listing from step 2.
4. **Wait** for the repair report (we use the repair report format but only for diffing, not fixing)

### Phase 3: Generate Diff

Compare the repair report against the current map state and categorize changes:

#### Module Changes
- **Added:** New source files/directories not in any existing module
- **Removed:** Modules whose files no longer exist
- **Renamed:** Files that moved but appear to be the same module (similar types/functions)
- **Resized:** Modules with significant line count changes (>20%)

#### Dependency Changes
- **New edges:** Dependencies that didn't exist in the map
- **Broken edges:** Dependencies that no longer exist
- **Changed edges:** Dependencies where the relationship type changed

#### Tier Changes
- Modules whose logical tier assignment shifted based on current file organization

#### Data Flow Changes
- Whether the pipeline steps are still accurate

### Phase 4: Output

#### Inline Output (default)
Present the diff in a readable format:

```
## Architecture Drift Report

**Project:** <name>
**Map generated:** <date from map if available>
**Scanned:** <current date>

### Summary
- X modules added, Y removed, Z modified
- A new dependencies, B broken dependencies
- C tier reassignments suggested

### Added Modules
- `new-module` (src/new/) — suggested tier: api — "Handles new API endpoints"

### Removed Modules
- `old-module` (src/old/) — was tier: util — files no longer exist

### Modified Modules
- `auth` — 420 → 580 lines (+38%), 2 new functions, 1 new type

### New Dependencies
- `auth` → `new-module` (imports auth middleware)

### Broken Dependencies
- `old-module` → `database` (old-module deleted)

### Tier Changes
- `helpers` — mapped as util, now looks like infra (moved to src/infra/)

### Verdict
[Map is current | Map is slightly stale | Map needs repair — run /archmap:repair]
```

#### Summary Mode (--summary)
Compact one-paragraph summary with counts only.

#### File Output (--output)
Write the full diff report to `docs/architecture-diff.md` (or custom path).

## Important

- This command is READ-ONLY — it does NOT modify the existing map
- The diff is informational — it tells you what changed, not what to do about it
- For fixing issues, use `/archmap:repair` (full) or `/archmap:focus <module>` (scoped)
- The "Verdict" line should give an honest assessment: if only 1-2 modules drifted, say "slightly stale"; if >30% of modules are affected, say "needs repair"
- If the user runs with `--output`, still show the summary inline
