#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

main() {
    info "Instalando fontes (programação + nerd fonts)..."

    # Fedora: pacotes de fontes oficiais; Nerd Fonts requerem instalação manual.
    packages=(
        "fira-code-fonts"
        "jetbrains-mono-fonts"
        "ubuntu-fonts"
        "google-space-mono-fonts"
        "google-inconsolata-fonts"
    )

    for pkg in "${packages[@]}"; do
        ensure_package "$pkg"
    done

    warn "TODO: Nerd Fonts não estão nos repositórios oficiais do Fedora; instalar manualmente se necessário."

    ok "Fontes instaladas."
}

main "$@"
