## Summary

<!-- 1-3 sentences on what this PR changes and why. -->

## Type of change

- [ ] Bug fix
- [ ] New feature (command, theme, agent capability, hook)
- [ ] Template / visualization change
- [ ] Docs
- [ ] Refactor / chore
- [ ] Security

## Related issues

<!-- "Closes #123" or "Refs #456". Leave blank if none. -->

## Test plan

<!-- What did you actually run? -->

- [ ] Ran `/archmap:generate` against a small repo and verified the HTML opens and renders
- [ ] Ran `/archmap:repair` / `/archmap:focus` / `/archmap:diff` as relevant
- [ ] Opened `docs/architecture.html` in a browser and clicked through the inspector
- [ ] Switched themes (dark / light / claude / openai) and verified no unstyled fallbacks
- [ ] For hook changes: smoke-tested with `bash hooks/scripts/*.sh < payload.json`
- [ ] For template changes: verified `exportMarkdown()` output is well-formed

## Checklist

- [ ] Updated `CHANGELOG.md` under `[Unreleased]` if user-visible
- [ ] Updated `README.md` / `CLAUDE.md` if behavior or configuration changed
- [ ] No new external dependencies in the HTML template (still self-contained)
- [ ] Hook scripts have `set -euo pipefail` and exit 0 on failure paths
- [ ] New tier keys (if any) exist in every theme's `tiers` object
