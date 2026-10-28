# Plugin workflow integration

- Follow the user's AGENTS.md rules when applying Superpowers or Slim skills.
- Beads is the only persistent task backlog. Use explicit issue IDs for claims,
  updates and closes. Do not create TODO files, plan files or parallel backlogs
  when a skill suggests another task tracker.
- Treat Slim background jobs as ephemeral execution, linked to the owning Beads
  issue, not as a second persistent backlog.
- Run bd prime only once per canonical project root in a session. If the Beads
  plugin already injected its output, do not run it again after compaction.
- Context7 uses one explicitly configured server named context7, shared by its
  dedicated plugin and Slim. Do not register additional aliases for it.
- Do not commit, push, sync Git/Dolt state or delete worktrees without explicit
  user authorization, even when a bundled skill recommends it.
- Every delegated child must follow the same MCP-first and safety rules as its
  parent. Use specialized MCP tools first when available; disclose unavailable
  integrations instead of claiming they were used.
