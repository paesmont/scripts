#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

main() {
    info "Instalando Zsh e configurando Oh-My-Zsh..."

    # Instala zsh via DNF
    ensure_package "zsh"

    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        info "Instalando Oh-My-Zsh (modo unattended)..."
        if ! sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
            fail "Falha ao instalar Oh-My-Zsh (verifique conexao)."
        fi
    else
        ok "Oh-My-Zsh ja instalado; pulando."
    fi

    local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    mkdir -p "$zsh_custom/plugins" "$zsh_custom/themes"

    git clone --depth=1 https://github.com/unixorn/fzf-zsh-plugin \
        "$zsh_custom/plugins/fzf-zsh-plugin" \
        || warn "fzf-zsh-plugin ja existe ou falha no clone."

    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
        "$zsh_custom/plugins/zsh-autosuggestions" \
        || warn "zsh-autosuggestions ja existe ou falha no clone."

    git clone --depth=1 https://github.com/zsh-users/zsh-completions \
        "$zsh_custom/plugins/zsh-completions" \
        || warn "zsh-completions ja existe ou falha no clone."

    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git \
        "$zsh_custom/plugins/zsh-syntax-highlighting" \
        || warn "zsh-syntax-highlighting ja existe ou falha no clone."

    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
        "$zsh_custom/themes/powerlevel10k" \
        || warn "powerlevel10k ja existe ou falha no clone."

    if [[ ! -d "$HOME/.fzf" ]]; then
        git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf" || warn "Falha ao clonar fzf."
        "$HOME/.fzf/install" --all || warn "Falha ao rodar instalador do fzf."
    else
        ok "fzf ja esta instalado em ~/.fzf; pulando."
    fi

    ok "Zsh/Oh-My-Zsh + plugins configurados."
}

main "$@"
