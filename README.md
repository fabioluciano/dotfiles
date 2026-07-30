# dotfiles

Personal dotfiles managed with [chezmoi](https://chezmoi.io), targeting
**macOS** (Homebrew) and **Arch Linux** (pacman plus yay/paru for AUR packages).

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
- On Arch, `yay` or `paru` must be installed before `chezmoi apply`. The
  Pacmanfile contains AUR packages such as `zsh-antidote`; the sync script
  fails clearly instead of trying to pass them to plain `pacman`.

## What's managed

| Manifest        | Target            | Installed by                                   |
| --------------- | ----------------- | ---------------------------------------------- |
| `dot_Brewfile.tmpl`| `~/.Brewfile`  | `brew bundle --global` (macOS)                 |
| `dot_Pacmanfile`| `~/.Pacmanfile`   | `yay -S --needed`/`paru -S --needed` (Arch; AUR helper required) |
| `dot_Krewfile`  | `~/.Krewfile`     | `kubectl krew install` (kubectl plugins)       |
| mise            | `~/.config/mise`  | `mise install`                                 |

Package installs run automatically on `chezmoi apply` via the
`run_onchange_after_*` scripts in `.chezmoiscripts/` — they re-run only when the
corresponding manifest changes (tracked by its content hash). Separately,
`run_after_60-antidote-bundles.sh.tmpl` runs after those package hooks on every
`chezmoi apply`: it runs `antidote update --bundles` to update plugin clones
without updating Antidote itself, then rebuilds both static bundles. The hook is
non-fatal for treatable errors, waits up to five seconds for its common lock, and
preserves all four bundle artifacts, although the update may already have
changed some plugin clones before a later failure.

## Day-to-day

```sh
chezmoi edit <file>     # edit a source file in $EDITOR
chezmoi diff            # preview pending changes
chezmoi apply           # apply (package sync on manifest changes; Antidote hook every apply)
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
- `.chezmoiscripts/` — `run_before_*` (YubiKey key material),
  `run_onchange_after_*` (package sync), and
  `run_after_60-antidote-bundles.sh.tmpl` (Antidote refresh and bundle rebuild
  on every apply).

## System Dependencies

These must be present **before** `chezmoi init --apply` will succeed:

| Dependency | Why | macOS | Arch |
|---|---|---|---|
| **chezmoi** (>=2.47) | dotfile manager itself | `brew install chezmoi` | `pacman -S chezmoi` |
| **git** | pulls the source repo | included with Xcode CLI tools | `pacman -S git` |
| **bitwarden-cli** (`bw`) | unlocks `dotfiles-tokens` vault to populate `~/.zshenv` | `brew install bitwarden-cli` | `pacman -S bitwarden-cli` |
| **mise** | installs Node/Python/etc per-project | `brew install mise` | `pacman -S mise` |
| **Homebrew** (macOS) | manages ~170 formulae + casks | already on system | n/a |
| **pacman + yay/paru** (Arch) | manages repository and AUR packages | n/a | `pacman` is built in; install `yay` or `paru` before applying |
| **antidote** | zsh plugin manager (bundles rebuilt by the post-apply hook) | `brew install antidote` | `yay -S zsh-antidote` or `paru -S zsh-antidote` (AUR) |
| **pkgfile** | local package index used by Arch's `command-not-found` plugin | n/a | included in `dot_Pacmanfile`; initialize with `sudo pkgfile -u` |
| **krew** | kubectl plugin manager (`dot_Krewfile`) | `brew install krew` | `pacman -S krew-bin` |

To bootstrap an AUR helper on a fresh Arch installation, install the build
tools with `pacman`, then build one helper from the AUR before applying this
repository. For example:

```sh
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/yay.git
(cd yay && makepkg -si)
rm -rf yay
```

After that, `chezmoi apply` can install `zsh-antidote` and the remaining
manifest packages through `yay` (replace it with `paru` if that is your
chosen helper). The Arch `command-not-found` plugin uses `pkgfile`; run
`sudo pkgfile -u` after the first installation and periodically to refresh its
local index.

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

**antidote bundle not refreshing** —
`run_after_60-antidote-bundles.sh.tmpl` runs after the package hooks on every
`chezmoi apply`. It first runs `antidote update --bundles` (which updates plugin
clones, not Antidote itself) and then regenerates and compiles both static
bundles from `~/.zsh_plugins_pre.txt` and `~/.zsh_plugins.txt`. If updating,
rendering, validation, compilation, or lock acquisition fails, the hook is
non-fatal and preserves the four bundle artifacts byte-for-byte; inspect the
warning on stderr. The update can have changed some plugin clones before that
failure, so a later apply may retry with those clones.

The normal zsh startup path loads the static bundles. Its conditional fallback
may call `antidote bundle` when a manifest is newer or the Antidote cache is
missing, but it first takes the common kernel lock with a zero-second timeout.
If another process holds that lock, startup does not wait or regenerate and
loads the current bundle instead.

**Updating plugins** — explicit plugin references in these manifests are not
pinned to SHA values. On every `chezmoi apply`, `antidote update --bundles`
updates their clones before `antidote bundle` regenerates and compiles the
static bundles; `antidote bundle` itself does not pull updates. Review with
`chezmoi diff` before applying. If the refresh fails, the current four bundle
artifacts stay intact, even though some clones may already have been updated.

Entries using `kind:defer` are a deliberate exception: Antidote injects
`romkatv/zsh-defer` internally and provides no officially supported syntax for
pinning that injected dependency. This keeps those plugins on the deferred
startup path.

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
oc-provider opencode    # switch to OpenCode Zen (opencode/ models)
oc-provider openai      # switch to OpenAI models
oc-provider xiaomi      # switch to Xiaomi (mimo)
oc-provider opencode recommended # switch with Oh My OpenAgent recommended tiers
oc-provider deepseek ultra # DeepSeek with lowest safe reasoning variants
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

Opencode skills are managed by the `skills` CLI and are **not** tracked by chezmoi.
Skill files live in `~/.config/opencode/skills/` and the lock file is at
`~/.agents/.skill-lock.json`. Use `mise run skills-*` tasks (defined in
`~/.config/mise/config.toml`) or run the `skills` CLI directly to install,
update, and remove skills across machines.
