#!/usr/bin/env python3
"""
Build site/demo.html — a pre-rendered archmap of the archmap-plugin itself.

Substitutes real module/edge data describing the plugin's own architecture
into templates/archmap-template.html. The result is the same HTML that
`/archmap` would produce when run against this repository; it is checked
in so the landing page's live demo works without a build step on the
Pages runner.

Re-run whenever the plugin structure changes:

    python3 site/build-demo.py
"""
import html
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
TEMPLATE = ROOT / "templates" / "archmap-template.html"
OUTPUT = ROOT / "site" / "demo.html"

PROJECT_NAME = "archmap-plugin"

# Stats across the repo — rough, but honest.
STATS_HTML = (
    '<div><span class="stat-val">~2,400</span> lines</div>'
    '<div><span class="stat-val">14</span> files</div>'
    '<div><span class="stat-val">5</span> tiers</div>'
)

MODULES = [
    # ── Manifests (entry) ────────────────────────────────────────
    {"id": "plugin-manifest", "label": "plugin.json", "tier": "entry",
     "lines": 22, "x": 60, "y": 120, "w": 150, "h": 60,
     "desc": "Plugin manifest (name, version, hooks ref)",
     "details": {
        "types": [],
        "functions": [],
        "imports": ["hooks.json"],
        "notes": "The root manifest Claude Code reads to register this plugin. Declares version, description, hooks path, author, repository, license, and keywords. Component paths (commands, agents, skills) use defaults — never redeclare."
     }},
    {"id": "marketplace-manifest", "label": "marketplace.json", "tier": "entry",
     "lines": 28, "x": 60, "y": 210, "w": 150, "h": 60,
     "desc": "Marketplace entry for distribution",
     "details": {
        "types": [],
        "functions": [],
        "imports": ["plugin.json"],
        "notes": "Registered when users run /plugin marketplace add juxstin1/archmap-plugin. Lists the archmap plugin with its own version, author, homepage, and keywords."
     }},

    # ── Config ───────────────────────────────────────────────────
    {"id": "archmap-json", "label": ".archmap.json", "tier": "config",
     "lines": 30, "x": 60, "y": 300, "w": 150, "h": 60,
     "desc": "Per-project configuration (exclude, tiers, output, theme)",
     "details": {
        "types": [],
        "functions": [],
        "imports": [],
        "notes": "Optional, placed in each consumer's project root. Controls exploration excludes, tier overrides, pinned modules, output paths, default theme, and hooks.sessionStart opt-out. Every field has a sensible default."
     }},

    # ── Commands (api) ───────────────────────────────────────────
    {"id": "cmd-archmap", "label": "/archmap", "tier": "api",
     "lines": 246, "x": 280, "y": 90, "w": 160, "h": 60,
     "desc": "Generate a full architecture map from scratch",
     "details": {
        "types": [],
        "functions": ["Phase 0: load config", "Phase 1: dispatch explorer", "Phase 2: layout", "Phase 3: substitute template", "Phase 4: write HTML + markdown"],
        "imports": ["explorer agent", "template.html", ".archmap.json"],
        "notes": "Entry point of the whole pipeline. Reads .archmap.json, dispatches the explorer agent for full codebase analysis, lays modules by tier, substitutes the HTML template with escaped data, writes docs/architecture.html and docs/architecture-map.md atomically."
     }},
    {"id": "cmd-repair", "label": "/archmap:repair", "tier": "api",
     "lines": 221, "x": 280, "y": 180, "w": 160, "h": 60,
     "desc": "Detect and surgically fix stale / broken maps",
     "details": {
        "types": [],
        "functions": ["extract map state", "scan for drift", "patch staleness", "preserve user notes"],
        "imports": ["repair agent", "template.html"],
        "notes": "Parses the embedded JS variables in docs/architecture.html, dispatches the repair agent in scan mode, diffs results against existing modules/edges, patches staleness / layout / details / integrity issues. Pinned modules are never removed or re-tiered. User-customised details.notes are preserved."
     }},
    {"id": "cmd-focus", "label": "/archmap:focus", "tier": "api",
     "lines": 178, "x": 280, "y": 270, "w": 160, "h": 60,
     "desc": "Deep-dive and repair a specific module",
     "details": {
        "types": [],
        "functions": ["find target module", "re-explore deeply", "update module + edges"],
        "imports": ["repair agent", "template.html"],
        "notes": "Same repair intelligence as :repair but scoped to a single module. Re-explores that module in depth, updates its types / functions / edges, and patches the map in-place."
     }},
    {"id": "cmd-diff", "label": "/archmap:diff", "tier": "api",
     "lines": 172, "x": 280, "y": 360, "w": 160, "h": 60,
     "desc": "Drift report (read-only, never modifies the map)",
     "details": {
        "types": [],
        "functions": ["lightweight re-explore", "compare", "report drift"],
        "imports": ["repair agent"],
        "notes": "Read-only comparison between the current codebase and the existing map. Shows added / removed modules, new / broken dependencies, tier changes. Outputs a verdict: current, slightly stale, or needs repair. Does NOT touch docs/architecture.html."
     }},

    # ── Agents (driver) + Skill (lint) ───────────────────────────
    {"id": "agent-explorer", "label": "explorer agent", "tier": "driver",
     "lines": 198, "x": 500, "y": 100, "w": 160, "h": 60,
     "desc": "Full codebase exploration from scratch",
     "details": {
        "types": [],
        "functions": ["discover source files", "extract types / functions", "infer dependencies", "infer data flow pipeline"],
        "imports": [],
        "notes": "Dispatched only by /archmap. Thoroughness: very thorough. Reports every module's path, types, public functions, internal imports, and role. Caps module count at 80 for large monorepos; honours .archmap.json excludes."
     }},
    {"id": "agent-repair", "label": "repair agent", "tier": "driver",
     "lines": 258, "x": 500, "y": 220, "w": 160, "h": 60,
     "desc": "Targeted re-exploration for repair / focus / diff",
     "details": {
        "types": [],
        "functions": ["scan mode: check everything for drift", "focus mode: deep-dive one module"],
        "imports": [],
        "notes": "Two modes. Scan mode verifies every module's files still exist and picks up new files in mapped tiers. Focus mode narrows to a single target and returns a full re-profile. Shared by /archmap:repair, /archmap:focus, and /archmap:diff."
     }},
    {"id": "skill-arch", "label": "architecture", "tier": "lint",
     "lines": 82, "x": 500, "y": 340, "w": 160, "h": 60,
     "desc": "Auto-activating skill for architecture Q&A",
     "details": {
        "types": [],
        "functions": ["detect arch questions", "read map data", "answer from map"],
        "imports": ["template.html"],
        "notes": "Triggers on phrases like 'how does this codebase work?' or 'what is the architecture of X'. Answers from existing docs/architecture.html + docs/architecture-map.md rather than re-exploring the codebase."
     }},

    # ── Runtime (HTML template) ──────────────────────────────────
    {"id": "template-html", "label": "archmap-template.html", "tier": "runtime",
     "lines": 720, "x": 720, "y": 180, "w": 180, "h": 80,
     "desc": "Self-contained HTML canvas visualization",
     "details": {
        "types": ["modules[]", "edges[]", "THEMES{dark,light,claude,openai}"],
        "functions": ["applyTheme()", "draw()", "drawModule()", "drawEdge()", "edgePoint()", "hitTest()", "showDetail()", "exportMarkdown()", "esc()", "safeColor()"],
        "imports": [],
        "notes": "The canvas target of template substitution. Pan, zoom, click-to-inspect. Four theme presets. Markdown export. No CDN, no external scripts, no fonts. XSS-hardened: every project-supplied string routes through esc() before innerHTML, color values through safeColor()."
     }},

    # ── Hooks (infra) ────────────────────────────────────────────
    {"id": "hooks-json", "label": "hooks.json", "tier": "infra",
     "lines": 28, "x": 940, "y": 100, "w": 160, "h": 60,
     "desc": "SessionStart + PostToolUse hook wiring",
     "details": {
        "types": [],
        "functions": [],
        "imports": ["detect-unmapped.sh", "flag-stale-modules.sh"],
        "notes": "Wires the two hook scripts. SessionStart fires on session open; PostToolUse fires on Write|Edit. Both scripts receive payloads via stdin per the Claude Code hook spec."
     }},
    {"id": "hook-detect", "label": "detect-unmapped.sh", "tier": "infra",
     "lines": 105, "x": 940, "y": 210, "w": 160, "h": 60,
     "desc": "SessionStart: missing / stale map detection",
     "details": {
        "types": [],
        "functions": ["map_mtime()", "check_git_staleness()"],
        "imports": [".archmap.json"],
        "notes": "Runs on every session start. Uses git ls-files when available (fast, gitignore-aware) and falls back to depth-capped find otherwise. Honours .archmap.json output.html override and the hooks.sessionStart: false opt-out. set -euo pipefail; exits 0 on every failure path."
     }},
    {"id": "hook-flag", "label": "flag-stale-modules.sh", "tier": "infra",
     "lines": 89, "x": 940, "y": 320, "w": 160, "h": 60,
     "desc": "PostToolUse: flag edits of mapped files",
     "details": {
        "types": [],
        "functions": [],
        "imports": [".archmap.json"],
        "notes": "Reads the tool payload from stdin, extracts file_path via jq (or a conservative regex fallback), and searches the map's modules block with grep -F for literal-match safety. Scoped between the 'Project Data' and 'Theme Engine' anchor comments so it can't false-match on CSS or comment text."
     }},
]

