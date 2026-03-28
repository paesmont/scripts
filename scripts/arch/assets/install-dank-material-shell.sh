#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

main() {
	info "Instalando Dank Material Shell (via script remoto)..."

	if command -v dank >/dev/null 2>&1 || command -v dank-material-shell >/dev/null 2>&1 || [ -d "$HOME/.config/dank-material-shell" ] || [ -d "$HOME/.local/share/dank-material-shell" ]; then
		info "Dank Material Shell já instalado. Pulando."
		return 0
	fi

	if ! command -v curl >/dev/null 2>&1; then
		fail "curl não encontrado; não foi possível instalar Dank Material Shell."
		exit 1
	fi

	if curl -fsSL https://install.danklinux.com | sh; then
		ok "Dank Material Shell instalado com sucesso."
	else
		fail "Falha ao instalar Dank Material Shell."
	fi
}

main "$@"
