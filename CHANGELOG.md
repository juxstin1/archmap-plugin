# Changelog

All notable changes to Archmap are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Security
- Hardened the HTML template against stored XSS. Every project-supplied string
  (module labels, descriptions, notes, edge labels, pipeline and legend text)
  is now escaped before being interpolated into `innerHTML`.
- CSS color values in `style="color:…"` contexts are now validated against an
  allowlist of hex, `rgb()`, and `var(--*)` tokens.
- `PROJECT_NAME` is no longer embedded as a JS string literal in
  `exportMarkdown`; it is read from a `data-project-name` attribute on `<body>`
  so quotes, newlines, or script-closing sequences in the project name cannot
  escape string context. The substitution contract in `commands/archmap.md` now
  documents the required HTML-escape vs. JSON-encode discipline per placeholder.

### Fixed
- `edgePoint()` now zero-guards the overlapping-box case (two modules with
  identical centers no longer produce NaN coordinates).
- `exportMarkdown()` sorts a copy of the `modules` array rather than mutating
  it in place; it also skips edges with missing endpoints.
- `flag-stale-modules.sh` now reads the tool payload from STDIN per the Claude
  Code hook spec (previously attempted to open an undocumented env var as a
  file path — broken on every platform). Uses `jq` when available and a
  conservative regex fallback when it isn't. Uses `grep -F` so paths with regex
  metacharacters can no longer false-match, and scopes the search to the map's
  modules block so edits can no longer collide with CSS/comment strings.
- `detect-unmapped.sh` now uses `git ls-files` when in a git repo for fast,
  `.gitignore`-aware staleness detection; falls back to a depth-capped `find`
  otherwise. Both paths exit well under the 10-second hook budget on large
  monorepos. `set -euo pipefail` throughout.
- Hardcoded author-specific tier labels (`"MCP Tools"`, `"FCPXML Format"`,
  `"AI Core"`, `"State Storage"`) that would have appeared in every generated
  map have been replaced with generic labels.

### Added
- `.archmap.json` now supports `hooks.sessionStart: false` to silence the
  session-start staleness nudge.
- Hook scripts honour the `.archmap.json` `output.html` override when locating
  the map file.
- README documents the `.archmap.json` schema in full, real marketplace install
  instructions, and a troubleshooting section.
- `CHANGELOG.md`, `CONTRIBUTING.md`, `SECURITY.md`, issue and pull-request
  templates, and a GitHub Actions workflow for plugin validation on push/tag.
- `.claude-plugin/marketplace.json` is now populated with full plugin metadata
  for marketplace distribution.
- `plugin.json` now declares `repository`, `homepage`, `bugs`, and a richer
  keyword set; redundant default component paths were removed.
- Hook scripts are now executable (`100755`) in the git index so they run on a
  fresh clone.

## [1.0.0] — 2026-02-10

### Added
- Initial public release.
- `/archmap` — generate a full architecture map from scratch.
- `/archmap:repair` — surgically patch stale, broken, or drifted maps.
- `/archmap:focus <module>` — deep-dive and repair a single module.
- `/archmap:diff` — read-only drift report between the current codebase and
  the existing map.
- `archmap-explorer` and `archmap-repair-agent` agents.
- `architecture` skill that auto-activates for architecture questions.
- SessionStart and PostToolUse hooks for missing/stale-map detection.
- Self-contained HTML canvas visualization with four theme presets (Dark,
  Light, Claude, OpenAI), pan/zoom, module inspector, and markdown export.
- `.archmap.json` configuration support.

[Unreleased]: https://github.com/juxstin1/archmap-plugin/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/juxstin1/archmap-plugin/releases/tag/v1.0.0
