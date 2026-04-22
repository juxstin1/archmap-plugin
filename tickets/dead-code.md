# Dead Code — Round 2

Things to delete. 5 items. Each costs zero functionality and removes noise.

Note: D1-D2-D5 overlap with bugs B3-B4-B5 respectively — same files/lines, different framing. Close both IDs with the same commit.

---

### D1. `showAllLabels` toggle
**Severity:** low (paired with B3)
**Status:** open
**Location:** `templates/archmap-template.html:611, :336, :948`
**Problem:** Declared, toggled by a button, never read. Identical dead-code situation to the round-1 audit — but the round-1 fix landed on the abandoned `master` branch and never made it to `main`.
**Fix:** Delete the variable declaration, the `toggleLabels()` function, and the "Toggle Labels" button markup.
**Done when:** `grep -E 'showAllLabels|toggleLabels|Toggle Labels' templates/archmap-template.html` returns nothing.

---

### D2. `currentThemeName` variable
**Severity:** low (paired with B4)
**Status:** open
**Location:** `templates/archmap-template.html:477, :572`
**Problem:** Assigned in `applyTheme`, never read. Same dead-code situation as round-1. Active theme is already implicit via `T` and persisted via localStorage.
**Fix:** Delete the declaration and the assignment line inside `applyTheme`.
**Done when:** `grep currentThemeName templates/archmap-template.html` returns nothing.

---

### D3. `layoutDirty` flag
**Severity:** low
**Status:** open
**Location:** `templates/archmap-template.html:619, :811, :997`
**Problem:** Set to `true` in the drag mousemove handler, reset to `false` in `resetLayout`, never read. `hasLayoutOverrides()` already computes the same signal from `_origX/_origY` comparison — it's what actually drives the Save/Reset button visibility. `layoutDirty` is mirror state nobody consults.
**Fix:** Delete the declaration and the two assignments.
**Done when:** `grep layoutDirty templates/archmap-template.html` returns nothing and the Save/Reset buttons still toggle correctly on drag.

---

### D4. Explorer fallback prompt in `generate.md`
**Severity:** low
**Status:** open
**Location:** `commands/generate.md:109-123`
**Problem:** Documents a fallback for using the built-in `Explore` agent if `archmap-explorer` isn't available. Since the plugin bundles the agent, this path is unreachable. Adds ~15 lines of noise to an already-long command doc and gives no signal to readers.
**Fix:** Delete the "If you must fall back to built-in `Explore`" paragraph and its embedded prompt block.
**Done when:** `commands/generate.md` no longer contains the fallback prompt block; command length drops by ~15 lines.

---

### D5. Hardcoded `tierOrder` array in `buildMarkdown`
**Severity:** low (paired with B5)
**Status:** open
**Location:** `templates/archmap-template.html:1244`
**Problem:** Second source of truth for tier ordering. `THEMES.dark.tiers` already enumerates tiers; this array duplicates and disagrees with it.
**Fix:** `const tierOrder = Object.keys(THEMES.dark.tiers);` — single source of truth.
**Done when:** Adding a new tier to `THEMES` automatically flows into `buildMarkdown`'s sort order without a second edit.
