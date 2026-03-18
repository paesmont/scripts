#!/usr/bin/env bash
# =============================================================================
# homebrew.sh - Ferramentas CLI user-space para Fedora Atomic / Bazzite
# =============================================================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/utils.sh"

check_root

info "Instalando ferramentas CLI via Homebrew"

ensure_homebrew
load_homebrew_env || {
    fail "Homebrew nao ficou disponivel no PATH"
    exit 1
}

brew update

formulas=(
    bat
    btop
    eza
    fd
    fish
    fnm
    fzf
    gh
    git
    jq
    lazygit
    neovim
    pipx
    ripgrep
    starship
    stow
    tmux
    yazi
    zoxide
)

for formula in "${formulas[@]}"; do
    brew_install "$formula"
done

append_line_if_missing 'eval "$(fnm env --use-on-cd --shell bash)"' "$HOME/.bashrc"
append_line_if_missing 'eval "$(fnm env --use-on-cd --shell bash)"' "$HOME/.profile"
append_line_if_missing 'fnm env --use-on-cd --shell fish | source' "$HOME/.config/fish/config.fish"
append_line_if_missing 'zoxide init bash | source' "$HOME/.bashrc"
append_line_if_missing 'zoxide init bash | source' "$HOME/.profile"
append_line_if_missing 'zoxide init fish | source' "$HOME/.config/fish/config.fish"

if has_command fnm; then
    eval "$(fnm env --use-on-cd --shell bash)"
    fnm install --lts
    fnm default lts-latest
fi

ok "Ferramentas CLI via Homebrew concluidas"
