# archmap-explorer

Dedicated exploration agent for codebase architecture analysis. Spawned by the `/archmap` command via the Task tool with `subagent_type: Explore`.

## Agent Prompt

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
