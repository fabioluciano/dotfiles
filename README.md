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
| `dot_Brewfile.tmpl`| `~/.Brewfile`  | `brew bundle --global` (macOS; taps + casks + core formulae) |
| `dot_Pacmanfile`| `~/.Pacmanfile`   | `yay -S --needed`/`paru -S --needed` (Arch; AUR helper required) |
| `dot_Krewfile`  | `~/.Krewfile`     | `kubectl krew install` (kubectl plugins)       |
| mise            | `~/.config/mise`  | `mise install`                                 |

Package installs run automatically on `chezmoi apply` via the
`run_onchange_after_*` scripts in `.chezmoiscripts/` — they re-run only when the
corresponding manifest changes (tracked by its content hash). Token sync
(`run_onchange_after_46-zsh-tokens`) and `mise install`
(`run_onchange_after_47-mise-install`) run after the package hooks so that
`bw`/`kubectl-argo-rollouts`/etc. already exist on first bootstrap; renaming
the hooks means they will execute once more on the next apply. Separately,
`run_after_60-antidote-bundles.sh.tmpl` runs after the package hooks on every
`chezmoi apply`: it runs `antidote update --bundles` to update plugin clones
without updating Antidote itself, then rebuilds both static bundles. The hook
shares the canonical lock `~/.cache/zsh/.zsh_plugins.lock` with the zsh startup
so the two cannot regenerate bundles simultaneously. Treatable contention is
non-fatal and keeps the current artifacts; genuine failures propagate a
non-zero status, although the update may already have changed some plugin
clones before a later failure.

## Day-to-day

