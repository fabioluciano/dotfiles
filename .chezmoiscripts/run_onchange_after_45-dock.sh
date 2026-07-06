#!/usr/bin/env bash
# Configure Dock apps and separators by category. Safe to re-run.

set -euo pipefail

[[ "$(uname -s)" == "Darwin" ]] || exit 0
command -v dockutil >/dev/null 2>&1 || exit 0

# Clear all current Dock items
dockutil --remove all --no-restart

# ── Sistema ──────────────────────────────────────────────────────────────────
# Finder is always pinned by macOS — no need to add it manually
dockutil --add /System/Applications/Apps.app --no-restart
dockutil --add /System/Applications/System\ Settings.app --no-restart
dockutil --add /System/Applications/App\ Store.app --no-restart

dockutil --add '' --type small-spacer --section apps --no-restart

# ── Browsers ─────────────────────────────────────────────────────────────────
dockutil --add /Applications/Safari.app --no-restart
dockutil --add /Applications/Firefox.app --no-restart
dockutil --add /Applications/Google\ Chrome.app --no-restart

dockutil --add '' --type small-spacer --section apps --no-restart

# ── Comunicação ──────────────────────────────────────────────────────────────
dockutil --add /System/Applications/Mail.app --no-restart
dockutil --add /Applications/Thunderbird.app --no-restart
dockutil --add /Applications/WhatsApp.app --no-restart
dockutil --add /Applications/Telegram.app --no-restart
dockutil --add /Applications/Discord.app --no-restart

dockutil --add '' --type small-spacer --section apps --no-restart

# ── Produtividade ─────────────────────────────────────────────────────────────
dockutil --add /System/Applications/Calendar.app --no-restart
dockutil --add /System/Applications/Reminders.app --no-restart
dockutil --add /System/Applications/Notes.app --no-restart
dockutil --add /Applications/Obsidian.app --no-restart

dockutil --add '' --type small-spacer --section apps --no-restart

# ── AI ───────────────────────────────────────────────────────────────────────
dockutil --add /Applications/ChatGPT.app --no-restart
dockutil --add /Applications/Claude.app --no-restart

dockutil --add '' --type small-spacer --section apps --no-restart

# ── Dev ───────────────────────────────────────────────────────────────────────
dockutil --add /Applications/Ghostty.app --no-restart
dockutil --add /Applications/Visual\ Studio\ Code.app --no-restart
dockutil --add /Applications/Zed.app --no-restart
dockutil --add /Applications/DBeaver.app --no-restart
dockutil --add /Applications/Parallels\ Desktop.app --no-restart
dockutil --add /Applications/Podman\ Desktop.app --no-restart

dockutil --add '' --type small-spacer --section apps --no-restart

# ── Mídia ─────────────────────────────────────────────────────────────────────
dockutil --add /Applications/Spotify.app --no-restart
dockutil --add /Applications/NetNewsWire.app --no-restart

# ── Diretórios ────────────────────────────────────────────────────────────────
dockutil --add ~/Downloads --view fan --display folder --sort dateadded --no-restart

# Restart Dock once at the end
killall Dock
