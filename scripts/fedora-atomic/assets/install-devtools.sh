#!/usr/bin/env bash
# =============================================================================
# install-devtools.sh - Bun, pnpm, lazydocker e outros dev tools
# =============================================================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/utils.sh"

check_root

info "Instalando dev tools"

ensure_homebrew
load_homebrew_env

brew_install "pnpm"
brew_install "lazydocker"
brew_install "gh"
brew_install "fd"
brew_install "rg" 2>/dev/null || brew_install "ripgrep"
brew_install "fzf"
brew_install "delta"
brew_install "ghq"

if has_command bun; then
	info "Bun ja instalado"
else
	info "Instalando Bun..."
	curl -fsSL https://bun.sh/install | bash
	append_line_if_missing 'export BUN_INSTALL="$HOME/.bun"' "$HOME/.bashrc"
	append_line_if_missing 'export PATH="$BUN_INSTALL/bin:$PATH"' "$HOME/.bashrc"
fi

ok "Dev tools instaladas"
