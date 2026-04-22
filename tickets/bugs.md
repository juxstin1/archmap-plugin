# Bugs — Round 2

Real defects. 15 items, ordered by severity.

---

### B1. Timeline scrubber bleeds current-session drags into historical snapshots
**Severity:** critical
**Status:** open
**Location:** `templates/archmap-template.html:1085-1086`
**Problem:** When the user clicks a timeline tick, `setSnapshot` deep-clones the historical snapshot's `modules`, then calls `captureOriginalPositions(modules)` and `applyLayoutOverrides()`. `applyLayoutOverrides()` reads localStorage (where current-session drag positions live) and overlays them — regardless of which snapshot is active. A user who drags `auth` to `(500, 500)` in the current map and scrubs back to `v0.1` will see `auth` at `(500, 500)` in the old snapshot too, even though historically it was at `(340, 160)`. The scrubbed view is no longer a faithful render of history.
**Fix:** In `setSnapshot`, skip the localStorage overlay. Only the newest snapshot (index `history.length - 1`) should reflect current user drags; historical snapshots should render exactly what's in `snap.modules`. One line: guard the `applyLayoutOverrides()` call with `if (idx === history.length - 1)`.
**Done when:** Drag a module in the current view, save, scrub to an older snapshot — the dragged module renders at its historical position, not the current one. Scrubbing back to newest restores the drag.

---

### B2. `PostToolUse` hook matcher omits `MultiEdit`
**Severity:** critical
**Status:** open
**Location:** `hooks/hooks.json:17`
**Problem:** Matcher is `"Write|Edit"`. Claude Code's `MultiEdit` tool also writes to files but doesn't trigger the stale-map nudge. Every `MultiEdit` on a mapped file silently escapes detection.
**Fix:** Change the matcher to `"Write|Edit|MultiEdit"`.
**Done when:** Using `MultiEdit` on a file that appears in the map fires the "run /archmap:focus" nudge.

---

### B3. `showAllLabels` toggle still does nothing
**Severity:** medium (user-facing — the button lies)
**Status:** open
**Location:** `templates/archmap-template.html:611, :336, :948`
**Problem:** Declared at `:611`, toggled by `toggleLabels()` at `:948`, wired to a button at `:336`. Never read by any draw function. Clicking the button appears to do nothing — and from the user's perspective, that's exactly what happens.
**Fix:** Either delete the variable/function/button, or implement label toggling on the canvas. Recommend delete until there's a concrete design for a label-visibility toggle.
**Done when:** `grep showAllLabels templates/archmap-template.html` returns nothing and the Toggle Labels button is gone.

---

### B4. `currentThemeName` written but never read
**Severity:** low
**Status:** open
**Location:** `templates/archmap-template.html:477, :572`
**Problem:** Assigned inside `applyTheme`, never read elsewhere. Active theme is already tracked in `T` and persisted via the `archmap-theme` localStorage key.
**Fix:** Delete the variable and its assignment.
**Done when:** `grep currentThemeName templates/archmap-template.html` returns nothing.

---

### B5. Hardcoded Annie-era `tierOrder` in `buildMarkdown`
**Severity:** medium
**Status:** open
**Location:** `templates/archmap-template.html:1244`
**Problem:** The sort array `['entry', 'api', 'data', 'driver', 'codegen', 'util', 'frontend', 'ir', 'runtime', 'lint', 'ui', 'infra', 'test', 'config']` is the legacy FCP/Annie ordering, not the canonical order documented in CLAUDE.md (`entry, frontend, ir, codegen, runtime, lint, driver, data, api, ui, infra, util, test, config`). Two sources of truth that disagree.
**Fix:** Replace with `const tierOrder = Object.keys(THEMES.dark.tiers);` — `THEMES.dark.tiers` already enumerates tiers in the canonical order.
**Done when:** Adding a new tier requires updating only `THEMES`; exported markdown groups tiers in the documented order.

---

### B6. `mouseup` click-vs-drag math uses stale positions
**Severity:** medium
**Status:** open
**Location:** `templates/archmap-template.html:839`
**Problem:** `dragStartX` is set at mousedown as `e.clientX - viewX`. During mousemove, `viewX = e.clientX - dragStartX`, so `dragStartX + viewX` equals the *latest* mousemove clientX, not the mousedown clientX. The `< 3` threshold at mouseup therefore measures movement since the last mousemove frame, not total drag distance. A long pan that ends near the last reported position can false-positive as a click and trigger an unwanted module select.
**Fix:** Capture raw mousedown client coordinates in separate variables (`mouseDownClientX`, `mouseDownClientY`) at mousedown; compare against those at mouseup.
**Done when:** A long pan across the canvas never selects a module just because the mouse happened to stop over one.

---

### B7. Arrow-key timeline navigation double-fires through focused tick buttons
**Severity:** medium
**Status:** open
**Location:** `templates/archmap-template.html:1462-1487`
**Problem:** The keydown handler ignores INPUT/TEXTAREA/contentEditable but not `<button>`. Timeline tick buttons are real buttons (`templates/archmap-template.html:1119-1127`) — once the user has clicked one, arrow keys trigger both the browser's default button-focus navigation AND the snapshot navigation, producing jitter.
**Fix:** Blur the active element before `setSnapshot` fires, or add `e.target.tagName === 'BUTTON'` to the ignore list in the keydown handler.
**Done when:** After clicking a tick, pressing arrow keys moves one snapshot at a time, not two, and doesn't scroll-focus the ticks row unexpectedly.

