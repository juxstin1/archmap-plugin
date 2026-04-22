# Build Order

Execution plan for the round-2 backlog. Waves group tickets that share a context, can commit atomically, and are safe to ship together. Each wave should ship as its own PR to keep reviews tight.

## Principles

1. **Kill lies first.** User-facing buttons that do nothing are worse than missing features. Dead code that looks alive is worse than a gap.
2. **One concept per PR.** If reviewers need to hold two mental models, it's two PRs.
3. **Tests before features.** Ship the fixture harness (E5) before any feature that would benefit from smoke-testing against fixtures.
4. **Don't touch aesthetics until structure is right.** Font/color polish (E1-E3) lands after the bug-fix waves so reviewers don't get distracted by visual diffs.

## Waves

### Wave 1 — Dead-weight cleanup (same session as ticket creation)

Low-risk, high-clarity. All three share the template file, so they naturally stack into one PR.

| # | ID | Kind | What |
|---|---|---|---|
| 1 | **B3 + D1** | bug + dead | Remove `showAllLabels` variable, function, and button |
| 2 | **B4 + D2** | bug + dead | Remove unused `currentThemeName` |
| 3 | **B5 + D5** | bug + dead | Derive `tierOrder` from `THEMES.dark.tiers` in `buildMarkdown` |
| 4 | **D3** | dead | Remove `layoutDirty` (never read) |
| 5 | **D4** | dead | Remove unreachable explorer-fallback prose from `generate.md` |

**PR title:** `chore: remove dead code and hardcoded tier order in exportMarkdown`

**Done when:** `grep showAllLabels templates/archmap-template.html` returns nothing; `grep currentThemeName` returns nothing; `tierOrder` in `buildMarkdown` is derived, not hardcoded.

---

### Wave 2 — Correctness fixes

Small, independent bug fixes. Commit each atomically, PR as a group.

| # | ID | What |
|---|---|---|
| 1 | **B2** | Add `MultiEdit` to PostToolUse matcher in `hooks/hooks.json` |
| 2 | **B6** | Capture raw mousedown coords for click-vs-drag threshold |
| 3 | **B8** | Null-check `renderToPng` result in `exportAll` |
| 4 | **B10** | Preserve edit-mode cursor after pan release |
| 5 | **B14** | Filter `legendItems` to tiers actually used at render time |

**PR title:** `fix: five small correctness bugs from round-2 audit`

**Done when:** each ticket's "Done when" passes; template still loads without regressions on a sample map.

---

### Wave 3 — Timeline scrubber bleed (largest single bug)

This one is structural and user-visible. Isolate in its own PR so it gets real review.

| # | ID | What |
|---|---|---|
| 1 | **B1** | In `setSnapshot`, apply localStorage overlay only when showing the newest snapshot |
| 2 | **B7** | Blur focused timeline button before firing arrow-key navigation |

**PR title:** `fix(template): timeline scrubber no longer bleeds current drags into history`

**Done when:** drag a module in the newest snapshot, scrub to an older one → module appears at its *historical* position, not the current drag. Arrow keys don't double-fire through focused tick buttons.

---

### Wave 4 — Infrastructure for everything downstream

The fixture harness (E5) is the gate for safer future work. Adding `--json` to diff (E17) enables the CI integrations features (F7, F15) without more refactor later.

| # | ID | What |
|---|---|---|
| 1 | **E5** | `tests/fixtures/` (4 sample repos) + `tests/run.sh` + snapshot baselines |
| 2 | **E17** | `/archmap:diff --json` mode in `commands/diff.md` |
| 3 | **B9** | Clamp off-screen drag positions (viewport-bounded) |
| 4 | **B13** | Commit `examples/.archmap.json` so CI exercises the schema |

**PR title:** `test: add fixture harness + diff JSON mode + schema example`

**Done when:** `bash tests/run.sh` exits 0 with no diff against baselines; a sample `/archmap:diff --json` yields valid structured output.

---

### Wave 5 — UX polish

After the structural work stabilizes, land the polish batch. These are visible but low-risk.

| # | ID | What |
|---|---|---|
| 1 | **E14** | `prefers-color-scheme` default when no localStorage |
| 2 | **E13** | Replace `confirm()` in `resetLayout` with the existing modal pattern |
| 3 | **E11** | Zip the PNG + MD pair in `exportAll` instead of firing two downloads |
| 4 | **E4** | Timeline label tooltip on overflow |
| 5 | **E6** | Sidebar search filter |
| 6 | **E7** | Show XY position in inspector |
| 7 | **E8** | Clickable "Used By" / "Depends On" entries pan to module |
| 8 | **E9** | Surface current snapshot metadata in default sidebar |
| 9 | **E12** | Keyboard navigation for theme picker |
| 10 | **E10** | `Ctrl+Z` / `Ctrl+Shift+Z` undo for drag actions |

**PR title:** varies — split into 2-3 sub-PRs grouped by surface (sidebar, canvas, export).

---

### Wave 6 — Aesthetic alignment

Lands after everything else so it's a distinct, reviewable design pass.

| # | ID | What |
|---|---|---|
| 1 | **E1** | Adopt `frontend-design` aesthetic per theme (no Segoe/Cascadia/Fira as defaults) |
| 2 | **E2** | Resolve tier-color collisions in each theme |
| 3 | **E3** | Sync `claude` theme with Anthropic brand-guidelines palette |

**PR title:** `feat(template): visual design pass — per-theme typography + tier palettes`

**Done when:** each theme is visually distinct in both color and typography; no two tiers share an identical color within a theme.

---

### Wave 7 — New commands and capabilities

Only after the audit backlog above is cleared. Each feature is its own PR.

| # | ID | What |
|---|---|---|
| 1 | **F4** | `/archmap:theme <name>` |
| 2 | **F7** | Git history overlay (module churn heatmap) |
| 3 | **F5** | `/archmap:query "<question>"` |
| 4 | **F6** | `/archmap:export png\|svg\|pdf` (CLI, complements the UI button) |
| 5 | **F1** | `/archmap:compare <a> <b>` (already queued per snapshot.md) |
| 6 | **F2** | `/archmap:at <ref>` (already queued per snapshot.md) |
| 7 | **F3** | In-canvas snapshot diff animation |
| 8 | **F8** | Module grouping / collapsible subgraphs |
| 9 | **F9** | In-UI notes editor with download-patch |
| 10 | **F10** | Auto-PNG sidecar on `/archmap:snapshot` |
| 11 | **F11** | Multi-map workspace with cross-links |

## Tickets not scheduled in any wave

These are either low-priority edge cases or intentionally deferred:

- **B11** — hook basename false-positive (low signal; keep as-is until users report noise)
- **B12** — schema `additionalProperties: false` on `hooks` (cosmetic; address on next schema bump)
- **B15** — `head -n 2000` cap in staleness detection (low probability)
- **E15** — delete or document `exportMarkdown()` as public console API (wait for a concrete caller to appear)
- **E16** — extend `architecture` skill to use `history[]` (low urgency)

## Cadence

Aim for one wave per session. Waves 1-2 are small enough to complete in a single short session. Wave 3 should be its own session. Wave 4 is a half-day of infrastructure work. Waves 5-6 are distinct days. Wave 7 is ongoing feature work, not a rush.
