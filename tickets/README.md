# Archmap Tickets — v1.1.0 Audit (Round 2)

Fresh audit conducted 2026-04-21 against `main` at commit `03c8691`. This supersedes the 2026-04-12 audit that was based on stale `master` tree; most of that work shipped in v1.1.0 already.

## Files

- [build-order.md](build-order.md) — prioritized execution plan with rationale
- [bugs.md](bugs.md) — real defects (15)
- [enhancements.md](enhancements.md) — improvements to existing behavior (17)
- [features.md](features.md) — new capabilities (11)
- [dead-code.md](dead-code.md) — code to remove (5)

## Scope

Audit covered everything on `main`:

- 6 commands (`generate`, `repair`, `focus`, `diff`, `snapshot`, `history`)
- 2 agents (`archmap-explorer`, `archmap-repair-agent`)
- 1 skill (`architecture`)
- 2 hook scripts + config
- 1 HTML template (1498 lines)
- 3 JSON schemas
- 1 CI workflow
- Plugin and marketplace manifests

Total surface: 4527 LOC across 31 files.

## Ticket format

```
### <ID>. <Title>
**Severity:** critical | medium | low
**Status:** open | in-progress | done
**Location:** `path/to/file:line`
**Problem:** what's wrong and why it matters
**Fix:** the concrete change
**Done when:** acceptance criterion
```

## Status tracking

Each ticket file carries the authoritative status. Flip `open` → `in-progress` → `done` as work proceeds. When a ticket is closed by a commit, note the short SHA next to `done`.

## Relationship to round-1 tickets

The round-1 tickets directory from master does not exist on main (master was deleted). Any ID collisions between round-1 and round-2 (e.g., both audits had a `D1`) are coincidence — tickets here are authoritative for current work.

Several round-1 findings were already closed on main in v1.1.0 before this audit:
- Dangling edges guarded (round-1 B4) ✓
- `modules.sort` cloned (round-1 B5) ✓
- Hook reads stdin JSON (round-1 B2) ✓
- Grep uses `-F` (round-1 B3) ✓
- XSS hardening beyond round-1 B6

Not closed on main and re-discovered here:
- `showAllLabels` dead (now B3/D1)
- `currentThemeName` dead (now B4/D2)
- Hardcoded tier order in exportMarkdown (now B5/D5)
- Mouse click-vs-drag math (now B6)
