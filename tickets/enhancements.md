# Enhancements — Round 2

Improvements to existing behavior. 17 items. Not bugs — the code works, but could be better.

---

### E1. Adopt `frontend-design` aesthetic
**Severity:** medium
**Status:** open
**Location:** `templates/archmap-template.html:13, :99, :123, :193, :226, :239, :691`
**Problem:** Still defaults to `'Segoe UI'` / `'Cascadia Code'` / `'Fira Code'`. Anthropic's `frontend-design` skill (277k+ installs) explicitly flags Inter/Roboto/Arial/Segoe as "AI slop" fonts. Every map looks like the same template.
**Fix:** Per-theme distinctive font pairing — e.g., `dark` → Space Mono / IBM Plex (brutalist), `light` → Fraunces / JetBrains Mono (editorial), `claude` → Lora / Poppins (warm, matches brand-guidelines), `openai` → Berkeley Mono / Söhne-alt (technical). Embed minimal woff2 files to keep self-contained, or commit to carefully-picked system fallbacks.
**Done when:** Each theme is typographically distinct with the rendering disabled, and no theme uses Segoe/Cascadia/Fira/Inter/Roboto.

---

### E2. Resolve tier-color collisions in every theme
**Severity:** medium
**Status:** open
**Location:** `templates/archmap-template.html:386-391, :410-414, :434-438, :458-462`
**Problem:** Each theme has 5-6 tier pairs sharing a color:
- `dark`: entry/data, codegen/api, lint/ui, frontend/driver/test, infra/util, ir/config
- Same pattern in `light`, `claude`, `openai`
Two blue modules from different tiers on the same canvas is confusing. Legend becomes redundant.
**Fix:** Either (a) expand to 14 distinct colors per theme (careful color-science work), or (b) keep the reuse but visually differentiate via secondary marker — dashed border, tier-glyph, pattern overlay.
**Done when:** Every tier is visually identifiable on-canvas without consulting the legend.

---

### E3. Sync `claude` theme with Anthropic's official brand palette
**Severity:** low
**Status:** open
**Location:** `templates/archmap-template.html:426-449`
**Problem:** The `claude` theme uses approximation colors (`#d4874b` orange, `#1c1510` bg) that don't match Anthropic's published brand-guidelines palette (`#141413`, `#faf9f5`, `#d97757`, `#6a9bcc`, `#788c5d`). "Inspired by," not on-brand.
**Fix:** Swap CSS variables to the official hex codes. Remap tier colors to distribute brand orange/blue/green. Consider bg: `#141413` (brand dark) vs current `#1c1510` (warm dark).
**Done when:** Side-by-side comparison with anthropic.com shows the `claude` theme using the same base palette.

---

### E4. Timeline label has no overflow tooltip
**Severity:** low
**Status:** open
**Location:** `templates/archmap-template.html:266-276` (CSS), `:1149` (label population)
**Problem:** `#timeline-label` has `overflow: hidden; text-overflow: ellipsis; max-width: 280px`. When the version+date+note combo exceeds 280px, the ellipsis hides the tail. No `title` attribute on the label span, so users can't see the full text.
**Fix:** Set `label.title = label.textContent` in `updateTimelineUI` so hover gives the full version/date/note.
**Done when:** A long-named snapshot (e.g., `v1.3 · 2026-04-01 · "refactored all auth and payment logic for Stripe migration"`) shows the full text on hover.

---

### E5. Add a fixture/simulated-user test harness
**Severity:** medium
**Status:** open
**Location:** new `tests/fixtures/` + `tests/run.sh`
**Problem:** CI validates manifest shape and template placeholders but never exercises any command end-to-end. A regression in the template JS, a command-file edit that breaks placeholder substitution, or a schema change that breaks round-trip — none of it is caught by CI today.
**Fix:** Create 4 fixture repos:
- `tests/fixtures/monorepo/` — 3 packages with cross-deps
- `tests/fixtures/single-file/` — one `main.py` with internal functions
- `tests/fixtures/polyglot/` — mixed TS/Python/Rust
- `tests/fixtures/drift-seed/` — old map + intentionally-changed source for diff testing

Add `tests/run.sh` that for each fixture:
1. Invokes each command via a scripted Claude Code session (or documents manual-run steps until scripting is possible)
2. Snapshots the resulting HTML output
3. Diffs against a committed baseline

Commit baselines. PR CI diffs them.
**Done when:** `bash tests/run.sh` exits 0 against baselines; a deliberate template bug causes the diff to fail.

---

### E6. Sidebar search / filter box
**Severity:** medium
**Status:** open
**Location:** `templates/archmap-template.html:328-331`
**Problem:** Navigating 30+ module maps requires pan-hunting. No text filter, no keyboard shortcut to jump to a module.
**Fix:** Add a search input at the top of the sidebar. On type, filter the legend and show a results list; clicking a result centers the canvas on that module and selects it. Keyboard shortcut `/` or `Ctrl+K` to focus.
**Done when:** Typing `auth` in a 30-module map narrows the results; Enter centers the canvas on the first match.

---

### E7. Show module XY position in inspector
**Severity:** low
**Status:** open
**Location:** `templates/archmap-template.html:881-921` (`showDetail`)
**Problem:** The inspector shows lines, types, functions, imports, notes — but not the module's current canvas position. Useful when debugging layout issues, composing collision-free placements, or sharing screenshots with coordinates.
**Fix:** Add a small `x, y` block near the `lines` subtitle. Greyed out in default layout, bolded when position differs from `_origX/_origY`.
**Done when:** Inspecting any module shows its current XY; dragging updates the shown value live.

---

