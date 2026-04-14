#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

main() {
    HYPRLAND_CONFIG="$HOME/.config/hypr/hyprland.conf"
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    OVERRIDES_CONFIG="$SCRIPT_DIR/hyprland-overrides.conf"
    SOURCE_LINE="source = $OVERRIDES_CONFIG"

    info "Configurando overrides do Hyprland"

    # Check if hyprland config exists
    if [ ! -f "$HYPRLAND_CONFIG" ]; then
        warn "Configuração do Hyprland não encontrada em $HYPRLAND_CONFIG"
        warn "Por favor, instale o Hyprland primeiro"
        return 1
    fi

    # Check if overrides config exists
    if [ ! -f "$OVERRIDES_CONFIG" ]; then
        warn "Arquivo de overrides não encontrado em $OVERRIDES_CONFIG"
        return 1
    fi

    # Check if source line already exists in hyprland.conf
    if grep -Fxq "$SOURCE_LINE" "$HYPRLAND_CONFIG"; then
        ok "Linha de source já existe em $HYPRLAND_CONFIG"
    else
        info "Adicionando linha de source em $HYPRLAND_CONFIG"
        echo "" >> "$HYPRLAND_CONFIG"
        echo "$SOURCE_LINE" >> "$HYPRLAND_CONFIG"
        ok "Linha de source adicionada com sucesso"
    fi

    ok "Setup de overrides do Hyprland completo!"
}

main "$@"