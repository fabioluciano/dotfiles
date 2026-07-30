# Global Rules

## Question Tool (MANDATORY)

Use `question` when facing a user decision: trade-offs, approach choices, conflicting options, or irreversible actions. Don't use it for trivial decisions. Include a clear question and concrete options for the user.

## Tasks (MANDATORY)

- Resolve the canonical root with `git rev-parse --show-toplevel`; operate only against that explicit root. If it is not a Git worktree, is `/` or exactly `$HOME`, or is ambiguous/unsafe, stop and ask—never initialize it.
- Confirm `bd` is available; otherwise stop and report it, with no backlog fallback. If `<root>/.beads/` is absent, run `(cd "$root" && bd init --stealth --skip-agents --skip-hooks --non-interactive --init-if-missing)`. Never run `bd setup` or allow automatic AGENTS/hooks changes.
- Run `bd -C "$root" prime` once per project used in a session; never repeat after compaction. Use `bd -C "$root" ready --json` thereafter. Beads is the sole persistent backlog: no `task_create`, `task_update`, `todowrite`, TODO/plan files, or parallel backlogs.
- Use `--json` for programmatic Beads commands. Create discovered work with `--deps discovered-from:<parent-id>`; for substantial issues, include `--acceptance`/`--design` and run `--validate`.
- Claims, updates, and closes require an explicit ID: `bd -C "$root" update <id> --claim --json`, `bd -C "$root" update <id> --status <status> --json`, `bd -C "$root" close <id> --reason "Done" --json`. The `task` subagent tool is only for ephemeral execution and must not duplicate backlog state.
- Before handoff, create linked issues for remaining work, close completed issues, and report status. Never commit, push, or sync Git/Dolt state unless explicitly requested; `.beads/issues.jsonl` is an export, not the sync protocol.

## Built-in Tools (MANDATORY)

- **Skills:** load with `skill` before specialized work. Not optional when a skill matches the task domain.
- **webfetch/websearch:** fallback only — prefer `context7` for library docs, `ctx_fetch_and_index` for large pages.

## Do not hallucinate!

**Do not hallucinate!** Never invent APIs, functions, file paths, or commands without verification. Look up via MCP tools (`codebase-memory`, `context7`) or say "I don't know." Ground every claim in evidence — agents that hallucinate waste time and erode trust.

## MCP-FIRST (mandatory, no exceptions for delegated work)

Use the specialized MCP **before** generic tools (`rg`, grep, `Read`, shell, curl). Applies universally — every agent, subagent, and delegated child. Delegation is not an escape hatch: delegated prompts must explicitly restate this policy.

`Read`/grep/shell findings without a corresponding MCP call = auxiliary evidence only, not authoritative.

| Domain | Required MCP |
|--------|-------------|
| Code / symbols / impact analysis | `codebase-memory` — index first if missing |
| External docs / libraries | `context7` (`resolve-library-id` → `query-docs`) |
| GitHub / public code examples | `github` (ops) / `gh_grep` (public examples) |
| Browser / UI / E2E / screenshots | `playwright` — never replace with curl |
| Large output / logs / reusable docs | `context-mode` (`ctx_batch_execute`, `ctx_execute`, `ctx_search`) |
| LSP / diagnostics / rename symbols | `lsp` — run `lsp_diagnostics` after editing |
| Prior sessions / recall | `session` |
| Media / PDFs / diagrams | `look_at` |
| Orchestration / delegation / tasks | `skill`, `task_*`, `team_*` |
| Generic web (last resort) | `webfetch` / `websearch` |

**Examples:**
- "What breaks if I change X?" → `codebase-memory_trace_path` (inbound)
- "How does Zod v4 define transforms?" → `context7_resolve-library-id` → `context7_query-docs`
- "Summarize 10k-line log" → `ctx_execute_file`
- "Verify page visually" → `playwright_browser_navigate` → `playwright_browser_snapshot`

## Language
- Always respond in Brazilian Portuguese (pt-BR)
- Code comments in English, explanations in Portuguese

## Code Style
- Prefer functional patterns over imperative
- Use TypeScript strict mode when applicable
- Follow existing project conventions over personal preferences

## Workflow
- Always run linter/typecheck after making changes
- Never commit unless explicitly asked
- Prefer editing existing files over creating new ones

## Security
- Never expose secrets, tokens, or API keys in code
- Never commit .env files or credentials
- Use environment variables for sensitive config

## Git
- Never use --force or --hard reset without explicit confirmation
- Prefer squash merges
- Use conventional commit messages (feat:, fix:, chore:, etc.)