### E8. Clickable dependencies in sidebar pan to the referenced module
**Severity:** low
**Status:** open
**Location:** `templates/archmap-template.html:904-915`
**Problem:** The "Used By" / "Depends On" lists are plain text. Users have to pan-hunt to the referenced module to inspect it.
**Fix:** Make each entry a clickable affordance. On click: select the target module, pan/zoom the canvas to center it, update the inspector.
**Done when:** Clicking `auth` under `Used By` jumps the canvas to `auth` and shows it in the inspector.

---

### E9. Surface current snapshot metadata in default sidebar
**Severity:** low
**Status:** open
**Location:** `templates/archmap-template.html:934-942` (`showDefaultSidebar`)
**Problem:** When a user scrubs to an older snapshot, the only indicator is the small timeline label. The main sidebar reads "Click a module to inspect it" — same as always. The user doesn't clearly know they're looking at history.
**Fix:** When `currentSnapshot < history.length - 1`, prepend a banner to the default sidebar: `Viewing v0.3 — 2026-03-15 — "added Stripe"` with a "Return to current" link. Subtle accent color to match the timeline.
**Done when:** Scrubbing to any non-newest snapshot shows a clear banner identifying which version is active.

---

### E10. Drag undo/redo
**Severity:** low
**Status:** open
**Location:** `templates/archmap-template.html:826-836` (mouseup), new keyboard binding
**Problem:** Reset Layout is an all-or-nothing hammer. A user who drags 10 modules then misplaces the 11th has no way back except reset-and-redo-everything.
**Fix:** Stack each drag's before/after positions in a capped array. `Ctrl+Z` / `Cmd+Z` pops and reverses. `Ctrl+Shift+Z` redoes.
**Done when:** Drag three modules, press `Ctrl+Z` three times — all three return to origin in reverse order.

---

### E11. `exportAll` fires two download prompts; should be one zip
**Severity:** low
**Status:** open
**Location:** `templates/archmap-template.html:1410-1441`
**Problem:** PNG downloads, 300ms pause, MD downloads. Some browsers (Safari, Firefox with strict settings) block the second as "multi-download." User sees only the PNG and doesn't know they missed the MD.
**Fix:** Bundle both into a single `.zip` using a minimal pure-JS zip writer (e.g., `fflate`'s zipSync ported inline — keep self-contained). One download, one prompt.
**Done when:** Clicking Export produces exactly one download prompt containing both files; Firefox strict mode no longer blocks the second.

---

### E12. Theme picker has no keyboard navigation
**Severity:** low
**Status:** open
**Location:** `templates/archmap-template.html:587-601`
**Problem:** Theme buttons are focusable `<button>` elements (Tab reaches them), but there's no arrow-key cycling. User has to Tab across them or click.
**Fix:** Add `←`/`→` handling within the theme picker (or a top-level shortcut `T` to cycle). Left cycles to previous theme, Right to next. Wraps.
**Done when:** Focus the theme picker, press `→` twice → third theme is active.

---

### E13. `resetLayout` uses native `confirm()`
**Severity:** low
**Status:** open
**Location:** `templates/archmap-template.html:994`
**Problem:** Native `confirm` is jarring, modal-blocking, and doesn't match the existing modal design (`save-layout-modal`). Inconsistent UX for a destructive action.
**Fix:** Replicate the Save Layout modal pattern for Reset. Primary button "Reset", secondary button "Cancel", match the existing styling.
**Done when:** Clicking Reset Layout shows a themed modal, not `confirm()`.

---

### E14. Respect `prefers-color-scheme` on first load
**Severity:** low
**Status:** open
**Location:** `templates/archmap-template.html:1453-1454`
**Problem:** First-time users always get `dark` regardless of OS preference.
**Fix:** `const saved = localStorage.getItem('archmap-theme'); const preferLight = window.matchMedia('(prefers-color-scheme: light)').matches; applyTheme(saved && THEMES[saved] ? saved : (preferLight ? 'light' : 'dark'));`
**Done when:** On a system in light mode with no localStorage value, opening a fresh map starts in the `light` theme.

---

### E15. Delete or document `exportMarkdown()` as public API
**Severity:** low
**Status:** open
**Location:** `templates/archmap-template.html:1443-1448`
**Problem:** Retained for "backwards compatibility with external callers / keybindings bound to exportMarkdown" — but nothing in the plugin calls it. If it's a public console API, that should be documented in the README. If it's vestigial, delete.
**Fix:** Grep GitHub for external uses; if none, delete. If some, document in README as `window.exportMarkdown()` and keep.
**Done when:** Function is either documented publicly or gone.

---

### E16. `architecture` skill doesn't leverage `history[]`
**Severity:** low
**Status:** open
**Location:** `skills/architecture/SKILL.md`
**Problem:** The skill reads current-state map data. With `history[]` now in the HTML, questions like "what changed between v0.2 and v0.3?" or "when was the auth module introduced?" could be answered from snapshots — but the skill's logic doesn't mention history.
**Fix:** Add a section to the skill: if the question involves temporality ("when", "changed", "before/after", version references), parse `history[]` from the HTML and answer from snapshot diffs.
**Done when:** Asking "when did the payment module appear?" against a map with history produces a specific version/date answer.

---

### E17. `/archmap:diff` needs a `--json` output mode
**Severity:** medium
**Status:** open
**Location:** `commands/diff.md`
**Problem:** Diff output is human-readable markdown only. CI integration ("fail PR if drift exceeds threshold") requires structured output.
**Fix:** Add a `--json` flag emitting `{ added: [], removed: [], renamed: [], resized: [], new_edges: [], broken_edges: [], tier_changes: [], verdict: string }`. Document a GitHub Actions example in the README.
**Done when:** `claude /archmap:diff --json | jq '.verdict'` prints `"current"` / `"slightly stale"` / `"needs repair"`.
