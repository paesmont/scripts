#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

main() {
    info "Instalando Ruby"

    # Check if asdf is installed
    if ! command -v asdf &>/dev/null; then
        fail "asdf não está instalado. Por favor, execute install-asdf.sh primeiro."
        exit 1
    fi

    # Install Ruby build dependencies
    info "Instalando dependências de build do Ruby..."
    # Fedora: usar pacotes -devel equivalentes ao base-devel do Arch.
    packages=(
        "gcc"
        "make"
        "openssl-devel"
        "readline-devel"
        "zlib-devel"
        "libyaml-devel"
        "libffi-devel"
    )
    for pkg in "${packages[@]}"; do
        ensure_package "$pkg"
    done

    # Install ruby plugin for asdf if not already installed
    if ! asdf plugin list | grep -q ruby; then
        info "Adicionando plugin Ruby para asdf."
        asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git
    else
        ok "Plugin Ruby para asdf já instalado."
    fi

    # Install latest stable Ruby if no ruby version is installed
    if ! asdf list ruby &>/dev/null || [ -z "$(asdf list ruby 2>/dev/null)" ]; then
        info "Instalando a versão mais recente do Ruby..."
        asdf install ruby latest
        asdf set -u ruby latest
        ok "Ruby instalado."
    else
        ok "Ruby já instalado."
    fi

    ok "Instalação e configuração do Ruby concluídas!"
}

main "$@"
