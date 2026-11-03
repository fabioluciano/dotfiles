# OMP context & compaction — design

**Date:** 2026-11-03
**Status:** Approved in conversation.
**Scope:** chezmoi source tree `/home/fabioluciano/.local/share/chezmoi` + one runtime command.

## Intent and why

The billion-context extension is a second compressor over the same traffic omp
already manages, and it was the reason `providers.cacheWarming` sat at `off`
(its comment said so). Removing it leaves a cache-warming gap that omp's own
`cacheWarming` must fill.

Separately, four of the five configured model roles have a 1M-token context
window. omp's default reserve policy compacts at roughly 85% of the window, so
`anthropic/claude-opus-5-5` would only compact near 850k tokens — about US$ 3.40
of input per turn. The schema already offers the right lever:
`compaction.modelThresholds` accepts an exact fixed trigger (`"f<tokens>"`) per
model, which is not rescaled by the 85% policy.

## Goals

- Zero billion-context references in managed config.
- Per-model compaction ceilings proportional to input cost.
- Native cache warming replaces the removed plugin's role.

## Non-goals

- `extendedContext` stays `false` (larger windows are premium-priced and
  contradict the working ceiling).
- `contextPromotionTarget` is not configured (moot under a fixed ceiling).
- No other agent (opencode, codex) gets compaction tuning beyond the plugin
  entry that must be removed.

## Anti-goals

- Do not `mise uninstall` anything without explicit approval — it is outside
  chezmoi and destructive.
- Do not touch `compaction.methodOrder`, `snapcompact.*`, or
  `compaction.experimentalContextManagement`; they are already correct.

## Constraints

- chezmoi source tree: edit sources, never the rendered `~` targets.
- Shell files indent with 4 spaces; comments in pt-BR, matching repo style.
- Conventional commits.
- No test suite: verification is `chezmoi diff`, `chezmoi --dry-run apply`,
  `mise run lint-report`.
- `compaction.modelThresholds` keys are bare selectors
  (`anthropic/claude-sonnet-5-5`), never the role's thinking-level suffix
  (`anthropic/claude-sonnet-5-5:auto`).

## Approaches considered

**Threshold strategy.**
1. *Percentage per model* (`"85%"`) — scales with the window, but 85% of 1M is
   still 850k and still expensive. Rejected.
2. *Uniform fixed ceiling (350k)* — simple and predictable, but wastes the
   cheap models' wide windows and is still costly on Opus. Rejected.
3. *Cost-aware fixed triggers (chosen)* — Opus 250k / Sonnet 300k /
   Gemini-Flash 400k / MiMo 400k, Luna left on the default policy. Holds the
   expensive models down and lets the cheap ones run wide.

**Cache warming.**
1. *`auto` (chosen)* — omp decides per provider and cache TTL; direct
   replacement for what billion-context did.
2. *`on`* — always warm, extra request cost. Rejected.
3. *`off`* — leaves the gap. Rejected.

**Removal scope.** Remove from every managed surface (omp config, mise,
opencode, zsh wrapper, plugin hook) rather than only the omp `extensions:`
entry, so no stale path or launcher survives an apply.

## Decided details

| Item | Value |
| --- | --- |
| `compaction.modelThresholds` | `anthropic/claude-opus-5-5: "f250000"`, `anthropic/claude-sonnet-5-5: "f300000"`, `google-antigravity/gemini-3.8-flash: "f400000"`, `xiaomi-token-plan-sgp/mimo-v2.6-pro: "f400000"` |
| `openai-codex/gpt-6-luna` | absent from the map — 272k window, default policy compacts near 231k |
| `providers.cacheWarming` | `off` → `auto` |
| `compaction.idleThresholdTokens` | `200000` → `400000` (builder's call: idle compaction at 200k would discard context the per-model ceiling still allows; at 400k it is only a safety net at the top of the working band, and the cache-aware timing still applies) |
| `disabledProviders` | drop `opencode-go`, `opencode-zen`; keep `commandcode`, `alibaba-token-plan`, `gitlab-duo`, `gitlab-duo-agent`, `llama.cpp`, `minimax`, `opencode`, `zai` |
| Untouched | `experimentalContextManagement`, `methodOrder`, `asyncEnabled`, `midTurnEnabled`, `snapcompact.*`, `cacheRetention`, `appendOnlyContext`, `extendedContext` |

## Removal surface

| File | Change |
| --- | --- |
| `private_dot_omp/private_agent/private_config.yml.tmpl` | drop `extensions:` block + comment; `cacheWarming` comment/value |
| `private_dot_config/mise/config.toml.tmpl` | drop `npm:billion-context` + comment |
| `.chezmoiscripts/run_onchange_after_53-omp-plugins.sh.tmpl` | drop `bili plugin install omp` block |
| `private_dot_config/opencode/opencode.jsonc` | drop `"billion-context"` from `plugins` |
| `private_dot_config/zsh/aiagents.zsh.tmpl` | `omp()` calls `omp` directly |
| runtime | `mise uninstall npm:billion-context` (separate, approved step) |

`~/.omp/plugins/` holds no billion-context registration (only `ponytail` and
`superpowers`), so no `omp plugin uninstall` is needed.

## Left to the builder

YAML/JSONC formatting and comment wording (pt-BR). Exact validation commands
are pinned in the implementation plan.
