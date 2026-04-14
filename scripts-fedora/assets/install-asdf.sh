#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

main() {
    info "Instalando asdf (via git, compatível com Fedora)"

    if [ -d "$HOME/.asdf" ]; then
        ok "asdf já instalado em ~/.asdf"
        return
    fi

    ensure_package "git"

    # Fedora não possui AUR; usamos a instalação oficial via git.
    git clone https://github.com/asdf-vm/asdf.git "$HOME/.asdf" --branch v0.14.0
    ok "asdf instalado em ~/.asdf"
}

main "$@"
