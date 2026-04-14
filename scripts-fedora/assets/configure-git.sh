#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

main() {
    info "Configurando Git"

    if ! command -v git >/dev/null 2>&1; then
        warn "git não encontrado; instale antes de configurar."
        return
    fi

    if git config --global user.email >/dev/null 2>&1 && \
        git config --global user.name  >/dev/null 2>&1; then
        ok "Git global já configurado (user.name/user.email)."
        return
    fi

    info "Configurando Git global..."

    read -rp "Digite seu email para Git: " git_email
    read -rp "Digite seu nome para Git: " git_name

    git config --global user.email "${git_email}"
    git config --global user.name "${git_name}"

    ok "Git configurado com user.name e user.email globais."
}

main "$@"
