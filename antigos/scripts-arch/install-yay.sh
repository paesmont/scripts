#!/bin/bash
set -euo pipefail

log()  { printf '[*] %s\n' "$*"; }
ok()   { printf '[+] %s\n' "$*"; }
warn() { printf '[!] %s\n' "$*"; }

main() {
  log "Verificando AUR helper (yay)..."

  if ! command -v yay >/dev/null 2>&1; then
    warn "yay não encontrado. Instalação automática pode exigir intervenção manual."
    echo "Sugestão:"
    echo "  git clone --depth=1 https://aur.archlinux.org/yay.git"
    echo "  cd yay && makepkg -si --noconfirm"
    echo "  cd .. && rm -rf yay"
    return
  else
    ok "yay encontrado."
  fi

}

main "$@"

