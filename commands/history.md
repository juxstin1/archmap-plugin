---
description: Inspect and prune the architecture map's version history.
argument-hint: "list | drop <version>"
---

# /archmap:history — Inspect and prune snapshot history

Companion to `/archmap:snapshot`. `list` prints the timeline; `drop <version>` removes a snapshot by label. Read-only for `list`; `drop` rewrites the HTML only when dropping an inline entry.

## Usage

```
/archmap:history list                     # print all snapshots, newest first
/archmap:history drop v0.3                # remove snapshot v0.3
/archmap:history                          # prints usage
/archmap:history --help                   # prints usage
```

## Runtime adapter

This command was originally written for Claude Code. The phases below are runtime-agnostic when the agent follows this rule — Claude Code, Codex (via `~/.codex/skills/`), and any other markdown-skill-aware runtime then execute identically.

**Template path resolution.** Wherever a phase says *"read the template"* or references `${CLAUDE_PLUGIN_ROOT}/templates/archmap-template.html`, resolve the template in this order and use the first hit:

  a. `${ARCHMAP_TEMPLATE_PATH}` — direct path override
  b. `${ARCHMAP_ROOT}/templates/archmap-template.html` — plugin-root override (recommended for non-Claude-Code runtimes; set `${ARCHMAP_ROOT}` once to the directory containing this plugin's `templates/`, `agents/`, `commands/`)
  c. `${CLAUDE_PLUGIN_ROOT}/templates/archmap-template.html` — Claude Code fallback (the `${CLAUDE_PLUGIN_ROOT}` env var is set only by Claude Code's plugin loader)

Only the `drop` subcommand needs the template (for rewriting the HTML when an inline snapshot is removed). `list` is fully read-only.

(`/archmap:history` does not dispatch a subagent, so the agent-dispatch rule from sibling commands doesn't apply here.)

## Execution directives

These rules apply to all phases below.

1. **Existence checks: batch all artifact paths into ONE `Test-Path`/`test` call.** Never use `Get-ChildItem`/`ls` to check existence — they error on missing directories and waste round-trips.

   - Windows: `Test-Path docs/architecture.html, .archmap.json, .archmap/snapshots`
   - POSIX: `for f in docs/architecture.html .archmap.json .archmap/snapshots; do [ -e "$f" ] && echo "$f"; done`

2. **HTML map extraction: read `docs/architecture.html` ONCE, in full, then extract all top-level JSON arrays in-memory via regex.** Variables to extract in a single pass (match `const` OR `let` for `modules`, `edges`, `tierLabels`, `pipelineSteps`, `legendItems`, `layoutOverrides` — newer template versions use `let` so the timeline scrubber can rebind them; `history` stays `const`): `modules`, `edges`, `tierLabels`, `pipelineSteps`, `legendItems`, `layoutOverrides`, `history`.

3. **Regex must be balanced-bracket / multi-line aware.** The arrays and objects can span many lines. Don't use `^const modules = \[(.*)\]` — match the whole literal from the opening `[`/`{` to its matching close. A JS-aware parser is also fine.

4. **Independent reads run in parallel.** Listing `.archmap/snapshots/*.json` and reading the HTML do not depend on each other — issue them as concurrent tool calls.

5. **Probe once per phase.** If the `Test-Path` batch in rule 1 already told you a file exists, don't re-check later.

## Subcommand dispatch

Parse `$ARGUMENTS` and branch on the first whitespace-separated token:

- `list` → **Phase A**
- `drop <version>` → **Phase B** (error if `<version>` is missing)
- empty, `help`, or `--help` → print the **Usage** block above and exit
- anything else → error `unknown subcommand '<token>'` followed by the **Usage** block

## Phase A — `list`

### A.1 Load map and config

Batch existence check: `docs/architecture.html` (or the path in `.archmap.json` `output.html`), `.archmap.json`, the configured spill directory (default `.archmap/snapshots`).

- If the target HTML doesn't exist, tell the user to run `/archmap:generate` first and exit.
- Read the HTML once and extract `history` (it stays `const`). If `.archmap.json` exists, read `history.spillPath` (default `.archmap/snapshots`); otherwise use the default.
- In parallel with the HTML read, list the spill directory for `*.json` files if it exists. Skip if it doesn't — spill is optional.

### A.2 Merge sources

For each inline entry, tag it `inline`. For each spilled file, read and parse the JSON and tag it `spilled` with its file path (e.g., `.archmap/snapshots/v0.1.json`).

De-duplicate by `version` — if the same label appears both inline and on disk, prefer the inline copy and note the shadowed spill file in the output.

### A.3 Sort

Chronological, **newest first**. Sort key: `date` (ISO-8601 string comparison is correct here). Fall back to numeric version order when `date` is missing or equal.

### A.4 Print

One entry per line, aligned columns. Format:

```
v0.3 · 2026-04-01 · "added Stripe" · (inline)
v0.2 · 2026-03-15 · "added B"      · (inline)
v0.1 · 2026-03-01 · "initial map"  · (spilled → .archmap/snapshots/v0.1.json)
```

Shorten `date` to its `YYYY-MM-DD` prefix. Truncate notes longer than ~60 chars with an ellipsis. Mark the newest entry as `(inline, current)` — it's the one mirrored by the top-level arrays.

If `history` is empty and no spilled files exist, print `No snapshots yet. Run /archmap:snapshot to save one.` and exit.

## Phase B — `drop <version>`

### B.1 Resolve

Run the same load as **A.1** and merge sources as **A.2**. Build the chronologically-sorted list as **A.3**.

- If `<version>` matches no entry → error with a clean message listing available versions (newest first, same format as A.4). Exit.
- If `<version>` is the newest entry (the current mirror) → refuse. Print:

  ```
  Cannot drop v0.3 — it is the current snapshot (the map's top-level arrays mirror it).
  Drop an older version, or run /archmap:snapshot to create a new current entry first.
  ```

  Exit. Do not rewrite anything.

### B.2 Drop

Two cases, decided by the tag from A.2:

**Case 1 — spilled.** Delete the sibling JSON file at its recorded path. No HTML rewrite. Confirm with: `Dropped v<version> — removed <path>`.

**Case 2 — inline.** Remove the entry from the in-memory `history[]` array, then rewrite the HTML using the same template-substitution approach as `/archmap:snapshot` Phase 4:

1. Resolve the template via the Runtime adapter above.
2. Substitute every placeholder, including `{{HISTORY_JSON}}` with `safeJson(history)`. The current-state top-level arrays (`modules`, `edges`, `tierLabels`, `pipelineSteps`, `legendItems`, `layoutOverrides`) must continue to mirror the newest remaining entry — they are unchanged by this operation because the newest entry itself is never droppable (see B.1).
3. Write atomically: write to `<target>.tmp`, then `mv` over the original. Disk-write failure must NOT leave a truncated HTML.

Confirm with: `Dropped v<version> — rewrote <html-path> (<N> entries remaining)`.

Dropping the oldest inline entry when spill is enabled: no promotion from disk is required — just remove. Spilled entries stay spilled.

### B.3 Leave the markdown file alone

`docs/architecture-map.md` reflects current state and is unaffected by history operations.

## Errors

- Missing map file → `No map at <path>. Run /archmap:generate first.`
- Parse failure on the HTML's `history` array → suggest `rm docs/architecture.html && /archmap:generate` to regenerate.
- Spill file exists in the directory but contains invalid JSON → warn with the path, skip that entry, continue.
- `drop` with no version → `usage: /archmap:history drop <version>`.
- `drop` of the newest entry → refuse (see B.1).
- `drop` of an unknown version → list available versions.

## Non-goals

- **Diff rendering between two snapshots.** The in-canvas timeline scrubber already covers playback; `/archmap:diff` covers drift-from-live. A future `/archmap:compare <a> <b>` is queued (#4 Phase 3).
- **Bulk drops by predicate** (e.g., "drop everything older than 30 days"). Explicit version labels only — safer.
- **Promoting a spilled snapshot back inline.** The inline/spill boundary is managed by `/archmap:snapshot` via `history.maxInlineSnapshots`.

## Important

- `list` never modifies the map.
- `drop` never modifies the current-state top-level arrays, because the newest entry is never droppable.
- Atomic writes are mandatory — follow the `.tmp` then `mv` pattern so a disk failure can't corrupt the map.
- Respect `.archmap.json` `history.spillPath` on every read and delete.
