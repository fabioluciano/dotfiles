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
  `private_dot_local/bin/executable_zsh-tokens-sync` → `~/.local/bin/zsh-tokens-sync`)
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

There is no compiled test or build suite — this is config, not an
application. The closest thing to a test is `chezmoi --dry-run apply` +
`chezmoi diff`. A non-mutating static check is available via
`mise run lint-report` (accepts syntax, style and template rendering without
changing state) and the stricter `mise run lint` (exits non-zero on any
failure). See the `## Validation and health checks` section below.

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
never Antidote itself) and then rebuilds both static bundles. It shares the
canonical lock `${ZSH_CACHE_DIR}/.zsh_plugins.lock` with the Zsh startup so the
two cannot regenerate bundles simultaneously. Treatable contention (lock held)
is non-fatal and keeps the current artifacts; genuine update/render/signpost
failure propagates a non-zero status instead of masking the error. The update
may already have changed some clones before a later failure.

Package sync scripts and the post-apply Antidote hook:

| Script (`.chezmoiscripts/`)        | Manifest        | Target          | Tool                          |
| `run_onchange_after_30-brew-bundle`        | `dot_Brewfile.tmpl`| `~/.Brewfile` | `brew bundle --global` (macOS; taps + casks only) |
| `run_after_35-zsh-completion-audit-brew.sh.tmpl` | (bin script)    | `~/.cache/zsh/completion-system` | `zsh-completion-audit` (brew metadata) |
| `run_onchange_after_40-pacman`             | `dot_Pacmanfile`| `~/.Pacmanfile` | `yay`/`paru`/`pacman` (Arch)  |
| `run_after_45-zsh-completion-audit-pacman.sh.tmpl` | (bin script)    | `~/.cache/zsh/completion-system` | `zsh-completion-audit` (pacman database) |
| `run_onchange_after_45-dock.sh.tmpl`       | (none)        | Dock            | dock layout reset            |
| `run_onchange_after_46-zsh-tokens`         | (bin script)    | `~/.config/zsh/tokens.zsh` | Bitwarden `bw`     |
| `run_onchange_after_47-mise-install`       | `mise/config.toml`| `~/.config/mise`| `mise install`              |
| `run_onchange_after_50-krew`               | `dot_Krewfile`  | `~/.Krewfile`   | `kubectl krew install`        |
| `run_onchange_after_53-omp-plugins`        | `dot_OmpPlugins` | `~/.omp/plugins/` (npm plugins) | `omp plugin install` |
| `run_after_60-antidote-bundles.sh.tmpl`    | (every apply) | `~/.zsh_plugins_pre.zsh`, `~/.zsh_plugins.zsh` | `antidote update --bundles` + bundle rebuild |

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
`.chezmoi.hostname`). Reference as `{{ .email }}` etc. OMP models are
configured directly in `private_dot_omp/agent/config.yml.tmpl`.

Platform branching uses `.chezmoi.os` (`darwin`/`linux`) and
`.chezmoi.osRelease.id` (`arch`). `.chezmoiignore` is itself a template that
excludes Linux-only configs (xfce4, cortile, autostart, …) on non-Linux and
`.Brewfile` on non-macOS — so a config existing in source doesn't mean it's
applied on the current OS.

Machine branching uses `.machineName` (set in `.chezmoi.toml.tmpl`) against the
`personal_machines` list in `.chezmoidata/machines.toml` (`["iorek", "aesahaettr"]`).
The idiom is **known machines are personal; anything else is a work machine** —
so the work Mac is covered without hardcoding its name. Used by:
`dot_Brewfile.tmpl` (work-only casks: Microsoft Office, Teams, OnlyOffice, and
Slack/Zoom on work machines) and
`private_dot_config/git/config.tmpl` (on a work machine the git `user.email` is
pulled from `WORK_MAIL` env or Bitwarden's `work_mail` field; personal machines
use `.email`, and Bitwarden is never queried on them since the branch is not
evaluated). There is no separate work gitconfig file anymore.

## Secrets

Secrets are **never** stored in this repo. API tokens live in a Bitwarden vault
item named `dotfiles-tokens`, fetched by `~/.local/bin/zsh-tokens-sync` into
`~/.config/zsh/tokens.zsh` (gitignored, mode 600). That file is generated as
shell `export` lines and is the only secret loaded at shell startup; loading
suspends `xtrace`/`verbose` and validates the file is regular, non-symlink,
owned by the current user, and has no group/other access before sourcing.
Re-run `zsh-tokens-sync` after rotating a token. Commit signing uses a YubiKey
(GPG → SSH key exported to `~/.ssh/yubikey.pub`); git is configured for SSH
signing with that key.

## Validation and health checks

This is configuration, not an application, so there is no build or unit-test
suite. Validation is static and non-mutating, split into a strict gate and a
non-blocking report:

- `mise run lint` — exits non-zero on any failure; use in CI/pre-apply gates.
- `mise run lint-report` — same checks, always returns zero so it can be noisy/optional.
- `mise run doctor-chezmoi` — `chezmoi doctor && chezmoi --dry-run apply`.
- `mise run doctor-omp` — verifies OMP and its model catalog.
- `mise run doctor-nvim` — verifies the Neovim binary headless without plugin bootstrap (`nvim --headless -u NONE`).
- `mise run benchmark-nvim` / `mise run benchmark-zsh` — measure isolated cold/warm startup with median, p95 and (for Zsh) `zprof`; use temporary XDG/cache directories and never touch plugin state.

The runner `private_dot_local/bin/executable_dotfiles-lint` performs shell,
TOML, YAML, Lua syntax/style checks and renders selected chezmoi templates
into a scratch directory. It deliberately skips templates that consult live
secrets, the Bitwarden item, or runtime state.

## Serena indexing

- OMP's `mcp.json` configures the Serena server launch; it does not select the
  languages indexed for this repository. Serena global defaults live in
  `~/.serena/serena_config.yml`; per-repository language servers and workspace
  folders belong in `.serena/project.yml`.
- Before `serena project index`, verify `.serena/project.yml` has a non-empty,
  suitable `language_servers` list. Auto-detection can create an empty list and
  still report success; confirm per-language counts after indexing.
- This repository currently indexes `bash`, `lua`, `json`, `toml`, `yaml`, and
  `markdown`. Serena has no built-in Zsh or template LSP; don't claim `.zsh`,
  `.tmpl`, or unsupported config formats are covered. Report the coverage gaps.


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

- **omp** (`private_dot_omp/agent/`): the only managed AI agent.
  - Installed with Homebrew on macOS and mise on Linux.
  - `config.yml.tmpl` defines `modelRoles` directly (default/smol/slow/plan),
    theme and LSP settings; it preserves the live `setupVersion`.
  - Models and endpoints come from the native OMP catalog; no custom model matrix.
  - `mcp.json` is separate from the main configuration.
  - `omp --model provider/model` selects a model for one launch. Change the
    source `modelRoles` and apply that target for persistent defaults.
  - The Zsh wrapper loads vault-backed tokens via `zsh-load-tokens` on demand.
  - `dot_OmpPlugins` and its hook manage OMP extensions.
  - Retired configuration paths are listed in `.chezmoiremove`; keep sessions
    and credentials out of recursive removals.
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
