# Export the active opencode provider for any consumer that reads it (e.g.
# statusline scripts, prompts). Reads from the state file written by `oc-provider`.
#
# Uses zsh builtins (read + parameter expansion) instead of awk to avoid a
# subprocess on every shell startup. Falls back to the default provider if the
# file is missing or has no provider line.
#
# NOTE: the hardcoded fallback below MUST match [opencode].default_provider in
# .chezmoidata/opencode_providers.toml. It is kept as a literal string (not a
# chezmoi template expansion) intentionally: running `chezmoi data` on every
# shell startup would be too slow. Update both values together when changing the
# default provider.
_opencode_active_provider="xiaomi"
if [[ -r "${HOME}/.config/opencode/.active_provider" ]]; then
  while IFS=':' read -r key value; do
    if [[ "$key" == "provider" && -n "$value" ]]; then
      _opencode_active_provider="$value"
      break
    fi
  done < "${HOME}/.config/opencode/.active_provider"
fi
export OPENCODE_PROVIDER="$_opencode_active_provider"
unset _opencode_active_provider
