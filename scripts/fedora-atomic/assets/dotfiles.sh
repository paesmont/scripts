#!/usr/bin/env bash
# =============================================================================
# dotfiles.sh - Dotfiles e configuracoes de usuario
# =============================================================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/utils.sh"

check_root

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/bashln/dotfiles.git}"
DOTFILES_BRANCH="${DOTFILES_BRANCH:-windows}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

info "Configurando dotfiles"

if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
    git clone --depth=1 --branch "$DOTFILES_BRANCH" "$DOTFILES_REPO" "$DOTFILES_DIR"
else
    git -C "$DOTFILES_DIR" fetch origin
    git -C "$DOTFILES_DIR" checkout -B "$DOTFILES_BRANCH" "origin/$DOTFILES_BRANCH"
fi

mkdir -p "$HOME/.config"

for path in alacritty fish kitty nvim ghostty; do
    if [[ -d "$DOTFILES_DIR/.config/$path" ]]; then
        ln -sfn "$DOTFILES_DIR/.config/$path" "$HOME/.config/$path"
        ok "Link criado: $HOME/.config/$path"
    fi
done

if [[ -f "$DOTFILES_DIR/.config/starship.toml" ]]; then
    ln -sfn "$DOTFILES_DIR/.config/starship.toml" "$HOME/.config/starship.toml"
    ok "Link criado: $HOME/.config/starship.toml"
fi

ok "Dotfiles configurados"
