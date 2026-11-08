# Global OMP Agent Instructions

## Session Startup & Project Lifecycle

Whenever starting work in a session or addressing a repository-related task:

1. **Read the repository conventions first** — the project's own `AGENTS.md`, docs and build files, before exploring or changing code.
2. **Search before opening** — locate the relevant files with `grep`/`glob` (or `xd://ast_grep` for structure); never open guessed paths.
3. **Call only tools that exist in this session** — MCP server tools are invoked by their full name (`mcp__<server>_<tool>`), **not** through `read xd://...`. `read xd://<tool>` only resolves the built-in devices (`lsp`, `ast_grep`, `github`, `debug`, `checkpoint`, `rewind`, `security_scan`) and the MCP tools listed in this session's inventory. A tool that is not listed does not exist: skip it, and never retry it with another spelling.

---

## Tool Selection Principles

- **Code search**: `grep` (regex over files), `glob` (names/structure), `xd://ast_grep` (AST patterns), `xd://lsp` (definitions, references, diagnostics, hover).
- **Files**: `read` with a line-range selector for inspection, `edit` for surgical changes, `write` only for new files or full rewrites.
- **Shell**: `bash` only for build, tests, linters, package managers and git.
- **MCP servers**: use one only when the task needs it *and* it is mounted in the session; call its tools by name with the exact schemas listed below.
- **Strict Schema Adherence (Zero Parameter Hallucination)**: never invoke an MCP tool with guessed names or parameters. Read the schema with `read xd://<tool>` **only** for a tool that appears in this session's inventory; MCP server tools are otherwise called directly by name, with the parameters documented in the server list below. When a tool is absent from the inventory, skip it — do not probe it through another path.
---


## Configured MCP Servers & Exact Schemas

The names below are the exact invocable names in this runtime: `mcp__<server>_<tool>`, where both the server name and the tool name are normalised to lowercase with `-` replaced by `_` (so the `context7` tool `resolve-library-id` is invoked as `mcp__context7_resolve_library_id`, and `gh_grep`'s `searchGitHub` as `mcp__gh_grep_searchgithub`). The parameter names in the schemas are the server's own, untouched — those keep their original casing (`libraryName`, `pullNumber`, `perPage`).

### 1. `serena`
- Use for semantic code navigation over an indexed repository: symbol search, references, call graphs and code snippets.
- **Exact Schemas**:
  - `mcp__serena_initial_instructions`: `{}` *(Call first to load the server usage manual)*
  - `mcp__serena_repl`: `{ session: string, code: string }` *(required: session, code)*

### 2. `context7`
- Use for retrieving current library and framework documentation when version details or API semantics matter. Prefer official upstream documentation.
- **Exact Schemas**:
  - `mcp__context7_resolve_library_id`: `{ query: string, libraryName: string }` *(required: query, libraryName — must be called first unless exact `/org/project` ID is already known)*
  - `mcp__context7_query_docs`: `{ libraryId: string, query: string, language?: string }` *(required: libraryId, query)*

### 3. `sequential-thinking`
- Use to decompose ambiguous multi-step reasoning problems or strategic architecture trade-offs.
- **Exact Schema**:
  - `mcp__sequential_thinking_sequentialthinking`: `{ thought: string, nextThoughtNeeded: boolean | string, thoughtNumber: number, totalThoughts: number, isRevision?: boolean | string, revisesThought?: number, branchFromThought?: number, branchId?: string, needsMoreThoughts?: boolean | string }` *(required: thought, nextThoughtNeeded, thoughtNumber, totalThoughts)*

### 4. `gh_grep`
- Search real-world public GitHub code patterns when concrete usage examples are needed.
- **Exact Schema**:
  - `mcp__gh_grep_searchgithub`: `{ query: string, matchCase?: boolean, matchWholeWords?: boolean, useRegexp?: boolean, repo?: string, path?: string, language?: string[] }` *(required: query — query must be literal code syntax, not natural language questions)*

### 5. `github`
- Use for GitHub platform operations. Creating issues/PRs, commenting, pushing code, or triggering workflows requires explicit user instruction.
- The server exposes 46 tools in total; the common ones are: `create_pull_request`, `create_branch`, `search_code`, `search_commits`, `search_issues`, `search_pull_requests`, `search_repositories`, `create_or_update_file`, `push_files`, `merge_pull_request`, `list_commits`, `get_commit`, `get_file_contents`, `list_branches`, `issue_write`, `pull_request_review_write`, `add_comment_to_pending_review`, `add_issue_comment`, `fork_repository`, `create_repository`, `delete_file`, `list_tags`, `list_releases`, `get_latest_release`, `get_release_by_tag`, `get_team_members`, `get_teams`, `search_users`, `list_repository_collaborators`, `list_issue_types`, `list_issue_fields`, `get_label`, `sub_issue_write`, `update_issue_comment`, `update_pull_request`, `update_pull_request_branch`, `assign_copilot_to_issue`, `request_copilot_review`, `ui_get`, `list_pull_requests`.
- **Exact Schemas**:
  - `mcp__github_get_me`: `{}`
  - `mcp__github_issue_read`: `{ owner: string, repo: string, issue_number: number, method: string, page?: number, perPage?: number }` *(required: owner, repo, issue_number, method)*
  - `mcp__github_pull_request_read`: `{ owner: string, repo: string, pullNumber: number, method: string, page?: number, after?: string }` *(required: owner, repo, pullNumber, method)*
  - `mcp__github_list_issues`: `{ owner: string, repo: string, state?: string, perPage?: number, after?: string, direction?: string, orderBy?: string, fields?: string[], field_filters?: string[], labels?: string[], since?: string }` *(required: owner, repo)*
  - `mcp__github_list_pull_requests`: `{ owner: string, repo: string, state?: string, page?: number, perPage?: number, direction?: string, sort?: string, base?: string, head?: string, fields?: string[] }` *(required: owner, repo)*
---

## Skills

- OMP discovers user skills in `~/.agents/skills` and project-local skill directories.
- When an applicable skill exists, read its content on demand via `read skill://<name>/SKILL.md` and follow referenced instructions.
- Skills define specialized workflows; they are never authorization for destructive actions.
- Do not install, update, or publish skills without explicit user instruction.

---

## Memory and Context

- Use long-term memory to retrieve persistent user preferences and prior architectural decisions; confirm technical decisions in the active repository. Explicit user instructions and current file state always take precedence over recalled memories.
- Never store secrets, tokens, credentials, or personal sensitive data in memory.
- Avoid loading redundant skills or MCP tools. Keep focus strictly on the immediate task.
