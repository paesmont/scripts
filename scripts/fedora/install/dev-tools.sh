#!/usr/bin/env bash
# =============================================================================
# install/dev-tools.sh - Git, GitHub CLI, fnm, Python, pipx, Neovim
# =============================================================================

set -euo pipefail

source "$(dirname "$0")/../lib/utils.sh"

check_root

info "Instalando ferramentas de desenvolvimento..."

info "Git..."
ensure_pkg git

info "GitHub CLI..."
if ! has_command gh; then
    ensure_pkg gh
    ok "GitHub CLI instalado"
fi

info "fnm (Node.js version manager)..."
if ! has_command fnm; then
    curl -fsSL https://fnm.vercel.app/install | bash
    
    mkdir -p ~/.config/fish/conf.d
    cat >~/.config/fish/conf.d/fnm.fish <<'EOF'
# fnm
set FNM_PATH "$HOME/.local/share/fnm"
if test -d "$FNM_PATH"
  set PATH "$FNM_PATH" $PATH
  fnm env | source
end
EOF
    
    ok "fnm instalado"
fi

info "Python..."
ensure_pkg python3
ensure_pkg python3-pip

info "pipx..."
if ! has_command pipx; then
    ensure_pkg pipx
    pipx ensurepath
    ok "pipx instalado"
fi

info "Neovim..."
if ! has_command nvim; then
    case "$PKG_MANAGER" in
        dnf) sudo dnf install -y neovim 2>/dev/null && ok "Neovim instalado via dnf" ;;
        apt) sudo apt-get install -y neovim 2>/dev/null && ok "Neovim instalado via apt" ;;
    esac
    
    if ! has_command nvim; then
        info "Tentando AppImage..."
        if wget -q "https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.appimage" -O /tmp/nvim.appimage; then
            if chmod +x /tmp/nvim.appimage; then
                if cd /tmp; then
                    if ./nvim.appimage --appimage-extract >/dev/null 2>&1; then
                        if sudo rm -rf /opt/nvim && sudo mv squashfs-root /opt/nvim; then
                            if sudo ln -sf /opt/nvim/usr/bin/nvim /usr/local/bin/nvim; then
                                cd - >/dev/null || true
                                ok "Neovim instalado via AppImage"
                            fi
                        fi
                    fi
                fi
            fi
        fi
    fi
else
    info "Neovim já instalado"
fi

mkdir -p ~/.config/nvim

info "Instalando Node.js LTS..."
if has_command fnm; then
    export PATH="$HOME/.local/share/fnm:$PATH"
    eval "$(fnm env)"
    fnm install --lts
    fnm use lts-latest
    ok "Node.js LTS instalado"
fi

ok "Ferramentas de desenvolvimento instaladas!"
