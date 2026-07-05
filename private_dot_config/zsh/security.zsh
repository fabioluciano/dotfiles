# GPG/SSH agent setup for YubiKey.
#
# Performance note: this runs on every interactive shell startup but is kept
# minimal. SSH_AUTH_SOCK and the agent launch are gated on gpgconf existing;
# the socket path is stable across sessions so we don't recompute it once set
# in the environment (re-sourcing won't re-launch if already exported).
if command -v gpgconf &>/dev/null; then
  # GPG_TTY: only set if we actually have a tty (avoids error noise in
  # headless contexts like gdb-attach). ${TTY} is set by zsh for interactive
  # shells and is cheaper than calling $(tty).
  [[ -z "${GPG_TTY:-}" && -n "${TTY:-}" ]] && export GPG_TTY="$TTY"

  # SSH_AUTH_SOCK: compute once. If already in the environment (inherited from
  # a parent shell), keep it; otherwise derive from gpgconf and launch the agent.
  if [[ -z "${SSH_AUTH_SOCK:-}" ]]; then
    export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
    gpgconf --launch gpg-agent 2>/dev/null
  fi
fi
