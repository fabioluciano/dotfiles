# Global OMP Agent Instructions

## Mandatory Session Startup & Project Lifecycle

Whenever starting work in a session or addressing a repository-related task, EVERY agent MUST execute the following sequence before exploring files or writing code:

1. **Call Serena Initial Instructions**:
   - Immediately call `mcp__serena_initial_instructions` (`{}`) to read the Serena manual and active project session context.
2. **Confirm Project Activation & Onboarding**:
   - Serena auto-activates the project from the working directory at MCP startup (`--project-from-cwd` resolves the nearest ancestor containing `.serena/project.yml` or `.git`).
   - If onboarding has not been performed, call `mcp__serena_onboarding` (`{}`).
   - If Serena finds no symbols in a directory, initialize/warm the project cache with `serena project create` / `serena project index` via bash.
3. **Query Project Memories**:
   - Call `mcp__serena_list_memories` (`{}`) to discover project conventions, architectural decisions, and known gotchas before proposing solutions.

---

## Tool Selection Principles — Serena Primacy Rule

**CRITICAL DIRECTIVE**: If a task can be achieved using Serena's tools, **EVERY AGENT MUST OBLIGATORILY USE SERENA TOOLS**. Do NOT bypass Serena for native file operations or raw shell scripts when a Serena tool exists for that function.

1. **Code Reading & Exploration (Serena Mandatory)**:
   - **PROHIBITED**: Do NOT read entire source code files using native `read` or run heavy exploratory traversals (`grep -r`, `find`, `cat` loops).
   - **File Overview**: Call `mcp__serena_get_symbols_overview` first to inspect the symbol structure of any file.
   - **Symbol Lookup**: Use `mcp__serena_find_symbol` to locate classes, functions, methods (set `include_body: true` ONLY when the implementation body is needed).
   - **Declarations & Implementations**: Use `mcp__serena_find_declaration` and `mcp__serena_find_implementations`.
   - **Callers & Usages**: Use `mcp__serena_find_referencing_symbols` to map references before changing symbols.
   - **Pattern Search**: Use `mcp__serena_search_for_pattern` when the exact symbol name path is unknown.
   - **Code Diagnostics**: Call `mcp__serena_get_diagnostics_for_file` to inspect LSP compiler and linter diagnostics.

2. **Code Editing & Refactoring (Serena Mandatory)**:
   - **Symbol Renames**: MUST use `mcp__serena_rename_symbol` for reference-aware cross-codebase renaming.
   - **Replacing Symbol Bodies**: MUST use `mcp__serena_replace_symbol_body` to update a function, method, or class definition.
   - **Inserting Code**: MUST use `mcp__serena_insert_before_symbol` (e.g. for imports or new top-level symbols) and `mcp__serena_insert_after_symbol` (after a class/function).
   - **Deleting Symbols**: MUST use `mcp__serena_safe_delete_symbol` to verify zero references before removal.
   - **Surgical Text/Regex Replacements**: MUST use `mcp__serena_replace_content` within a file (prefer `mode: "regex"` with wildcards `beginning.*?end` to avoid quoting large blocks).
   - **Multi-File Batch Edits**: MUST use `mcp__serena_replace_in_files` (always run `dry_run: true` first to inspect diffs, then apply with occurrence IDs or `dry_run: false`).

3. **Scope for Native OMP Tools**:
   - Native `read`/`edit`/`write` are reserved ONLY for non-code files (Markdown documents, JSON/YAML configuration files, templates) or files outside the Serena project scope.
   - Native `write` is used when generating brand new files that do not yet exist.
   - Native `bash` is reserved for build execution, test suites, linters, package managers, and git commands.

4. **Project Memory Persistence**:
   - Record architectural patterns, conventions, and reusable project knowledge using `mcp__serena_write_memory`.
   - Read and manage memories using `mcp__serena_read_memory`, `mcp__serena_list_memories`, `mcp__serena_edit_memory`, `mcp__serena_rename_memory`, and `mcp__serena_delete_memory`.

5. **Strict Schema Adherence (Zero Parameter Hallucination)**:
   - NEVER invoke MCP tools with guessed, hallucinated, or unverified parameter names. Always inspect the exact tool schema before invocation (`read xd://mcp__<server>_<tool>`).
   - MCP tools strictly follow the prefixed routing pattern `mcp__<server>_<tool>` (e.g., `mcp__serena_find_symbol`).
