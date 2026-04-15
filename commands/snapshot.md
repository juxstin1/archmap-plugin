---
description: Save a snapshot of the current architecture map into its version history.
argument-hint: "[--name <label>] [--note \"description\"]"
---

# /archmap:snapshot — Save a version snapshot

Capture the current map state as a named snapshot in the map's `history[]` array. Snapshots let you play back architectural evolution, diff two points in time, and auto-generate changelogs (see #4 Phase 2+).

## Usage

```
/archmap:snapshot                            # auto-versioned (v0.N, next in sequence)
/archmap:snapshot --name v1.2.0              # named snapshot
/archmap:snapshot --note "split auth module"  # custom note
/archmap:snapshot --name v1.0 --note "public release"
```

## Runtime adapter

This command was originally written for Claude Code. The phases below are runtime-agnostic when the agent follows this rule — Claude Code, Codex (via `~/.codex/skills/`), and any other markdown-skill-aware runtime then execute identically.

**Template path resolution.** Wherever a phase says *"read the template"* or references `${CLAUDE_PLUGIN_ROOT}/templates/archmap-template.html`, resolve the template in this order and use the first hit:

  a. `${ARCHMAP_TEMPLATE_PATH}` — direct path override
  b. `${ARCHMAP_ROOT}/templates/archmap-template.html` — plugin-root override (recommended for non-Claude-Code runtimes; set `${ARCHMAP_ROOT}` once to the directory containing this plugin's `templates/`, `agents/`, `commands/`)
  c. `${CLAUDE_PLUGIN_ROOT}/templates/archmap-template.html` — Claude Code fallback (the `${CLAUDE_PLUGIN_ROOT}` env var is set only by Claude Code's plugin loader)

(`/archmap:snapshot` does not dispatch a subagent, so the agent-dispatch rule from sibling commands doesn't apply here.)

## Execution directives

These rules apply to all phases below. They exist so the agent spends model cycles on judgment, not on re-deriving how to enumerate a filesystem or parse this template.

1. **Existence checks: batch all artifact paths into ONE `Test-Path`/`test` call.** Never use `Get-ChildItem docs` or `ls docs` to check if a file exists — those error loudly on missing directories and waste a round-trip on follow-up probes.

   - Windows: `Test-Path docs/architecture.html, .archmap.json, .archmap/snapshots`
   - POSIX: `for f in docs/architecture.html .archmap.json .archmap/snapshots; do [ -e "$f" ] && echo "$f"; done`

2. **HTML map extraction: read `docs/architecture.html` ONCE, in full, then extract all `const` arrays in-memory via regex.** Do not run `Select-String` (or `grep`) once per variable. One full read + one regex pass is correct; seven sequential greps of the same file are not. Variables to extract in a single pass: `const modules`, `const edges`, `const tierLabels`, `const pipelineSteps`, `const legendItems`, `const layoutOverrides`, `const history`.

3. **Independent reads run in parallel.** When a phase lists reads that do not depend on each other, issue them as concurrent tool calls.

4. **Probe once per phase.** If the `Test-Path` batch in rule 1 already told you a file exists, don't re-check later.

## Behavior

### Phase 1: Load current map

Read the target HTML file (default `docs/architecture.html`, or the path in `.archmap.json` `output.html`). Extract the current data by parsing the JavaScript variable declarations between the anchor comments:

- `const modules = [...]`
- `const edges = [...]`
- `const tierLabels = [...]`
- `const pipelineSteps = [...]`
- `const legendItems = [...]`
- `const layoutOverrides = {...}`
- `const history = [...]` — the existing history array (empty on first run)

If the target file doesn't exist, tell the user to run `/archmap:generate` first and exit.

### Phase 2: Resolve version label

If `--name <label>` is given, use it verbatim. Otherwise:

1. Look at existing `history[]` entries for versions matching `v<major>.<minor>` (e.g., `v0.3`, `v1.7`)
2. Pick the highest minor within the highest major and increment it — so the next auto-version after `v0.3` is `v0.4`
3. If there's no history yet, start at `v0.1`

Reject duplicate version labels (if the user passes `--name v0.3` and that already exists, error).

### Phase 3: Build the snapshot entry

```javascript
{
  version: "<resolved-version>",
  date: "<ISO-8601 UTC timestamp>",
  commit: "<short git SHA>",      // optional; attempt `git rev-parse --short HEAD` and omit on failure
  note: "<--note arg, or 'snapshot' as fallback>",
  modules: <deep-clone of current modules>,
  edges: <deep-clone of current edges>,
  tierLabels: <deep-clone of current tierLabels>,
  pipelineSteps: <deep-clone of current pipelineSteps>,
  legendItems: <deep-clone of current legendItems>,
  layoutOverrides: <deep-clone of current layoutOverrides>
}
```

The clone is important — subsequent edits (e.g., `/archmap:repair`) must not mutate historical snapshots.

### Phase 4: Append and rewrite

1. Append the new entry to `history[]`.
2. **Enforce `.archmap.json` `history.maxInlineSnapshots`** (default 50). If the array would exceed the cap:
   - Check `.archmap.json` `history.spillPath` (default `.archmap/snapshots/`)
   - Move the oldest entries into `<spillPath>/<version>.json` files (one per snapshot)
   - Keep only the newest N entries inline
   - Preserve the self-contained guarantee for users who don't want spill: set `history.maxInlineSnapshots: 9999` (or a very high number) in `.archmap.json`.
3. Rewrite the HTML using the same template-substitution approach as `/archmap:generate` Phase 3:
   - Read `${CLAUDE_PLUGIN_ROOT}/templates/archmap-template.html`
   - Substitute every placeholder, including `{{HISTORY_JSON}}` with `safeJson(history)`
   - Write atomically (`.tmp` then `mv`)
4. Leave `docs/architecture-map.md` untouched — it already represents current state.

### Phase 5: Report

Tell the user:

- The resolved version label and the note
- How many entries are now in history
- If any snapshots spilled to disk, list the file paths
- The total byte size added to the HTML (rough — helps them notice when to enable spill)

## Configuration

`.archmap.json`:

```json
{
  "history": {
    "enabled": true,
    "autoSnapshotOnRepair": true,
    "autoSnapshotOnFocus": true,
    "maxInlineSnapshots": 50,
    "spillPath": ".archmap/snapshots"
  }
}
```

- `enabled` (default `true`) — master switch. When `false`, this command errors out.
- `autoSnapshotOnRepair` / `autoSnapshotOnFocus` (default `true`) — whether `/archmap:repair` and `/archmap:focus` call this command before mutating.
- `maxInlineSnapshots` (default `50`) — cap before spill kicks in.
- `spillPath` (default `.archmap/snapshots`) — directory for overflow snapshots.

## Non-goals

- **Snapshot diff rendering.** That's Phase 2 (timeline scrubber + diff mode in the HTML UI).
- **Git integration beyond capturing HEAD SHA.** Phase 3 will add `/archmap:at <ref>` and `/archmap:compare`.
- **Deleting snapshots by predicate.** A follow-up sub-command (`/archmap:history drop <version>`) will cover that; this command is purely additive.

## Error handling

- Missing map file → tell the user to run `/archmap:generate` first
- Parse failure on an existing HTML → suggest `rm docs/architecture.html && /archmap:generate` to regenerate
- Disk write failure on spill → abort; do not rewrite the HTML (atomic all-or-nothing)
- Duplicate `--name` → error, list existing versions

## Important

- Snapshots are **additive only**. This command never deletes or modifies existing history entries.
- The current-state top-level arrays (`const modules`, etc.) always mirror the newest snapshot's data — code that doesn't care about history keeps working unchanged.
- Preserve `details.notes` on every module in every snapshot (user-customized notes should never be lost).
