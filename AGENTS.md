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
  `private_dot_local/bin/executable_oc-provider` → `~/.local/bin/oc-provider`)
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
chezmoi apply                # render + write to ~ (runs package sync if a manifest changed)
chezmoi execute-template < file.tmpl   # debug a template render in isolation
chezmoi doctor               # catch misconfig (missing git, broken templates, stale cache)
chezmoi --refresh-externals apply      # force-refresh externals (antidote)
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

Package sync scripts and their manifests:

| Script (`.chezmoiscripts/`)        | Manifest        | Target          | Tool                          |
| ---------------------------------- | --------------- | --------------- | ----------------------------- |
| `run_onchange_after_30-brew-bundle`| `dot_Brewfile.tmpl`| `~/.Brewfile` | `brew bundle --global` (macOS)|
| `run_onchange_after_40-pacman`     | `dot_Pacmanfile`| `~/.Pacmanfile` | `yay`/`paru`/`pacman` (Arch)  |
| `run_onchange_after_50-krew`       | `dot_Krewfile`  | `~/.Krewfile`   | `kubectl krew install`        |
| `run_onchange_after_20-mise-install`| `mise/config.toml`| `~/.config/mise`| `mise install`              |
| `run_onchange_after_15-zsh-tokens` | (bin script)    | `~/.config/zsh/tokens.zsh` | Bitwarden `bw`     |

Scripts are platform-gated at the template level (e.g. brew script wraps its
whole body in `{{- if eq .chezmoi.os "darwin" -}}`), and every script no-ops
gracefully (`command -v X || exit 0`) when its tool is absent.

## Template data

Template values come from `.chezmoi.toml.tmpl` (chezmoi's own config, special-cased:
run by `chezmoi init` before any other target so `.email` etc. are available on
the very first apply on a fresh machine) `[data]`: `name`, `email`, `github_user`,
`weather_city`, `machineName` (prompted once via `promptStringOnce`, defaults to
`.chezmoi.hostname`). Reference as `{{ .email }}` etc. `.chezmoidata/opencode_providers.toml`
provides the opencode provider/tier matrix consumed by the opencode template.

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

- **opencode** (`private_dot_config/opencode/`): the `oc-provider` command
  (`~/.local/bin/oc-provider`) switches all opencode agents between configured
  LLM providers by writing
  `~/.config/opencode/.active_provider` then running `chezmoi apply` on the
  `oh-my-openagent.json` template. The tier→model matrix lives in
  `.chezmoidata/opencode_providers.toml`. opencode *skills* are NOT tracked by
  chezmoi (gitignored under `.config/opencode/skills/`; managed by the `skills`
  CLI).
- **nvim** (`private_dot_config/nvim/`): AstroNvim-based, Lua config under
  `lua/plugins/`.
- **externals** (`.chezmoiexternal.toml`): antidote (zsh plugin manager) is
  git-cloned to `~/.antidote`, refreshed at most weekly.

See `README.md` for bootstrap, full system-dependency table, troubleshooting,
and rollback procedures.