EDGES = [
    {"from": "plugin-manifest", "to": "cmd-archmap", "label": "declares"},
    {"from": "plugin-manifest", "to": "cmd-repair", "label": "declares"},
    {"from": "plugin-manifest", "to": "cmd-focus", "label": "declares"},
    {"from": "plugin-manifest", "to": "cmd-diff", "label": "declares"},
    {"from": "plugin-manifest", "to": "hooks-json", "label": "wires"},
    {"from": "marketplace-manifest", "to": "plugin-manifest", "label": "distributes"},
    {"from": "archmap-json", "to": "cmd-archmap", "label": "configures"},
    {"from": "archmap-json", "to": "hook-detect", "label": "configures"},
    {"from": "archmap-json", "to": "hook-flag", "label": "configures"},
    {"from": "cmd-archmap", "to": "agent-explorer", "label": "dispatches"},
    {"from": "cmd-repair", "to": "agent-repair", "label": "dispatches"},
    {"from": "cmd-focus", "to": "agent-repair", "label": "dispatches"},
    {"from": "cmd-diff", "to": "agent-repair", "label": "dispatches"},
    {"from": "cmd-archmap", "to": "template-html", "label": "writes"},
    {"from": "cmd-repair", "to": "template-html", "label": "patches"},
    {"from": "cmd-focus", "to": "template-html", "label": "patches"},
    {"from": "skill-arch", "to": "template-html", "label": "reads"},
    {"from": "hooks-json", "to": "hook-detect", "label": "SessionStart"},
    {"from": "hooks-json", "to": "hook-flag", "label": "PostToolUse"},
    {"from": "hook-detect", "to": "template-html", "label": "checks mtime"},
    {"from": "hook-flag", "to": "template-html", "label": "searches"},
]

