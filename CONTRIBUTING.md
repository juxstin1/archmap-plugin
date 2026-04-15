# Contributing to Archmap

Thanks for your interest in improving Archmap. Contributions of all sizes are welcome — bug reports, fixes, new themes, better agent prompts, docs, and tests.

## Getting set up

```bash
git clone https://github.com/juxstin1/archmap-plugin.git
cd archmap-plugin
claude --plugin-dir "$(pwd)"
```

This runs Claude Code with your working copy loaded as a live plugin. Any edit to a command, agent, skill, or hook is picked up on the next invocation — no rebuild step.

## Project layout

See [the Repository layout section of the README](./README.md#repository-layout). Archmap is a Claude Code plugin: no build system, no package manager, no tests in the traditional sense. The components are:

- **`commands/*.md`** — slash-command prompt definitions (`/archmap`, `/archmap:repair`, …)
- **`agents/*.md`** — prompts for dispatched Task agents
- **`skills/architecture/SKILL.md`** — auto-activating skill for architecture Q&A
- **`hooks/scripts/*.sh`** — bash scripts wired up via `hooks/hooks.json`
- **`templates/archmap-template.html`** — the self-contained HTML canvas target of `{{…}}` substitution

`CLAUDE.md` is the canonical architecture reference. Read it before making non-trivial changes.

## Coding standards

- **File and directory names:** kebab-case.
- **Markdown component files** (commands, agents, skills) use YAML frontmatter between `---` delimiters.
- **HTML template must remain fully self-contained** — no external scripts, stylesheets, fonts, or CDN links. The whole point is that the output works offline from a single file.
- **Canvas colors** come from the active theme (`applyTheme()`); never hardcode tier colors on modules.
- **Tier keys** used in any module must exist in every theme's `tiers` object (`entry`, `frontend`, `ir`, `codegen`, `runtime`, `lint`, `driver`, `data`, `api`, `ui`, `infra`, `util`, `test`, `config`).
- **Hook scripts** must start with `set -euo pipefail`, exit `0` on every failure path, and never hardcode paths — use `${CLAUDE_PLUGIN_ROOT}` in `hooks.json`.
- **Template substitution is security-critical** — see the Phase 3 documentation in `commands/archmap.md` for the HTML-escape vs JSON-encode rules for each placeholder.

## Running and testing your changes

Because this is a prompt-driven plugin, manual smoke testing is the primary QA path. Before opening a PR:

1. Run `/archmap` against at least two different repos (a small script and a larger multi-language codebase) and confirm the HTML renders, modules have the right tiers, and the inspector works.
2. Run `/archmap:repair` after a small code change and confirm only the changed modules get touched.
3. Run `/archmap:diff` and confirm the drift report is readable.
4. For hook changes, smoke-test with a scratch repo and `bash hooks/scripts/*.sh < payload.json`.

If your change affects the HTML template, open the generated `docs/architecture.html` in a browser and verify:
- Canvas renders, pan/zoom work, sidebar inspector populates on click
- All four themes apply cleanly (no unstyled fallbacks)
- Export MD button produces a well-formed markdown file

## Commit style

We use short, imperative-mood commit subjects with a type prefix:

```text
fix(hooks): rewrite both scripts for correctness and portability
feat(commands): add /archmap:diff
docs(readme): document .archmap.json schema
```

Types we use: `feat`, `fix`, `docs`, `refactor`, `chore`, `perf`.

## Pull requests

1. Fork and create a branch off `main` with a descriptive name (`fix/hook-stdin`, `feat/rust-preset`).
2. Keep PRs focused — one concern per PR is easier to review.
3. Update `CHANGELOG.md` under `[Unreleased]` with a one-line entry.
4. Fill out the PR template. If your change is behavioural, include a short manual test plan.
5. Be patient — code review on a solo-maintained repo is best-effort.

## Reporting bugs

Open an issue via the bug template at [Issues › New issue](https://github.com/juxstin1/archmap-plugin/issues/new/choose). Include:

- Archmap version (`cat .claude-plugin/plugin.json | jq -r .version`)
- Claude Code version
- OS and shell (bash/zsh, macOS/Linux/WSL)
- Steps to reproduce, expected vs actual behavior
- The relevant portion of `.archmap.json` if any
- If the bug is in the HTML output, attach the generated `docs/architecture.html`

## Security

Do **not** open public issues for security bugs. Follow the process in [SECURITY.md](./SECURITY.md).
