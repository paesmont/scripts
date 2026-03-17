#!/usr/bin/env bash
# =============================================================================
# install/shell-default-fish.sh - Define Fish como shell padrão
# =============================================================================

set -euo pipefail

source "$(dirname "$0")/../lib/utils.sh"

check_root

info "Configurando Fish como shell padrão..."

if [[ "$SHELL" == *"fish"* ]]; then
    info "Fish já é o shell padrão"
    exit 0
fi

FISH_PATH="$(command -v fish 2>/dev/null)"
if [[ -z "$FISH_PATH" ]]; then
    log_warn "Caminho do Fish não encontrado"
    exit 0
fi

read -r -p "Deseja definir Fish como shell padrão? [y/N]: " change_shell
if [[ ! "$change_shell" =~ ^[Yy]$ ]]; then
    info "Mantendo shell padrão atual"
    exit 0
fi

if chsh -s "$FISH_PATH"; then
    ok "Fish configurado como shell padrão"
else
    log_warn "Não foi possível alterar o shell padrão"
fi
