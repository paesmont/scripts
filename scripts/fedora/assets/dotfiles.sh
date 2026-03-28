#!/usr/bin/env bash
# =============================================================================
# install/dotfiles.sh - Clonar e configurar dotfiles
# =============================================================================

set -euo pipefail

source "$(dirname "$0")/../lib/utils.sh"

check_root

DOTFILES_REPO="https://github.com/bashln/dotfiles.git"
DOTFILES_BRANCH="windows"
DOTFILES_DIR="$HOME/dotfiles"

info "Configurando dotfiles..."

if [[ ! -d "$DOTFILES_DIR" ]]; then
    info "Clonando dotfiles..."
    git clone --depth=1 --branch "$DOTFILES_BRANCH" "$DOTFILES_REPO" "$DOTFILES_DIR"
    ok "Dotfiles clonados"
else
    info "Atualizando dotfiles..."
    cd "$DOTFILES_DIR"
    git fetch origin
    if git diff --quiet HEAD "origin/$DOTFILES_BRANCH" 2>/dev/null; then
        ok "Dotfiles já atualizados"
    else
        git checkout --detach "origin/$DOTFILES_BRANCH" 2>/dev/null || true
        git checkout -B "$DOTFILES_BRANCH" "origin/$DOTFILES_BRANCH" 2>/dev/null || true
        ok "Dotfiles atualizados"
    fi
fi

mkdir -p ~/.config

link_dotfile() {
    local source="$1"
    local target="$2"
    
    if [[ -e "$target" && ! -L "$target" ]]; then
        backup_file "$target"
        rm -rf "$target"
    elif [[ -L "$target" ]]; then
        rm "$target"
    fi
    
    ln -sf "$source" "$target"
    ok "Link: $target"
}

info "Criando symlinks das configurações..."

if [[ -d "$DOTFILES_DIR/.config/alacritty" ]]; then
    link_dotfile "$DOTFILES_DIR/.config/alacritty" "$HOME/.config/alacritty"
fi

if [[ -d "$DOTFILES_DIR/.config/nvim" ]]; then
    link_dotfile "$DOTFILES_DIR/.config/nvim" "$HOME/.config/nvim"
fi

if [[ -d "$DOTFILES_DIR/.config/fish" ]]; then
    link_dotfile "$DOTFILES_DIR/.config/fish" "$HOME/.config/fish"
fi

if [[ -f "$DOTFILES_DIR/.config/starship.toml" ]]; then
    link_dotfile "$DOTFILES_DIR/.config/starship.toml" "$HOME/.config/starship.toml"
fi

info "Configurando Fish..."

mkdir -p ~/.config/fish

if [[ ! -f ~/.config/fish/config.fish ]] || ! grep -q "starship init fish" ~/.config/fish/config.fish 2>/dev/null; then
    cat >>~/.config/fish/config.fish <<'EOF'

# Starship prompt
starship init fish | source

# Aliases
alias gs='git status'
alias ga='git add -A'
alias gc='git commit -m'
alias gp='git push'
alias gl='git pull'
alias gco='git checkout'
alias clone='git clone'
alias lz='lazygit'

alias v='nvim'
alias vim='nvim'

alias ..='cd ..'
alias ...='cd ../..'

# eza aliases
alias ls='eza -al --color=always --group-directories-first --icons'
alias la='eza -a --color=always --group-directories-first --icons'
alias ll='eza -l --color=always --group-directories-first --icons'
alias lt='eza -aT --color=always --group-directories-first --icons'

# zoxide (cd inteligente)
zoxide init fish | source

# fnm
set FNM_PATH "$HOME/.local/share/fnm"
if test -d "$FNM_PATH"
  set PATH "$FNM_PATH" $PATH
  fnm env | source
end

# fzf
fzf --fish | source
EOF
    ok "Configuração do Fish atualizada"
fi

info "Instalando plugins do Neovim..."
if has_command nvim; then
    nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
    ok "Plugins do Neovim instalados"
fi

ok "Dotfiles configurados com sucesso!"
info "Reinicie o Fish para aplicar todas as configurações."