```sh
chezmoi edit <file>     # edit a source file in $EDITOR
chezmoi diff            # preview pending changes (now includes scripts)
chezmoi apply           # apply (package sync on manifest changes; Antidote hook every apply)
chezmoi update          # pull latest from the repo and apply
mise run lint           # strict, non-mutating static checks (exits non-zero on failure)
mise run lint-report    # same checks, does not block
mise run doctor-chezmoi # chezmoi doctor + dry-run apply
mise run doctor-nvidia  # NVIDIA driver, KMS, VA-API and Vulkan (Arch)
mise run benchmark-nvim # measure isolated Neovim cold/warm startup, median and p95
mise run benchmark-zsh  # same for zsh, including zprof output in scratch
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

## NVIDIA / GPU (Arch)

The Arch desktop uses an NVIDIA RTX 3060 with the open kernel modules
(`nvidia-open`), KMS and fbdev enabled. The driver stack is declared in
`dot_Pacmanfile`; the boot-time pieces are system-level and intentionally
**not** written by chezmoi:

- `/etc/kernel/cmdline` must contain
  `nvidia_drm.modeset=1 nvidia_drm.fbdev=1` (systemd-boot UKI).
- `/etc/mkinitcpio.conf` must include the NVIDIA modules in `MODULES`, e.g.
  `MODULES=(nvidia nvidia-modeset nvidia_uvm nvidia_drm)`, followed by
  `sudo mkinitcpio -P`.
- Reboot after changing either file.

Verify the stack with:

```sh
nvidia-smi
cat /sys/module/nvidia_drm/parameters/modeset   # Y
vainfo                                          # NVDEC direct backend
vulkaninfo --summary                            # NVIDIA device
xrandr --listproviders                          # NVIDIA-0 + modesetting
mise run doctor-nvidia
```

User-level pieces managed here:

- `~/.xprofile` exports `LIBVA_DRIVER_NAME=nvidia` and
  `MOZ_DISABLE_RDD_SANDBOX=1` for the Xfce session.
- `~/.config/environment.d/90-nvidia.conf` exports the same values to
  `systemd --user` services (e.g. apps launched by Vicinae).
- `~/.config/mpv/mpv.conf` uses `vo=gpu-next`, `hwdec=auto-safe` and
  `gpu-api=vulkan`.
- `run_after_56-firefox-vaapi.sh.tmpl` injects the Firefox VA-API prefs into
  each profile's `user.js`.
- Compiz disables X11 sync on NVIDIA (`x11_sync_blacklist_vendor`), pins the
  composite refresh rate to 165 Hz and enables independent output painting and
  fullscreen unredirect.

No fan curve, overclock or power-limit changes are applied; the card runs at
its stock 170 W limit. The AMD Raphael iGPU is present but the monitors are
connected to the NVIDIA card, so no PRIME/offload is configured. `nvidia-open`
is the non-DKMS package and is tied to the `linux` kernel; if you switch to
`linux-lts` or `linux-zen`, install `nvidia-open-dkms` (or the matching
package) instead.

With `nvidia-open`, video memory is preserved across suspend automatically;
the `nvidia-suspend`/`nvidia-resume` services are not required and remain
disabled. `nvidia-persistenced` and `nvidia-powerd` are also unnecessary on
this desktop.

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

## Plank Reloaded (Arch Linux)

Plank Reloaded runs a single dock (`dock1`) on the primary X11 monitor.
The legacy `plank-multidock` startup entry point now starts only that dock;
secondary dock data is retained but is not launched automatically.

The Plank hook groups existing pinned launchers into system/files, browsers,
communication, notes, development, media, other applications, and folders/trash.
Native separator docklets divide nonempty groups using empty spaces, not lines
(`DockySeparatorPreferences/Style=2`, with no custom icon). This style is
enforced for managed `dotfiles-separator-*` items, including existing ones.
Existing launcher filenames
and preferences are preserved; default applications are seeded only for an
empty dock. The grouping implementation lives in
`.chezmoitemplates/plank/organize.py` and uses the system Python.
File/docklet anchoring and active-display tracking are disabled so category
ordering is respected and the dock stays on the primary monitor.

For an isolated organization update without resetting theme, icon size or zoom:

```sh
chezmoi execute-template < "$(chezmoi source-path)/.chezmoiscripts/run_after_59-plank.sh.tmpl" | bash -s -- --organize-only
```

Run regression tests with `/usr/bin/python3 -B .chezmoitemplates/plank/test_organize.py`.

## Xfce XML configuration

Xfconf XML remains versioned under `.chezmoitemplates/xfce/`. Edit those XMLs
to change managed preferences; the corresponding files under
`private_dot_config/xfce4/xfconf/private_xfce-perchannel-xml/` are rendering
wrappers. Avoid `chezmoi re-add` for these targets, since capturing the live
XML is not a substitute for editing the managed defaults.

The templates run `.chezmoitemplates/xfce/render.py` with `/usr/bin/python3`
(the system Python on Arch, not mise). Rendering only reads the destination;
it never calls `xfconf-query`, writes files, or restarts the desktop.
They preserve the current wallpaper and desktop settings window geometry,
Whisker recent applications, tray item history, and known media players.
New installations use the versioned XML defaults. Other properties, including
wallpaper cycling settings, theme, panel layout, shortcuts, and display
configuration, remain managed and produce a diff when changed.

Property ordering, comments, whitespace, and equivalent double representations
do not trigger changes: when the merged XML is semantically equivalent, the
template returns the destination contents unchanged. Array order still matters.
Malformed destination XML causes rendering to fail rather than overwrite it.
As with any Xfconf XML edit, applying real preference changes while `xfconfd`
is running can race with its in-memory state; this does not replace a safe
session-level procedure for applying desktop configuration.

Run the non-mutating regression tests with:

```sh
/usr/bin/python3 -B .chezmoitemplates/xfce/test_render.py
```

## LightDM appearance (Arch Linux)

`lightdm-slick-greeter` uses Colloid Grey Dark Compact, Colloid Dark icons,
a centered login form, and the current primary monitor wallpaper. The theme
settings live in `.chezmoitemplates/lightdm/slick-greeter.conf`.

On each apply, `.chezmoiscripts/run_after_62-lightdm-theme.sh.tmpl` snapshots
the current Xfce wallpaper into a metadata-stripped PNG under
`/usr/local/share/backgrounds/dotfiles/`. It does not grant the greeter access
to your home directory or Dropbox. Without a graphical session it keeps the
previous public copy; without any wallpaper or required packages it skips
installation. Assets must therefore be prepared from a graphical session at
least once. A later apply can update the snapshot if the desktop wallpaper
has changed.

The hook writes `/etc/lightdm/slick-greeter.conf` and the dedicated
`/etc/lightdm/lightdm.conf.d/90-dotfiles-greeter.conf` drop-in. It only writes
when contents change, backs up existing files once as `.chezmoi-backup`, and
requires `sudo -v` before an apply that needs system changes. It never restarts
LightDM, changes PAM, enables autologin, or changes the desktop's display layout.
The new appearance is used on the next greeter launch; save your work before
logging out to test it. `lightdm --show-config` shows the effective selection.

The existing GTK greeter is kept installed. To return to it, first disable the
LightDM theme hook in the source, then remove its dedicated greeter drop-in
(or restore its `.chezmoi-backup` if a previous file existed). Do not restart
the display-manager service from a session you want to keep.

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
remove it from `dot_Brewfile.tmpl`/`dot_Pacmanfile` and uninstall it explicitly
with the package manager.

## AI agent: OMP

OMP is the only managed AI agent. Homebrew installs it on macOS; mise installs
it on Linux. The Zsh wrapper loads API tokens from the existing Bitwarden-backed
file on demand.

Configuration lives in `private_dot_omp/agent/`:

- `config.yml.tmpl`: direct model roles, theme and LSP settings.
- `mcp.json`: MCP servers.

```sh
omp
omp --model xiaomi-token-plan-sgp/mimo-v2.5
mise run doctor-omp
```

For persistent model changes, edit `modelRoles` in the source template and run
`chezmoi apply ~/.omp/agent/config.yml`. There is no provider matrix or profile
synchronization; models and endpoints come from the native OMP catalog. OMP extensions are listed in `dot_OmpPlugins`.

Retired configuration files are removed through `.chezmoiremove`; session
history and authentication stores are preserved. Removing a package from a
manifest prevents future installation but does not uninstall an existing copy;
uninstall that package explicitly with its package manager.

## Validation and health checks

This is configuration, not an application, so there is no build/test suite.
Validation is static and non-mutating:

- Safe (read-only):
  - `mise run lint-report` or `dotfiles-lint --report` — all checks, never blocks.
  - `mise run lint` or `dotfiles-lint --strict` — same checks, exits non-zero on failure.
  - `chezmoi doctor`, `chezmoi diff`, `chezmoi status`.
  - `mise run doctor-nvidia` — NVIDIA driver, KMS, VA-API and Vulkan (Arch).
  - `chezmoi execute-template < file.tmpl` — render a template to stdout for inspection
    (do not use on templates that read live secrets/Bitwarden/YubiKey).
  - `zsh -n`, `bash -n`, `shellcheck`, `taplo check`, `yamllint`, `luac -p`, `stylua --check`.
- Mutating (requires intent):
  - `chezmoi --dry-run apply` — safe preview, but review which hooks would run.
  - `chezmoi apply` — installs packages, syncs tokens, runs Antidote, runs `mise install`.
  - `nvim --headless +qa` — may bootstrap `lazy.nvim`, install Mason packages and download spellfiles.
  - `nvim --headless '+Lazy! sync' +qa` (or `mise run update-nvim`) — updates plugins.
  - `mise install` / `mise upgrade` / `mise run update-full` — updates all tools.

Global tools intentionally follow `latest`. Pin specific versions only per-project
via a `.mise.toml` / `mise.toml` in the project root; do not commit pins to global config.

## Verifying a fresh-machine bootstrap (manual checklist)

Before running `chezmoi init --apply` on a new machine, inspect first:

```sh
git status
git diff
chezmoi diff
chezmoi --dry-run apply
```

Confirm no `REBASE_HEAD`/conflicts, then apply.
