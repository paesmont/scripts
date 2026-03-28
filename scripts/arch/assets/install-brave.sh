#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

main() {
	info "Instalando Brave Browser (via script remoto)..."

	if command -v brave-browser >/dev/null 2>&1 || { command -v pacman >/dev/null 2>&1 && (pacman -Qi brave-bin >/dev/null 2>&1 || pacman -Qi brave-browser >/dev/null 2>&1); }; then
		info "Brave Browser já instalado. Pulando."
		return 0
	fi

	if ! command -v curl >/dev/null 2>&1; then
		fail "curl não encontrado; não foi possível instalar Brave Browser."
		exit 1
	fi

	if sudo curl -fsS https://dl.brave.com/install.sh | sh; then
		ok "Brave Browser instalado com sucesso."
	else
		fail "Falha ao instalar Brave Browser."
	fi
}

main "$@"