TIER_LABELS = [
    {"label": "MANIFESTS / CONFIG", "x": 70, "y": 60},
    {"label": "COMMANDS", "x": 310, "y": 60},
    {"label": "AGENTS / SKILL", "x": 510, "y": 60},
    {"label": "RUNTIME", "x": 740, "y": 60},
    {"label": "HOOKS", "x": 965, "y": 60},
]

PIPELINE = [
    {"type": "label", "text": "User runs /archmap"},
    {"type": "arrow", "text": "Load .archmap.json"},
    {"type": "label", "text": "Dispatch explorer agent"},
    {"type": "arrow", "text": "Modules + edges + tiers"},
    {"type": "label", "text": "Substitute HTML template"},
    {"type": "arrow", "text": "Write docs/architecture.html"},
    {"type": "label", "text": "Emit docs/architecture-map.md"},
]

LEGEND = [
    {"tier": "entry", "label": "Manifests"},
    {"tier": "config", "label": "Config"},
    {"tier": "api", "label": "Slash commands"},
    {"tier": "driver", "label": "Agents"},
    {"tier": "lint", "label": "Skills"},
    {"tier": "runtime", "label": "HTML template"},
    {"tier": "infra", "label": "Hooks"},
]


def safe_json(obj):
    """JSON.stringify equivalent with </script> neutralisation."""
    s = json.dumps(obj, ensure_ascii=False)
    return s.replace("</script", "<\\/script").replace("</SCRIPT", "<\\/SCRIPT")


def main():
    template = TEMPLATE.read_text(encoding="utf-8")

    # HTML-context substitutions — the project name appears in <title>,
    # <h1>, and a data-project-name attribute. HTML-escape once.
    escaped_name = html.escape(PROJECT_NAME, quote=True)

    substitutions = {
        "{{PROJECT_NAME}}": escaped_name,
        "{{STATS_HTML}}": STATS_HTML,
        "{{MODULES_JSON}}": safe_json(MODULES),
        "{{EDGES_JSON}}": safe_json(EDGES),
        "{{TIER_LABELS_JSON}}": safe_json(TIER_LABELS),
        "{{PIPELINE_JSON}}": safe_json(PIPELINE),
        "{{LEGEND_JSON}}": safe_json(LEGEND),
    }

    out = template
    for placeholder, value in substitutions.items():
        if placeholder not in out:
            print(f"error: placeholder {placeholder} not found in template",
                  file=sys.stderr)
            sys.exit(1)
        out = out.replace(placeholder, value)

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(out, encoding="utf-8")
    print(f"wrote {OUTPUT.relative_to(ROOT)} ({len(out):,} bytes)")


if __name__ == "__main__":
    main()
