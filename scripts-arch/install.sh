#!/bin/bash
set -u

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# FIX 1: Aspas corrigidas
export LOG_FILE="$BASE_DIR/install.log"

# FIX 2: Aspas corrigidas
source "$BASE_DIR/lib/utils.sh"

SUCCESS_STEPS=()
FAILED_STEPS=()

info "Iniciando instalação. Log completo em: $LOG_FILE"

# Mantém o sudo vivo em background para quando precisarmos
sudo -v
while true; do
  sudo -n true
  sleep 60
  kill -0 "$$" || exit
done 2>/dev/null &

run_step() {
  local script="$1"
  local path="$BASE_DIR/assets/$script"

  if [[ ! -x "$path" ]]; then
    warn "Script ignorado (não executável): $script"
    return
  fi

  # --- INTEGRAÇÃO DA INTELIGÊNCIA ---
  # Detecta se o script pede root explicitamente
  local requires_root=0
  if grep -q "^REQUIRES_ROOT=1" "$path"; then
    requires_root=1
  fi

  info ">>> Executando módulo: $script"

  local exit_code=0
  local spinner_title="Executando módulo: $script"

  if [[ $requires_root -eq 1 ]]; then
    # Se requer root, usamos sudo E passamos a variável LOG_FILE adiante
    # (Sem isso, o script filho não consegue escrever no log)
    if [[ ${GUM_AVAILABLE:-0} -eq 1 ]]; then
      if gum spin --spinner dot --title "$spinner_title" -- sudo LOG_FILE="$LOG_FILE" "$path"; then
        exit_code=0
      else
        exit_code=1
      fi
    elif sudo LOG_FILE="$LOG_FILE" "$path"; then
      exit_code=0
    else
      exit_code=1
    fi
  else
    # Se não requer root (ex: dotfiles, stow), roda como seu usuário normal
    if [[ ${GUM_AVAILABLE:-0} -eq 1 ]]; then
      if gum spin --spinner dot --title "$spinner_title" -- "$path"; then
        exit_code=0
      else
        exit_code=1
      fi
    elif "$path"; then
      exit_code=0
    else
      exit_code=1
    fi
  fi

  if [[ $exit_code -eq 0 ]]; then
    ok "Módulo $script finalizado com sucesso."
    SUCCESS_STEPS+=("$script")
  else
    fail "Módulo $script FALHOU."
    FAILED_STEPS+=("$script")
  fi
}

STEPS=(
  # ----------------------------------------
  # 1. System Base & Core Utilities
  # ----------------------------------------
  "install-gum.sh"
  "install-base-devel.sh"
  "install-dev-tools.sh"
  "install-git.sh"
  "install-stow.sh"
  # "install-yay.sh" # AUR helper (needed early for AUR packages)
  "install-curl.sh"
  "install-unzip.sh"
  "install-jq.sh"
  "install-eza.sh"
  "install-zoxide.sh"
  # "install-linux-toys.sh"

  # ----------------------------------------
  # 2. Languages & Runtimes
  # ----------------------------------------
  "install-go-tools.sh" # Go itself is installed via ensure_package in this script
  # "install-python.sh"
  # "install-python-tools.sh"
  # "install-ruby.sh" # Depends on asdf and base-devel, so asdf should be installed
  # "install-rust.sh"

  # ----------------------------------------
  # 3. Graphics, Multimedia & Drivers
  # ----------------------------------------
  "install-fonts.sh"
  "install-mesa-radeon.sh"
  "install-vulkan-stack.sh"
  "install-lib32-libs.sh"
  "install-libva-utils.sh"
  "install-gvfs.sh"

  # ----------------------------------------
  # 4. Terminal Emulators & Shells
  # ----------------------------------------
  "install-alacritty.sh"
  "install-kitty.sh"
  "install-ghostty.sh"
  # "install-tmux.sh"
  # "install-zsh-env.sh"
  # "install-ohmybash-starship.sh"
  "install-dank-material-shell.sh" # Shell customization
  # "set-shell.sh"                   # Change default shell (should be after shell installs)

  # ----------------------------------------
  # 5. Networking & Storage
  # ----------------------------------------
  "install-ntfs-3g.sh"
  "install-samba.sh"
  "autofs.sh"
  "install-wl-clipboard.sh"
  "fix-services.sh"

  # ----------------------------------------
  # 6. Browsers
  # ----------------------------------------
  # "install-vivaldi.sh"
  "install-brave.sh"

  # ----------------------------------------
  # 7. Development Tools
  # ----------------------------------------
  "install-asdf.sh" # Version manager for languages
  "install-cmake.sh"
  "install-nodejs.sh"
  "install-npm-global.sh"
  "install-lsps.sh"
  # "install-vscode.sh"
  "install-lazygit.sh"
  "install-emacs.sh"
  "install-neovim.sh"
  "configure-git.sh" # Configuration, depends on git

  # ----------------------------------------
  # 8. Applications
  # ----------------------------------------
  "install-remmina.sh"
  "install-vlc.sh"
  "install-yazi-deps.sh" # Yazi dependencies first
  "install-yazi.sh"      # Then Yazi itself
  "install-steam.sh"
  "install-wine-stack.sh"
  "install-postgresql.sh"

  # ----------------------------------------
  # 9. Flatpak Applications (Requires Flatpak setup first)
  # ----------------------------------------
  "install-flatpak-flathub.sh"
  "install-flatpak-pupgui2.sh"
  "install-flatpak-spotify.sh"

  # ----------------------------------------
  # 10. Desktop Environment Overrides (Hyprland specific)
  # ----------------------------------------
  "install-hyprland-overrides.sh" # Specific DE config, usually last
  "install-hyprland-autostart.sh"
)

for step in "${STEPS[@]}"; do
  run_step "$step"
done

# --- RELATÓRIO ---
echo ""
echo "=========================================="
echo "          RESUMO DA OPERAÇÃO              "
echo "=========================================="
echo "Log file: $LOG_FILE"
echo ""

if [ ${#SUCCESS_STEPS[@]} -gt 0 ]; then
  printf "${GREEN}Sucessos (${#SUCCESS_STEPS[@]}):${RESET}\n"
  printf "  - %s\n" "${SUCCESS_STEPS[@]}"
fi

echo ""

if [ ${#FAILED_STEPS[@]} -gt 0 ]; then
  printf "${RED}FALHAS (${#FAILED_STEPS[@]}):${RESET}\n"
  printf "  - %s\n" "${FAILED_STEPS[@]}"
  echo ""
  warn "Verifique o arquivo $LOG_FILE."
  exit 1
else
  ok "Instalação completa sem erros!"
  exit 0
fi
