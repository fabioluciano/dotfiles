# GPG/SSH agent setup for YubiKey.
#
# Performance note: this runs on every interactive shell startup but is kept
# minimal. SSH_AUTH_SOCK is always pointed at the gpg-agent socket when
# gpgconf is available — this overrides the macOS Keychain socket
# (/var/run/com.apple.launchd.*/Listeners) which is set by launchd before
# the shell starts and would otherwise prevent the YubiKey from being used.
if command -v gpgconf &>/dev/null; then
  # GPG_TTY: only set if we actually have a tty (avoids error noise in
  # headless contexts like gdb-attach). ${TTY} is set by zsh for interactive
  # shells and is cheaper than calling $(tty).
  [[ -z "${GPG_TTY:-}" && -n "${TTY:-}" ]] && export GPG_TTY="$TTY"

  # SSH_AUTH_SOCK: always point to gpg-agent so the YubiKey private key is
  # reachable. The macOS launchd socket is set before the shell starts and
  # must be explicitly overridden here; the -z guard is intentionally removed.
  export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
  gpgconf --launch gpg-agent 2>/dev/null
fi
