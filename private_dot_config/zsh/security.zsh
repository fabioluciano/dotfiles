# GPG/SSH agent setup for YubiKey.
#
# Performance note: this runs on every interactive shell startup but is kept
# minimal. Never replace SSH_AUTH_SOCK unless a usable gpg-agent socket has
# been found; this leaves other agents (including macOS Keychain) untouched
# when GPG or the YubiKey is unavailable.
_setup_gpg_ssh_agent() {
  emulate -L zsh
  local gpg_sock_cache cached_sock candidate cache_dir tmp_cache cache_hit

  # GPG_TTY: only set if we actually have a tty (avoids error noise in
  # headless contexts like gdb-attach). Preserve an existing value.
  if [[ -z "${GPG_TTY:-}" && -n "${TTY:-}" ]]; then
    export GPG_TTY="$TTY"
  fi

  command -v gpgconf &>/dev/null || return 0

  gpg_sock_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/gpg-ssh-auth-sock"
  candidate=''
  cache_hit=0
  if [[ -r "$gpg_sock_cache" ]]; then
    cached_sock=$(<"$gpg_sock_cache") || cached_sock=''
    if [[ -n "$cached_sock" && -S "$cached_sock" ]]; then
      candidate="$cached_sock"
      cache_hit=1
    fi
  fi

  # Refresh a stale or missing cache entry before attempting to launch the
  # agent. A failed gpgconf lookup leaves SSH_AUTH_SOCK unchanged.
  if (( ! cache_hit )); then
    candidate=$(gpgconf --list-dirs agent-ssh-socket 2>/dev/null) || candidate=''
  fi
  [[ -n "$candidate" ]] || return 0

  # Launch only when the candidate is not already a usable socket.
  if [[ ! -S "$candidate" ]]; then
    gpgconf --launch gpg-agent >/dev/null 2>&1 || true
  fi
  [[ -S "$candidate" ]] || return 0

  export SSH_AUTH_SOCK="$candidate"

  # Update the cache only after validating the socket, and replace it
  # atomically so a concurrent shell cannot read a partial path. A valid
  # cache hit is already current and must not touch the filesystem.
  if (( ! cache_hit )); then
    cache_dir="${gpg_sock_cache:h}"
    if mkdir -p "$cache_dir" 2>/dev/null; then
      tmp_cache=$(mktemp "${gpg_sock_cache}.tmp.XXXXXX" 2>/dev/null) || tmp_cache=''
      if [[ -n "$tmp_cache" ]]; then
        if ! printf '%s\n' "$candidate" >"$tmp_cache" ||
          ! mv -f "$tmp_cache" "$gpg_sock_cache" 2>/dev/null; then
          rm -f "$tmp_cache" 2>/dev/null || true
        fi
      fi
    fi
  fi

  return 0
}

_setup_gpg_ssh_agent
