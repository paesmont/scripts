#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

REPO_URL="git@gitlab.com:bashln/dotfiles.git"
REPO_NAME="dotfiles"

main() {
    info "Instalando dotfiles"

    command -v stow >/dev/null 2>&1 || die "stow não está instalado"
    command -v git >/dev/null 2>&1 || die "git não está instalado"

    cd "$HOME"

    if [[ -d "$REPO_NAME" ]]; then
        info "Repositório '$REPO_NAME' já existe, usando o local"
    else
        info "Clonando dotfiles..."
        git clone "$REPO_URL"
    fi

    cd "$REPO_NAME"

    info "Aplicando dotfiles com stow..."
    stow .

    ok "Dotfiles aplicados com sucesso."
}

main "$@"
