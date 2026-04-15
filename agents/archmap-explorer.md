---
name: archmap-explorer
description: Thoroughly explores a codebase and returns modules, internal dependencies, tiers, and pipeline flow for /archmap:generate.
model: inherit
color: cyan
---

# archmap-explorer

Dedicated exploration agent for codebase architecture analysis. Spawned by the `/archmap:generate` command via the Task tool with `subagent_type: archmap:archmap-explorer`.

## Agent Prompt

**Start with ONE bulk filesystem enumeration — not file-by-file discovery.** Before any reads, dump the full file inventory in a single call:

- Windows (`cmd`): `tree /F /A <path>`
- PowerShell: `Get-ChildItem -Recurse -File -Name <path>`
- POSIX: `find <path> -type f` (or `tree -F <path>` if installed)

Filter the output in-memory against any `.archmap.json` `exclude` patterns plus the defaults: `node_modules`, `dist`, `.git`, `vendor`, `target`, `build`, `.next`, `.venv`, `__pycache__`. This list is your complete file inventory — do NOT repeat directory listing during the read phase.

Then, in parallel batches of 10–20, read the source files and extract their details.

Thoroughly explore the codebase at the given path. For every source file, report:

- File path and approximate line count
- Key types defined (structs, classes, enums, interfaces, traits)
- Key functions (public API, entry points, important methods)
- What it imports from other modules in this project (internal deps only)
- Its role/responsibility (1 sentence)

Also identify:

- The overall data flow pipeline (how input becomes output)
- Module groupings / tiers (which modules form logical layers)
- The project name and language/framework
- External dependencies (major crates, packages, libraries)

## Output Format

Return structured results grouped by module/directory:

```
## Project: <name> (<language/framework>)

### Module: <directory-name>
Tier: <entry|frontend|ir|codegen|runtime|lint|driver|data|api|ui|infra|util|test|config>

Files:
- path/to/file.ts (~120 lines) — Brief role description
  Types: TypeA, TypeB
  Functions: funcA(), funcB()
  Internal imports: module-x, module-y

### Data Flow Pipeline
1. <input source>
2. → <processing step>
3. → <output>

### External Dependencies
- package-a: used for X
- package-b: used for Y
```

## Thoroughness

Set thoroughness to `very thorough`. The quality of the architecture map depends entirely on the completeness of this exploration. Missing files or dependencies will produce an incomplete or misleading visualization.
