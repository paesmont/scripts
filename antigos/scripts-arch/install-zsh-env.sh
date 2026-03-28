#!/bin/bash
set -euo pipefail

log()  { printf '[*] %s\n' "$*"; }
ok()   { printf '[+] %s\n' "$*"; }
warn() { printf '[!] %s\n' "$*"; }

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    warn "Comando recomendado não encontrado: $1"
  fi
}

main() {
  log "Configurando Oh-My-Zsh e plugins..."

  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    require_cmd curl
    log "Instalando Oh-My-Zsh (modo unattended)..."
    if ! sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
      warn "Falha ao instalar Oh-My-Zsh (verifique conexão)."
    fi
  else
    ok "Oh-My-Zsh já instalado; pulando."
  fi

  local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  mkdir -p "$zsh_custom/plugins" "$zsh_custom/themes"

  git clone --depth=1 https://github.com/unixorn/fzf-zsh-plugin \
    "$zsh_custom/plugins/fzf-zsh-plugin" \
    || warn "fzf-zsh-plugin já existe ou falha no clone."

  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
    "$zsh_custom/plugins/zsh-autosuggestions" \
    || warn "zsh-autosuggestions já existe ou falha no clone."

  git clone --depth=1 https://github.com/zsh-users/zsh-completions \
    "$zsh_custom/plugins/zsh-completions" \
    || warn "zsh-completions já existe ou falha no clone."

  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git \
    "$zsh_custom/plugins/zsh-syntax-highlighting" \
    || warn "zsh-syntax-highlighting já existe ou falha no clone."

  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "$zsh_custom/themes/powerlevel10k" \
    || warn "powerlevel10k já existe ou falha no clone."

  if [[ ! -d "$HOME/.fzf" ]]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf" || warn "Falha ao clonar fzf."
    "$HOME/.fzf/install" --all || warn "Falha ao rodar instalador do fzf."
  else
    ok "fzf já está instalado em ~/.fzf; pulando."
  fi

  ok "Zsh/Oh-My-Zsh + plugins configurados (ajuste ~/.zshrc conforme seu gosto)."
}

main "$@"

