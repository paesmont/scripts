#!/usr/bin/env bash
# =============================================================================
# install-gaming.sh - Steam, ProtonUp-Qt e ferramentas de gaming
# =============================================================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/utils.sh"

check_root

info "Instalando ferramentas de gaming"

ensure_flathub

flatpak_install "com.valvesoftware.Steam"
flatpak_install "net.davidotek.pupgui2"

ok "Gaming pronto - reinicie o Steam apos instalar"
