#!/usr/bin/env bash
# =============================================================================
# flatpaks.sh - Aplicacoes graficas para Fedora Atomic / Bazzite
# =============================================================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/utils.sh"

check_root

info "Instalando aplicacoes Flatpak"

ensure_flathub

# Preferencia por Flatpak no Atomic para apps graficos de desktop.
apps=(
    "com.spotify.Client"
    "com.microsoft.Edge"
    "com.visualstudio.code"
    "org.videolan.VLC"
    "org.remmina.Remmina"
    "net.davidotek.pupgui2"
)

for app in "${apps[@]}"; do
    flatpak_install "$app"
done

ok "Aplicacoes Flatpak concluidas"
