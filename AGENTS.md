# AGENTS.md

Personal dotfiles managed with [chezmoi](https://chezmoi.io), targeting **macOS**
(Homebrew) and **Arch Linux** (pacman/yay). This repo is the chezmoi *source
directory* — files here are templates/source state, not the live config. The
live config is what chezmoi renders into `~`.

## Critical: this is a chezmoi source tree, not a normal dotfiles dir

File and directory names are chezmoi *source-state attributes*, not literal
target names. Editing the right file means understanding the name encoding:

- `dot_X` → target `~/.X` (e.g. `dot_zshrc.tmpl` → `~/.zshrc`)
- `private_` prefix → target gets `0600`/`0700` perms (chezmoi attribute only;
  strip it mentally when mapping to the target path)
- `executable_` prefix → target gets `+x` (e.g.
  `private_dot_local/bin/executable_change-providers` → `~/.local/bin/change-providers`)
- `.tmpl` suffix → Go-template rendered by chezmoi before writing
- `private_dot_config/` → `~/.config/`

So to change `~/.config/git/config` you edit
`private_dot_config/git/config.tmpl`. Never edit the rendered files in `~`
directly — `chezmoi apply` will overwrite them.

## Commands

Always work through chezmoi, not by editing `~` directly:

```sh
chezmoi edit <target>        # edit the source of a target file in $EDITOR (nvim)
chezmoi diff                 # preview pending changes to ~
chezmoi --dry-run apply      # apply without writing anything
chezmoi apply                # render + write to ~ (package sync on manifest changes; Antidote hook every apply)
chezmoi execute-template < file.tmpl   # debug a template render in isolation
chezmoi doctor               # catch misconfig (missing git, broken templates, stale cache)
```

There is **no build/test/lint suite** — this is config, not an application. The
closest thing to a test is `chezmoi --dry-run apply` + `chezmoi diff`.

## How apply works (control flow)

`chezmoi apply` runs scripts in `.chezmoiscripts/` in lexical order around the
file-writing phase:

- `run_before_*` — run before files are written. Used for YubiKey GPG/SSH key
  material (`yubikey.pub`, `allowed_signers`).
- `run_onchange_after_*` — run after, **only when their embedded content hash
  changes**. Each script embeds a hash of the manifest it depends on via
  `{{ include "..." | sha256sum }}` in a comment line; changing that comment is
  what re-triggers the script. If you change a manifest (e.g. `dot_Brewfile.tmpl`)
  the hash changes and the sync re-runs; otherwise it's skipped.
- `run_after_60-antidote-bundles.sh.tmpl` — runs after the package hooks on
  **every apply**. It runs `antidote update --bundles` (updating plugin clones,
  never Antidote itself) and then rebuilds both static bundles. Treatable
  failures are non-fatal, it waits up to five seconds for the common lock,
  preserves all four bundle artifacts, and lets chezmoi continue; the update may
  already have changed some clones before a later failure.

Package sync scripts and the post-apply Antidote hook:

| Script (`.chezmoiscripts/`)        | Manifest        | Target          | Tool                          |
| ---------------------------------- | --------------- | --------------- | ----------------------------- |
| `run_onchange_after_30-brew-bundle`| `dot_Brewfile.tmpl`| `~/.Brewfile` | `brew bundle --global` (macOS; taps + casks only) |
| `run_onchange_after_40-pacman`     | `dot_Pacmanfile`| `~/.Pacmanfile` | `yay`/`paru`/`pacman` (Arch)  |
| `run_onchange_after_50-krew`       | `dot_Krewfile`  | `~/.Krewfile`   | `kubectl krew install`        |
| `run_onchange_after_20-mise-install`| `mise/config.toml`| `~/.config/mise`| `mise install`              |
| `run_onchange_after_15-zsh-tokens` | (bin script)    | `~/.config/zsh/tokens.zsh` | Bitwarden `bw`     |
| `run_onchange_after_52-pi-packages` | `dot_PiPackages` | `~/.pi/agent/settings.json` (packages); `~/.local/share/groovy-lsp/groovy-language-server-all.jar` (server-side LSP build) | `pi install` + `gradle shadowJar` (server-side pin in `# gerenciado:groovy-lsp-pin:...` — upstream has no GH Releases / no aqua entry) |
| `run_onchange_after_53-omp-plugins` | `dot_OmpPlugins` | `~/.omp/plugins/` (npm plugins) | `omp plugin install` |
| `run_after_60-antidote-bundles.sh.tmpl` | (every apply) | `~/.zsh_plugins_pre.zsh`, `~/.zsh_plugins.zsh` | `antidote update --bundles` + bundle rebuild |

Scripts are platform-gated at the template level (e.g. brew script wraps its
whole body in `{{- if eq .chezmoi.os "darwin" -}}`), and every script no-ops
gracefully (`command -v X || exit 0`) when its tool is absent. The Antidote hook
is active on macOS and Arch Linux, runs on every apply, and is a successful
no-op on other systems or when its prerequisites are absent.

## Template data

Template values come from `.chezmoi.toml.tmpl` (chezmoi's own config, special-cased:
run by `chezmoi init` before any other target so `.email` etc. are available on
the very first apply on a fresh machine) `[data]`: `name`, `email`, `github_user`,
`weather_city`, `machineName` (prompted once via `promptStringOnce`, defaults to
`.chezmoi.hostname`). Reference as `{{ .email }}` etc. `.chezmoidata/providers.toml`
is the single provider matrix consumed by both the opencode and omp templates
(`[opencode.*]` and `[omp.*]` sections, plus a shared `[providers.<key>]` registry
holding each provider's native id per binary, `opencode_id`/`omp_id`).

Platform branching uses `.chezmoi.os` (`darwin`/`linux`) and
`.chezmoi.osRelease.id` (`arch`). `.chezmoiignore` is itself a template that
excludes Linux-only configs (xfce4, cortile, autostart, …) on non-Linux and
`.Brewfile` on non-macOS — so a config existing in source doesn't mean it's
applied on the current OS.

Machine branching uses `.machineName` (set in `.chezmoi.toml.tmpl`) against the
`personal_machines` list in `.chezmoidata/machines.toml` (`["iorek", "aesahaettr"]`).
The idiom is **known machines are personal; anything else is a work machine** —
so the work Mac is covered without hardcoding its name. Used by:
`dot_Brewfile.tmpl` (work-only casks: Outlook/Teams/OnlyOffice/Slack/Zoom) and
`private_dot_config/git/config.tmpl` (on a work machine the git `user.email` is
pulled from `WORK_MAIL` env or Bitwarden's `work_mail` field; personal machines
use `.email`, and Bitwarden is never queried on them since the branch is not
evaluated). There is no separate work gitconfig file anymore.

## Secrets

Secrets are **never** stored in this repo. API tokens live in a Bitwarden vault
item named `dotfiles-tokens`, fetched by `~/.local/bin/zsh-tokens-sync` into
`~/.config/zsh/tokens.zsh` (gitignored, sourced by `private_dot_zshenv.tmpl`).
Re-run `zsh-tokens-sync` after rotating a token. Commit signing uses a YubiKey
(GPG → SSH key exported to `~/.ssh/yubikey.pub`); git is configured for SSH
signing with that key.

## Conventions

- Indentation (`.editorconfig`): 2 spaces default; **4 spaces** for shell
  (`*.sh`, `*.bash`, `*.zsh`, `*.sh.tmpl`); tabs for Makefiles. LF, UTF-8,
  trailing whitespace trimmed (except `*.md`).
- Shell scripts: `#!/usr/bin/env bash` + `set -euo pipefail`, and a header
  comment explaining intent. Comments/messages are frequently in Brazilian
  Portuguese (pt-BR); keep that style when editing existing scripts.
- Commit messages: conventional commits (`feat:`, `fix:`, `chore:`, `docs:`).
- zsh startup is heavily performance-tuned (antidote static bundle, cached
  compinit, lazy tool init). Preserve the staged sourcing in `dot_zshrc.tmpl`;
  don't add live plugin resolution or per-shell `bw`/`python` calls.

## Notable subsystems

- **opencode** (`private_dot_config/opencode/`): the `change-providers opencode`
  command (`~/.local/bin/change-providers`) switches all opencode agents between
  configured LLM providers by writing
  `~/.config/opencode/.active_provider` then running `chezmoi apply` on the
  `oh-my-openagent.json` template. The tier→model matrix lives in
  `.chezmoidata/providers.toml` (`[opencode.models]`). opencode *skills* are NOT tracked by
  chezmoi (gitignored under `.config/opencode/skills/`; managed by the `skills`
  CLI).
- **omp** (@oh-my-pi/cli, `private_dot_omp/agent/` + `private_dot_local/bin/`):
  ecossistema paralelo ao opencode, com semântica diferente de pi. omp é
  um fork Rust do pi (16k+ stars, omp.sh) com 40+ providers built-in
  (alibaba-token-plan, xiaomi, opencode, minimax, kimi-code, zai, deepseek,
  etc.). Diferenças-chave do pi:
  - omp usa YAML (`~/.omp/agent/config.yml`), não JSON.
  - `modelRoles` (record de role → "provider/model") controla default/smol/slow/plan.
  - Tiers e Perfis selecionam os MODELOS reais baseados em consumo de tokens / custo
    (orchestrator, implementation, planner, quick, standard, complex, deep).
  - mcp.json fica em arquivo SEPARADO (`~/.omp/agent/mcp.json`) — omp
    rejeita config inteiro se `mcpServers:` aparecer no config.yml. É
    estático (não-template), schema-validado contra o mcp-schema.json do
    omp. Contém só servers sem built-in equivalente: context7, gh_grep
    (http), codebase-memory, kubernetes (--read-only), terraform.
    Removidos por duplicarem built-ins: filesystem (read/write/glob),
    memory (memory tools), playwright (tool `browser`), github (tool
    `github` via `gh`, habilitado com `github.enabled: true`).
  - setupVersion: key VÁLIDA do config.yml (schema `type: number, default: 0`;
    o próprio omp a escreve pós-setup). O gate do setup wizard é
    `setupVersion < CURRENT_SETUP_VERSION` (=1). O template config.yml.tmpl
    DEVE renderizá-la (preserva o valor do target, default 1) — omitir apaga
    o valor a cada apply e o wizard reabre em todo launch. `symbolPreset: nerd`
    também vem do template pelo mesmo motivo.
  - **Path crítico**: omp lê de `~/.omp/agent/` (não `Library/Application Support/omp/`).
  - **Env vars**: omp usa `ALIBABA_TOKEN_PLAN_API_KEY`, `XIAOMI_TOKEN_PLAN_SGP_API_KEY`
    (diferentes do opencode/pi). Aliases via `private_dot_zshenv.tmpl` derivam
    das chaves Bitwarden (`QWENCLOUD_API_TOKEN` → `ALIBABA_TOKEN_PLAN_API_KEY`,
    `MIMO_API_KEY` → `XIAOMI_TOKEN_PLAN_SGP_API_KEY`).
  - **Tema**: Tokyo Night vem embutido no binário (`dark-tokyo-night`,
    `light-tokyo-night`). Setado via `theme.dark` / `theme.light`.
  - **URL alibaba**: omp já tem `https://token-plan.ap-southeast-1.maas.aliyuncs.com/compatible-mode/v1`
    correto embutido (não precisou override).

  O `change-providers omp` subcomando (`~/.local/bin/change-providers`) escreve
  `~/.config/omp/.active_provider` (`provider:foo\nprofile:bar`) e
  rerenderiza `~/.omp/agent/config.yml`. Matriz em
  `.chezmoidata/providers.toml` (`[omp.providers]`; id nativo resolvido via
  registry `[providers.<key>].omp_id`); parser em `.chezmoitemplates/omp-state.tmpl`
  (emite também `fallbackChains`: chains `default`/`smol` com o deep/quick
  de todos os providers, ativo primeiro, demais em ordem sortAlpha —
  `keys` sozinho retorna em ordem aleatória).
  Tiers baseados em custo de tokens: expensive / recommended (flagship / alto consumo),
  balanced / optimized (balanceado), cheap / super (econômico), free / ultra (custo mínimo).
- **nvim** (`private_dot_config/nvim/`): AstroNvim-based, Lua config under
  `lua/plugins/`.
- **antidote**: zsh plugin manager installed via Homebrew/pacman. The static
  bundle is rebuilt by `run_after_60-antidote-bundles.sh.tmpl` on every apply.
  The normal zsh startup path loads static bundles; its conditional fallback
  may call `antidote bundle` when a manifest is newer or the Antidote cache is
  missing. It takes a zero-wait common lock first; if the lock is occupied, it
  does not wait or regenerate and loads the current bundle instead.

See `README.md` for bootstrap, full system-dependency table, troubleshooting,
and rollback procedures.
