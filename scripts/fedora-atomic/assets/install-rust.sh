#!/usr/bin/env bash
# =============================================================================
# install-rust.sh - Rust toolchain via rustup
# =============================================================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/utils.sh"

check_root

info "Instalando Rust toolchain"

if has_command rustup; then
	info "Rust ja instalado"
	rustup update
else
	info "Instalando rustup..."
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable

	append_line_if_missing 'export PATH="$HOME/.cargo/bin:$PATH"' "$HOME/.bashrc"
	append_line_if_missing 'export PATH="$HOME/.cargo/bin:$PATH"' "$HOME/.profile"

	if has_command fish; then
		mkdir -p ~/.config/fish/functions
		echo 'set -gx PATH $HOME/.cargo/bin $PATH' >>~/.config/fish/config.fish
	fi
fi

if has_command cargo; then
	source "$HOME/.cargo/env" 2>/dev/null || true

	info "Instalando ferramentas globais via Cargo..."

	if has_command just; then
		info "just ja instalado"
	else
		cargo install just --quiet
	fi

	cargo install bat --quiet 2>/dev/null || info "bat skipado (pode falhar em sandbox)"
	cargo install eza --quiet 2>/dev/null || info "eza skipado"
	cargo install zellij --quiet 2>/dev/null || info "zellij skipado"
fi

ok "Rust toolchain pronta"