---


## Configured MCP Servers & Exact Schemas

### 1. `serena` (MANDATORY for all Code Reading, Navigation, Editing, Refactoring, and Memory)
- **Primary Architecture**: Serena is the mandatory semantic backend wired directly into language servers (LSP) for precision code intelligence.
- **Project Activation**: Auto-activates from the nearest `.serena/project.yml` or `.git`. If not configured, run `serena project create` then `serena project index` via bash.
- **Complete 23 Tools Reference & Exact Schemas**:
  - **Lifecycle & Setup**:
    - `mcp__serena_initial_instructions`: `{}` — **MUST** be called at session start to load Serena instructions and active session ID.
    - `mcp__serena_onboarding`: `{}` — Call if onboarding has not been performed for the active project.
    - `mcp__serena_open_dashboard`: `{}` — Opens the Serena web dashboard.
  - **Code Exploration & Retrieval**:
    - `mcp__serena_get_symbols_overview`: `{ relative_path: string, depth?: number, max_answer_chars?: number }` — High-level symbol tree of a file. Use first before reading code.
    - `mcp__serena_find_symbol`: `{ name_path_pattern: string, depth?: number, relative_path?: string, include_body?: boolean, include_info?: boolean, include_kinds?: number[], exclude_kinds?: number[], substring_matching?: boolean, max_matches?: number, max_answer_chars?: number }` — Find functions, classes, methods. Set `include_body: true` ONLY when reading code.
    - `mcp__serena_find_declaration`: `{ relative_path: string, regex: string, containing_symbol_name_path?: string | null, include_body?: boolean, include_info?: boolean }` — Find symbol declaration via regex matching group.
    - `mcp__serena_find_implementations`: `{ name_path: string, relative_path: string, include_info?: boolean, include_kinds?: number[], exclude_kinds?: number[], max_answer_chars?: number }` — Find interface/abstract implementations.
    - `mcp__serena_find_referencing_symbols`: `{ name_path: string, relative_path: string, include_kinds?: number[], exclude_kinds?: number[], max_answer_chars?: number }` — Find all usages, callers, and references across project.
    - `mcp__serena_get_diagnostics_for_file`: `{ relative_path: string, start_line?: number, end_line?: number, min_severity?: number, max_answer_chars?: number }` — LSP compiler/linter diagnostics (1=Error, 2=Warning, 3=Info, 4=Hint).
    - `mcp__serena_search_for_pattern`: `{ substring_pattern: string, context_lines_before?: number, context_lines_after?: number, paths_include_glob?: string, paths_exclude_glob?: string, relative_path?: string, restrict_search_to_code_files?: boolean, skip_ignored_files?: boolean, multiline?: boolean, max_answer_chars?: number }` — Regex search across files when symbol name path is unknown.
  - **Symbolic & Structure-Aware Code Editing**:
    - `mcp__serena_rename_symbol`: `{ name_path: string, relative_path: string, new_name: string }` — Reference-aware rename across entire codebase.
    - `mcp__serena_replace_symbol_body`: `{ name_path: string, relative_path: string, body: string }` — Replace definition of a function, method, or class. (Inspect body with `include_body: true` first).
    - `mcp__serena_insert_before_symbol`: `{ name_path: string, relative_path: string, body: string }` — Insert imports or new definitions before the target symbol.
    - `mcp__serena_insert_after_symbol`: `{ name_path: string, relative_path: string, body: string }` — Insert new methods, functions, or classes after the target symbol.
    - `mcp__serena_safe_delete_symbol`: `{ name_path_pattern: string, relative_path: string }` — Safe deletion verifying no references exist.
    - `mcp__serena_replace_content`: `{ relative_path: string, needle: string, repl: string, mode: "literal" | "regex", allow_multiple_occurrences?: boolean }` — Targeted in-file edit. Prefer `mode: "regex"` with `beginning.*?end` wildcards to minimize token overhead.
    - `mcp__serena_replace_in_files`: `{ needle: string, repl: string, mode: "literal" | "regex", relative_path?: string, paths_include_glob?: string, paths_exclude_glob?: string, dry_run?: boolean, occurrence_ids?: string[] | null, expected_count?: number, max_answer_chars?: number }` — Multi-file batch edits. Always run with `dry_run: true` first.
  - **Project Memory Management**:
    - `mcp__serena_write_memory`: `{ memory_name: string, content: string, max_chars?: number }` — Store architectural decisions, conventions, patterns (supports topics like `topic/name` or `global/name`).
    - `mcp__serena_read_memory`: `{ memory_name: string }` — Read a stored project memory.
    - `mcp__serena_list_memories`: `{ topic?: string }` — List available project memories.
    - `mcp__serena_edit_memory`: `{ memory_name: string, needle: string, repl: string, mode: "literal" | "regex", allow_multiple_occurrences?: boolean }` — Edit memory content.
    - `mcp__serena_rename_memory`: `{ old_name: string, new_name: string }` — Rename or move memory topic.
    - `mcp__serena_delete_memory`: `{ memory_name: string }` — Delete a stored memory.

