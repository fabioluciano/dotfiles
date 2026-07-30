#!/usr/bin/env bash
# Configure Touch ID for sudo and battery percentage.
# Safe to re-run.

set -euo pipefail

[[ "$(uname -s)" == "Darwin" ]] || exit 0

# Touch ID for sudo via /etc/pam.d/sudo_local (mecanismo oficial no
# Sonoma+; sobrevive a updates do macOS, ao contrario de editar sudo direto).
if [[ -f /usr/lib/pam/pam_tid.so ]]; then
    if ! grep -q "pam_tid.so" /etc/pam.d/sudo_local 2>/dev/null; then
        echo "auth       sufficient     pam_tid.so" | sudo tee -a /etc/pam.d/sudo_local >/dev/null
        echo "Touch ID configured for sudo"
    fi
fi

# Show battery percentage.
defaults write com.apple.menuextra.battery ShowPercent -string "YES"

killall SystemUIServer >/dev/null 2>&1 || true
