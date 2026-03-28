#!/bin/bash
set -euo pipefail

REPO_URL="git@gitlab.com:bashln/dotfiles.git"
REPO_NAME="dotfiles"

log() { printf '[*] %s\n' "$*"; }
ok() { printf '[+] %s\n' "$*"; }
warn() { printf '[!] %s\n' "$*"; }
die() {
  printf '[X] %s\n' "$*" >&2
  exit 1
}

# --- dependências ---
command -v stow >/dev/null 2>&1 || die "stow não está instalado"
command -v git >/dev/null 2>&1 || die "git não está instalado"

cd "$HOME"

# --- clone do repo ---
if [[ -d "$REPO_NAME" ]]; then
  log "Repo '$REPO_NAME' já existe, usando o local"
else
  log "Clonando dotfiles..."
  git clone --depth=1 "$REPO_URL"
fi

cd "$REPO_NAME"

# --- limpeza mínima (apenas o que costuma conflitar) ---
# log "Removendo configs antigas conhecidas..."
# rm -rf \
#   "$HOME/.config/nvim" \
#   "$HOME/.local/share/nvim" \
#   "$HOME/.cache/nvim" \
#   "$HOME/.config/starship.toml" \
#   "$HOME/.config/ghostty/config"

# --- aplicar dotfiles ---
log "Aplicando dotfiles com stow..."
stow .

ok "Dotfiles aplicados com sucesso."
