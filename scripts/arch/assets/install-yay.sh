#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

main() {
    info "Verificando AUR helper (yay)..."

    if ! command -v yay >/dev/null 2>&1; then
        warn "yay não encontrado. Instalação automática pode exigir intervenção manual."
        info "Sugestão:"
        info "  git clone --depth=1 https://aur.archlinux.org/yay.git"
        info "  cd yay && makepkg -si --noconfirm"
        info "  cd .. && rm -rf yay"
        return
    else
        ok "yay encontrado."
    fi
}

main "$@"