---

### B8. `exportAll` doesn't null-check `renderToPng` result
**Severity:** medium
**Status:** open
**Location:** `templates/archmap-template.html:1421`
**Problem:** `canvas.toBlob()` can resolve to `null` if the canvas is tainted or empty. The returned `null` flows into `downloadBlob(pngBlob, pngName)` where `new Blob([null])` throws. The caught error is logged to console, but the user just sees the button flicker and no download.
**Fix:** Check `if (!pngBlob) throw new Error('PNG render returned no data')`. The existing catch already handles the error visibly.
**Done when:** An empty-map export (edge case) surfaces the failure via the button's UI state, not a silent console error.

---

### B9. Modules dragged off-screen persist off-screen
**Severity:** medium
**Status:** open
**Location:** `templates/archmap-template.html:800-814`
**Problem:** Drag handler accepts arbitrary coordinates with no bounds. A user can drag a module to `(-5000, -5000)` or `(99999, 99999)`, localStorage persists it, next page-load shows a module that can't be found without Reset Layout.
**Fix:** Clamp the drag destination to reasonable bounds (e.g., allow up to ±5000 from the current extent of all modules, or to the computed export bounds plus padding). Alternatively, detect out-of-bounds modules on load and snap them back to the viewport.
**Done when:** Dragging a module arbitrarily far and reloading still leaves it visible in the default viewport.

---

### B10. Mouseup cursor reset ignores edit mode
**Severity:** low
**Status:** open
**Location:** `templates/archmap-template.html:847`
**Problem:** After ending a pan (not a module drag) in edit mode, the cursor is unconditionally set to `'pointer'` or `'grab'` — ignoring that edit mode should show `'move'`/`'crosshair'`. Cosmetic but signals the wrong mode to the user.
**Fix:** Replicate the `editMode ? 'move' : 'pointer'` / `editMode ? 'crosshair' : 'grab'` pattern already used in the mousemove handler.
**Done when:** Panning in edit mode returns to the edit-mode cursor when the pan ends.

---

### B11. Hook basename fallback false-positives across paths
**Severity:** low
**Status:** open
**Location:** `hooks/scripts/flag-stale-modules.sh:72-93`
**Problem:** When the full path doesn't match, the script falls back to matching just the basename against the modules block. Editing `src/new/util.ts` when the map has `src/old/util.ts` triggers the nudge. Advisory-only, so not catastrophic, but noisy in mature repos.
**Fix:** Only fall back to basename when the full path is a *suffix* of a registered path (`grep -Fq -- "/<basename>"`) or is explicitly listed in the map. Keeps the signal when files are referenced as short names, kills the noise.
**Done when:** Editing a same-named file in a different directory than the mapped one does not fire the nudge.

---

### B12. Schema rejects future `hooks.*` config additions
**Severity:** low
**Status:** open
**Location:** `schemas/archmap.schema.json:55-64`
**Problem:** `hooks` object has `additionalProperties: false` with only `sessionStart` defined. Any future addition (`postToolUse: false`, new `onRepair` hook) breaks validation until the schema is updated in lockstep. Forward-compatibility footgun.
**Fix:** Either (a) loosen to `additionalProperties: { type: "boolean" }` for boolean-flag hooks, or (b) keep strict but document a clear schema-versioning plan.
**Done when:** Adding a new hook-config key to `.archmap.json` either validates or produces an informative "unknown hook" warning rather than a hard error.

---

### B13. CI workflow skips schema validation when no example exists
**Severity:** low
**Status:** open
**Location:** `.github/workflows/validate.yml:55-61`
**Problem:** The step only runs when `.archmap.json` exists at repo root. No example is committed, so the schema never validates in CI. A buggy schema could ship without anyone noticing.
**Fix:** Commit `examples/.archmap.json` with a realistic config covering every schema field, and point the CI step at it. Users can also copy it as a starter.
**Done when:** CI actually runs ajv against a committed example; breaking the schema in a PR fails CI.

---

### B14. Dead tier legend entries persist after repair
**Severity:** low
**Status:** open
**Location:** `templates/archmap-template.html:923-925` (render), `commands/repair.md` (generation)
**Problem:** `legendDotsHtml` renders whatever `legendItems` array was baked in. If `/archmap:repair` removes the last module of a tier without also pruning `legendItems`, the legend shows an orphan dot for a tier no module uses.
**Fix:** Filter at render time: `legendItems.filter(li => modules.some(m => m.tier === li.tier))`. Belt-and-suspenders with the command's responsibility.
**Done when:** Removing the last module of a tier via repair results in that tier disappearing from the legend on next render.

---

### B15. `detect-unmapped.sh` caps at 2000 tracked files
**Severity:** low
**Status:** open
**Location:** `hooks/scripts/detect-unmapped.sh:76`
**Problem:** `head -n 2000` means repos with more than 2000 tracked source files may miss staleness if the 2001st-onward file is newer than the map. Low probability but real for monorepos.
**Fix:** Either (a) raise the cap dramatically (10000) at the cost of a handful more ms, or (b) replace with `git ls-files -z | xargs -0 stat ...` piped through `sort -nk2 | tail -1` to find genuinely newest without a head cap.
**Done when:** On a repo with 3000 tracked source files where the newest-modified is at position 2500, the hook still detects staleness.
