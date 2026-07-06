#!/usr/bin/env bash
# Instala extensoes do gh CLI (gh-dash, gh-poi). gh extensions nao sao formulas
# brew/pacman — precisam ser instaladas via `gh extension install`.
# Re-executa quando esta lista mudar (conteudo do script e o hash do onchange).
set -euo pipefail

command -v gh >/dev/null 2>&1 || exit 0
gh auth status >/dev/null 2>&1 || { echo "gh nao autenticado; pulando extensoes." >&2; exit 0; }

extensions=(
    dlvhdr/gh-dash
    seachicken/gh-poi
)

for ext in "${extensions[@]}"; do
    if ! gh extension list 2>/dev/null | grep -q "${ext}"; then
        echo ":: gh extension install ${ext}"
        gh extension install "${ext}" || echo "  ${ext}: falhou, instale manualmente" >&2
    fi
done
