#!/usr/bin/env bash
# =============================================================================
# install-fonts.sh - Nerd Fonts e fontes dev
# =============================================================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/utils.sh"

check_root

info "Instalando fontes"

local_fonts_dir="$HOME/.local/share/fonts"
mkdir -p "$local_fonts_dir"

NERD_FONTS=(
	"JetBrainsMono"
	"FiraCode"
	"Hack"
	"SourceCodePro"
	"NerdFontsSymbolsOnly"
)

install_nerd_font() {
	local font_name="$1"
	local font_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font_name}.zip"

	if fc-list | grep -qi "$font_name"; then
		info "Fonte ja instalada: $font_name"
		return 0
	fi

	info "Baixando $font_name..."
	local tmp_dir
	tmp_dir=$(mktemp -d)
	curl -fsSL "$font_url" -o "$tmp_dir/font.zip"
	unzip -q "$tmp_dir/font.zip" -d "$local_fonts_dir"
	rm -rf "$tmp_dir"

	info "Instalada: $font_name"
}

for font in "${NERD_FONTS[@]}"; do
	install_nerd_font "$font" || warn "Falha ao instalar $font"
done

fc-cache -f >/dev/null 2>&1

ok "Fontes instaladas em $local_fonts_dir"
