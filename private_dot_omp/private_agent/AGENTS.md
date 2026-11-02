# Global OMP Agent Instructions

## Session Startup & Project Lifecycle

Whenever starting work in a session or addressing a repository-related task:

1. **Read the repository conventions first** — the project's own `AGENTS.md`, docs and build files, before exploring or changing code.
2. **Search before opening** — locate the relevant files with `grep`/`glob` (or `xd://ast_grep` for structure); never open guessed paths.
3. **Call only tools that exist in this session** — MCP tools are invoked by their full name (`mcp__<server>_<tool>`). Only the servers mounted in the current session are available; a tool that is not listed does not exist. Never retry a missing tool with another spelling.

---

## Tool Selection Principles

- **Code search**: `grep` (regex over files), `glob` (names/structure), `xd://ast_grep` (AST patterns), `xd://lsp` (definitions, references, diagnostics, hover).
- **Files**: `read` with a line-range selector for inspection, `edit` for surgical changes, `write` only for new files or full rewrites.
- **Shell**: `bash` only for build, tests, linters, package managers and git.
- **MCP servers**: use one only when the task needs it *and* it is mounted in the session; call its tools by name with the exact schemas listed below.
- **Strict Schema Adherence (Zero Parameter Hallucination)**: never invoke an MCP tool with guessed names or parameters. Inspect the schema of a mounted tool with `read xd://<tool>` **before** the first call, and skip the tool entirely when it is not mounted.
---


## Configured MCP Servers & Exact Schemas

### 1. `git`
- Use only when MCP graph or structured output provides clear value over local terminal git. For ordinary status, diff, log, and local changes, prefer native `git` via `bash`.
- **Exact Schemas**:
  - `mcp__git_status`: `{ repo_path: string }`
  - `mcp__git_diff_unstaged`: `{ repo_path: string }`
  - `mcp__git_diff_staged`: `{ repo_path: string }`
  - `mcp__git_log`: `{ repo_path: string, max_count?: number }`

### 2. `context7`
- Use for retrieving current library and framework documentation when version details or API semantics matter. Prefer official upstream documentation.
- **Exact Schemas**:
  - `mcp__context7_resolve_library_id`: `{ libraryName: string, query: string }` *(Must be called first unless exact `/org/project` ID is already known)*
  - `mcp__context7_query_docs`: `{ libraryId: string, query: string }`

### 3. `gh_grep`
- Search real-world public GitHub code patterns when concrete usage examples are needed.
- **Exact Schema**:
  - `mcp__gh_grep_searchgithub`: `{ query: string, matchCase?: boolean, matchWholeWords?: boolean, useRegexp?: boolean, repo?: string, path?: string, language?: string[] }` *(Query must be literal code syntax, not natural language questions)*

### 4. `terraform`
- Use for inspecting Terraform registry providers, modules, and policies. Never execute apply or destroy without explicit user instruction.
- **Exact Schemas**:
  - `mcp__terraform_search_providers`: `{ query?: string, service_slug?: string, provider_document_type?: string }`
  - `mcp__terraform_get_provider_details`: `{ provider_doc_id: string }`
  - `mcp__terraform_search_modules`: `{ query: string, provider?: string }`
  - `mcp__terraform_get_module_details`: `{ module_id: string }`

### 5. `github`
- Use for GitHub platform operations. Creating issues/PRs, commenting, pushing code, or triggering workflows requires explicit user instruction.
- **Exact Schemas**:
  - `mcp__github_get_me`: `{}`
  - `mcp__github_issue_read`: `{ owner: string, repo: string, issue_number: number }`
  - `mcp__github_pull_request_read`: `{ owner: string, repo: string, pull_number: number }`
  - `mcp__github_list_issues`: `{ owner: string, repo: string, state?: "OPEN" | "CLOSED", limit?: number }`
  - `mcp__github_list_pull_requests`: `{ owner: string, repo: string, state?: "OPEN" | "CLOSED" | "MERGED", limit?: number }`

### 6. `sequential-thinking`
- Use to decompose ambiguous multi-step reasoning problems or strategic architecture trade-offs.
- **Exact Schema**:
  - `mcp__sequential_thinking_sequentialthinking`: `{ thought: string, nextThoughtNeeded: boolean | string, thoughtNumber: number, totalThoughts: number, isRevision?: boolean | string, revisesThought?: number, branchFromThought?: number, branchId?: string, needsMoreThoughts?: boolean | string }`

### 7. `playwright`
- Use strictly for real browser rendering, UI interactions, snapshots, and E2E verification. Do not invent tools or capabilities based merely on a server name.
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