### 2. `git`
- Use only when MCP graph or structured output provides clear value over local terminal git. For ordinary status, diff, log, and local changes, prefer native `git` via `bash`.
- **Exact Schemas**:
  - `mcp__git_status`: `{ repo_path: string }`
  - `mcp__git_diff_unstaged`: `{ repo_path: string }`
  - `mcp__git_diff_staged`: `{ repo_path: string }`
  - `mcp__git_log`: `{ repo_path: string, max_count?: number }`

### 3. `context7`
- Use for retrieving current library and framework documentation when version details or API semantics matter. Prefer official upstream documentation.
- **Exact Schemas**:
  - `mcp__context7_resolve_library_id`: `{ libraryName: string, query: string }` *(Must be called first unless exact `/org/project` ID is already known)*
  - `mcp__context7_query_docs`: `{ libraryId: string, query: string }`

### 4. `gh_grep`
- Search real-world public GitHub code patterns when concrete usage examples are needed.
- **Exact Schema**:
  - `mcp__gh_grep_searchgithub`: `{ query: string, matchCase?: boolean, matchWholeWords?: boolean, useRegexp?: boolean, repo?: string, path?: string, language?: string[] }` *(Query must be literal code syntax, not natural language questions)*

### 5. `kubernetes`
- Use strictly for cluster and resource inspection. The server is configured in **read-only** mode. Do not attempt or promise mutating operations.
- **Exact Schemas**:
  - `mcp__kubernetes_resources_list`: `{ apiVersion: string, kind: string, namespace?: string, labelSelector?: string, fieldSelector?: string, context?: string }`
  - `mcp__kubernetes_resources_get`: `{ apiVersion: string, kind: string, name: string, namespace?: string, context?: string }`
  - `mcp__kubernetes_pods_list`: `{ context?: string }`
  - `mcp__kubernetes_pods_log`: `{ name: string, namespace?: string, container?: string, context?: string }`

### 6. `terraform`
- Use for inspecting Terraform registry providers, modules, and policies. Never execute apply or destroy without explicit user instruction.
- **Exact Schemas**:
  - `mcp__terraform_search_providers`: `{ query?: string, service_slug?: string, provider_document_type?: string }`
  - `mcp__terraform_get_provider_details`: `{ provider_doc_id: string }`
  - `mcp__terraform_search_modules`: `{ query: string, provider?: string }`
  - `mcp__terraform_get_module_details`: `{ module_id: string }`

### 7. `github`
- Use for GitHub platform operations. Creating issues/PRs, commenting, pushing code, or triggering workflows requires explicit user instruction.
- **Exact Schemas**:
  - `mcp__github_get_me`: `{}`
  - `mcp__github_issue_read`: `{ owner: string, repo: string, issue_number: number }`
  - `mcp__github_pull_request_read`: `{ owner: string, repo: string, pull_number: number }`
  - `mcp__github_list_issues`: `{ owner: string, repo: string, state?: "OPEN" | "CLOSED", limit?: number }`
  - `mcp__github_list_pull_requests`: `{ owner: string, repo: string, state?: "OPEN" | "CLOSED" | "MERGED", limit?: number }`

### 8. `sequential-thinking`
- Use to decompose ambiguous multi-step reasoning problems or strategic architecture trade-offs.
- **Exact Schema**:
  - `mcp__sequential_thinking_sequentialthinking`: `{ thought: string, nextThoughtNeeded: boolean | string, thoughtNumber: number, totalThoughts: number, isRevision?: boolean | string, revisesThought?: number, branchFromThought?: number, branchId?: string, needsMoreThoughts?: boolean | string }`

### 9. `playwright`
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
