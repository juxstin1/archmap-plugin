---
name: architecture
description: Auto-activates when users ask about codebase structure, architecture, module relationships, or how the codebase works. Leverages existing architecture maps if available.
---

# Architecture Intelligence

Provides contextual architecture answers by leveraging existing archmap-generated documentation. Activates when users ask questions like:

- "How does this codebase work?"
- "What's the architecture?"
- "Explain the module structure"
- "How are these components connected?"
- "What depends on X?"
- "Where does data flow through?"
- "What layer is X in?"

## Behavior

### Step 1: Check for Existing Maps

Look for architecture documentation in the project:

1. Check if `docs/architecture-map.md` exists (preferred — structured, easy to parse)
2. Check if `docs/architecture.html` exists (fallback — can extract data from JS variables)
3. Check for `.archmap.json` configuration

### Step 2: Answer from Existing Data

**If `docs/architecture-map.md` exists:**
- Read the markdown file
- Use its structured content (Overview, Data Flow Pipeline, Architecture Layers, Module Details, Dependency Graph) to answer the user's question
- Cite specific modules, tiers, dependencies, and data flow paths
- If the question is about a specific module, find its section in Module Details

**If only `docs/architecture.html` exists:**
- Extract the JSON data from the embedded JavaScript (modules, edges, pipeline arrays)
- Use this data to answer the question
- Suggest running `/archmap:repair` to regenerate the markdown export

**If no maps exist:**
- Tell the user: "No architecture map found for this project. Run `/archmap` to generate one — it'll create an interactive visualization and structured documentation you can explore."
- Do NOT attempt to explore the codebase yourself — that's `/archmap`'s job
- You can still answer general architecture questions by reading key files (README, package.json, project structure), but note that a full map would provide better answers

### Step 3: Enrich with Context

When answering architecture questions:
- Reference the tier/layer system (entry, api, data, driver, etc.) to explain module roles
- Trace the data flow pipeline to show how input becomes output
- Use the dependency graph to explain coupling and relationships
- If a module seems stale (user is asking about something that doesn't match the map), suggest `/archmap:focus <module>` or `/archmap:repair`

## Response Style

- Lead with a direct answer, then provide supporting detail from the map
- Use the tier names and module labels from the map for consistency
- If the map has data flow pipeline info, reference it when explaining how things connect
- Don't dump the entire map — extract what's relevant to the specific question
- If the user asks a question that the map can't answer (e.g., runtime behavior, performance), say so and suggest what tools/approaches would help

## Important

- This skill is READ-ONLY — it never modifies maps or codebase files
- It's a knowledge layer, not a generation tool — it reads existing maps, it doesn't create them
- If the map data seems very outdated (e.g., references modules that clearly don't exist), mention this and suggest `/archmap:diff` to check for drift
