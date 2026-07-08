# dotfiles

Personal dotfiles managed with [chezmoi](https://chezmoi.io), targeting
**macOS** (Homebrew) and **Arch Linux** (pacman/yay).

## Bootstrap

On a fresh machine (installs chezmoi, pulls this repo, and applies it):

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply fabioluciano/dot
```

Or, if chezmoi is already installed:

```sh
chezmoi init --apply https://github.com/fabioluciano/dot.git
```

### Prerequisites

- A Bitwarden vault unlocked via the `bw` CLI (`bw login && bw unlock`) — used
  to populate tokens/API keys in `~/.zshenv`. The expected item is named
  `dotfiles-tokens`.
- A YubiKey for GPG/SSH commit signing (the `run_before_*` scripts derive the
  public key and `allowed_signers`; signing degrades gracefully if absent).

## What's managed

| Manifest        | Target            | Installed by                                   |
| --------------- | ----------------- | ---------------------------------------------- |
| `dot_Brewfile.tmpl`| `~/.Brewfile`  | `brew bundle --global` (macOS)                 |
| `dot_Pacmanfile`| `~/.Pacmanfile`   | `yay`/`paru`/`pacman -S --needed` (Arch)       |
| `dot_Krewfile`  | `~/.Krewfile`     | `kubectl krew install` (kubectl plugins)       |
| mise            | `~/.config/mise`  | `mise install`                                 |

Package installs run automatically on `chezmoi apply` via the
`run_onchange_after_*` scripts in `.chezmoiscripts/` — they re-run only when the
corresponding manifest changes (tracked by its content hash).

## Day-to-day

```sh
chezmoi edit <file>     # edit a source file in $EDITOR
chezmoi diff            # preview pending changes
chezmoi apply           # apply (and run package sync if a manifest changed)
chezmoi update          # pull latest from the repo and apply
mise run update-safe    # update host packages only (topgrade)
mise run update-full    # full update: packages + dotfiles + krew + nvim + tmux
```

## Layout

- `dot_zshrc.tmpl`, `private_dot_zshenv.tmpl`, `dot_zsh_plugins*.txt.tmpl` — zsh
  (antidote static bundle, cached completions, lazy tool init).
- `private_dot_config/` — app configs (nvim/AstroNvim, tmux, ghostty, k9s, jj,
  starship, mise, espanso, …).
- `private_dot_config/git/`, `private_dot_gnupg/`, `private_dot_ssh/` — git
  identity + SSH-based commit signing via YubiKey.
- `.chezmoiscripts/` — `run_before_*` (YubiKey key material) and
  `run_onchange_after_*` (package sync).

## System Dependencies

These must be present **before** `chezmoi init --apply` will succeed:

| Dependency | Why | macOS | Arch |
|---|---|---|---|
| **chezmoi** (>=2.47) | dotfile manager itself | `brew install chezmoi` | `pacman -S chezmoi` |
| **git** | pulls the source repo | included with Xcode CLI tools | `pacman -S git` |
| **bitwarden-cli** (`bw`) | unlocks `dotfiles-tokens` vault to populate `~/.zshenv` | `brew install bitwarden-cli` | `pacman -S bitwarden-cli` |
| **mise** | installs Node/Python/etc per-project | `brew install mise` | `pacman -S mise` |
| **Homebrew** (macOS) | manages ~170 formulae + casks | already on system | n/a |
| **pacman/yay** (Arch) | manages ~200 packages | n/a | `pacman -S yay` or `paru` |
| **antidote** | zsh plugin manager (fetched by `.chezmoiexternal.toml`) | cloned automatically | cloned automatically |
| **krew** | kubectl plugin manager (`dot_Krewfile`) | `brew install krew` | `pacman -S krew-bin` |

Optional but expected: a **YubiKey** for GPG/SSH commit signing. The
`run_before_*` scripts derive the public key and `allowed_signers`; signing
degrades gracefully if absent.

## Troubleshooting

**Preview before applying:**

```sh
chezmoi diff            # show exactly what would change
chezmoi --dry-run apply # apply without touching anything
```

**chezmoi doctor** catches most misconfigurations (missing git, broken templates,
stale cache):

```sh
chezmoi doctor
```

**Bitwarden vault locked** — the `run_onchange_after_*` scripts call `bw` to
fetch tokens. If the vault is locked, you'll see `bw get` failures:

```sh
bw login
bw unlock          # unlock the vault, then re-run:
chezmoi apply
```

**Template render errors** — if a `.tmpl` file references a missing data key
(defined in `.chezmoidata/`), chezmoi will fail with a template error.
Debug with:

```sh
chezmoi execute-template < private_dot_zshenv.tmpl
```

**antidote not refreshing** — `.chezmoiexternal.toml` sets a 168-hour refresh.
Force an immediate update:

```sh
chezmoi --refresh-externals apply
```

## Rollback

`chezmoi apply` is idempotent. The source directory is the source of truth; the
target files are derived from it. To undo a change:

1. **Inspect what changed:**

   ```sh
   chezmoi diff
   ```

2. **Revert in the source directory:**

   ```sh
   # undo the last commit
   git -C "$(chezmoi source-dir)" revert HEAD

   # or checkout a specific file
   git -C "$(chezmoi source-dir)" checkout HEAD -- <path>
   ```

3. **Re-apply from the reverted source:**

   ```sh
   chezmoi apply
   ```

Because `chezmoi apply` re-syncs from source, reverting a commit and applying
restores the previous state. The `--dry-run` flag lets you verify the rollback
before committing.

**Note:** Package installs (brew/pacman) are not automatically undone by
reverting a dotfile commit. If you added a formula and want to remove it,
edit `dot_Brewfile.tmpl`/`dot_Pacmanfile` and run `chezmoi apply` again.

## Switching opencode provider (`oc-provider`)

The `oc-provider` command switches all opencode agents to use a specific LLM
provider in one shot:

```sh
oc-provider bedrock-claude # switch to the canonical Bedrock Claude chain
oc-provider bedrock-mixed  # switch to the mixed non-Anthropic Bedrock chain
oc-provider opencode    # switch to OpenCode Zen (opencode/ models)
oc-provider opencode-free # switch to free OpenCode Zen models
oc-provider github-copilot # switch to GitHub Copilot Plus models
oc-provider xiaomi      # switch to Xiaomi (mimo)
oc-provider opencode recommended # switch with Oh My OpenAgent recommended tiers
oc-provider github-copilot ultra # GitHub Copilot with lowest safe reasoning variants
```

**How it works:**

1. Writes the chosen provider name to `~/.config/opencode/.active_provider`.
2. Runs `chezmoi apply` to re-render `oh-my-openagent.json` from its template,
   which reads `.active_provider` as the single source of truth (default: `xiaomi`)
   when the file is absent).
3. Each provider entry in the matrix specifies which model, API endpoint, and
   auth mechanism opencode uses for that provider.

**Fallback behavior:** opencode is configured with automatic intra-provider fallback
between tiers (pro → fast → cheap) when the primary model is unavailable
(rate-limited, throttled, etc.). Fallback stays within the active provider —
it never crosses to a different provider. The tier matrix in `.chezmoidata/opencode_providers.toml`
controls the model for each tier.

**Profiles:** pass an optional profile as the second argument. `moderate` is the
default, `optimized`/`super` trade quality for cost, and `recommended` applies
the Oh My OpenAgent recommended effort/variant tiers per role where the active
provider supports them.
`ultra` minimizes cost further by selecting the lowest safe reasoning variant
for each provider/model family and leaving unsupported cases for the provider
runtime default.

**Verify current provider:**

```sh
cat ~/.config/opencode/.active_provider
chezmoi execute-template < private_dot_config/opencode/oh-my-openagent.jsonc.tmpl
```

The `oc-provider` command is part of the opencode tap installed via Homebrew
(`anomalyco/tap/opencode`). On Arch, it's managed alongside the opencode
package.

## Managing opencode skills

The opencode skills lock file (`~/.agents/.skill-lock.json`) **is** tracked by chezmoi and versioned in git. The actual skill files (in `~/.config/opencode/skills/`) are **not** tracked.

When you run `chezmoi apply`, the `.chezmoiscripts/run_onchange_after_60-skills.sh.tmpl` script automatically reinstalls skills whenever the lock file changes. This ensures all machines stay in sync with the same skill versions.

### Install a skill

```sh
# Find skills
npx skills find <query>

# Install from a GitHub repo (global, for opencode)
npx skills add <owner/repo> -a opencode -g

# Example: install community DevOps skills
npx skills add Raishin/vanguard-frontier-agentic -a opencode -g
```

### Manage installed skills

```sh
npx skills list                        # list installed skills
npx skills update -g                   # update all global skills
npx skills remove <skill> -a opencode  # remove a specific skill
```

### How it works

1. The `skills` CLI manages skill installation and updates.
2. When you add/remove/update a skill, the lock file (`~/.agents/.skill-lock.json`) changes.
3. `chezmoi apply` detects the lock file change and runs the sync script.
4. The sync script reinstalls all skills listed in the lock file.
5. Commit the lock file to git so other machines pull the same skill versions.
