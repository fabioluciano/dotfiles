# Global OMP Agent Instructions

## Session Startup & Project Lifecycle

Whenever starting work in a session or addressing a repository-related task:

1. **Read the repository conventions first** — the project's own `AGENTS.md`, docs and build files, before exploring or changing code.
2. **Search before opening** — locate the relevant files with `grep`/`glob` (or `xd://ast_grep` for structure); never open guessed paths.
3. **Call only tools that exist in this session** — MCP server tools are invoked by their full name (`mcp__<server>_<tool>`), **not** through `read xd://...`. `read xd://<tool>` only resolves the built-in devices (`lsp`, `ast_grep`, `github`, `debug`, `checkpoint`, `rewind`, `security_scan`) and the MCP tools listed in this session's inventory. A tool that is not listed does not exist: skip it, and never retry it with another spelling.

---

## Do not hallucinate!

**Do not hallucinate!** Never invent APIs, functions, flags, file paths, commands, tool names or tool parameters without verification. Verify with the session's tools first: `grep`/`glob`/`read` and `xd://lsp` for the repository, `context7` for library documentation, `serena` for symbols. If you could not verify something, say "I don't know" or mark it as inference. Ground every claim in evidence you actually observed; never report a result you did not see.

---

## Tool Selection Principles

- **Code search**: `grep` (regex over files), `glob` (names/structure), `xd://ast_grep` (AST patterns), `xd://lsp` (definitions, references, diagnostics, hover).
- **Files**: `read` with a line-range selector for inspection, `edit` for surgical changes, `write` only for new files or full rewrites.
- **Shell**: `bash` only for build, tests, linters, package managers and git.
- **MCP servers (ALWAYS use the ones available)**: when a mounted MCP server fits the task, you MUST use it instead of guessing or falling back to a weaker tool. Check the session's tool inventory at the start of every task. Tools are named `mcp__<server>_<tool>` (server and tool lowercased, `-` replaced by `_`, e.g. `mcp__context7_resolve_library_id`).
- **Strict Schema Adherence (Zero Parameter Hallucination)**: never invoke an MCP tool with guessed names or parameters. The session's tool inventory is the only source of truth for names and schemas; a tool that is not listed there does not exist: skip it and do not probe it through another path.
- **Which server for what** (use whichever of these is mounted):
  - `serena`: semantic code navigation (symbols, references, call graphs). Call `mcp__serena_initial_instructions` before the first Serena use.
  - `context7`: current library/framework/SDK/CLI documentation, even for well-known ones; prefer it over memory and over web search.
  - `sequential-thinking`: ambiguous multi-step problems and architecture trade-offs.
  - `gh_grep`: real-world public code examples (literal code syntax queries only).
  - `github`: GitHub platform operations; creating issues/PRs, commenting, pushing or triggering workflows needs explicit user instruction.
---

## Skills

- OMP discovers user skills in `~/.agents/skills` and project-local skill directories.
- **ALWAYS use the available skills**: before acting on any task (including exploring or asking questions), check the skill list in the session; if a skill matches, you MUST read it with `read skill://<name>/SKILL.md` and follow it. Do not skip a matching skill because the task looks simple.
- Skills define specialized workflows; they are never authorization for destructive actions.
- Do not install, update, or publish skills without explicit user instruction.

---

## Memory and Context

- Use long-term memory to retrieve persistent user preferences and prior architectural decisions; confirm technical decisions in the active repository. Explicit user instructions and current file state always take precedence over recalled memories.
- Never store secrets, tokens, credentials, or personal sensitive data in memory.
- Do not load the *same* skill or MCP tool twice in one session, and do not load ones unrelated to the task; every applicable skill and MCP server must still be used.
