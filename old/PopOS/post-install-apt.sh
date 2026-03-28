#!/usr/bin/env bash
# =============================================================================
# post-install-apt.sh
# Pop!_OS / Ubuntu post-install using APT — install each package individually.
# Preserva o fluxo mesmo quando um pacote não existe ou falha.
# =============================================================================
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# --- Logging ---
LOG_FILE="${LOG_FILE:-$HOME/post-install-apt.log}"
: > "$LOG_FILE"
log() { printf "%s %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG_FILE"; }

# --- Helpers to install packages one-by-one ---
ok=(); missing=(); failed=()

_install_pkg() {
  local pkg="$1"
  log "→ Instalando: $pkg"
  set +e
  local out
  out="$(sudo -E apt-get -o Dpkg::Use-Pty=0 install -y "$pkg" 2>&1)"
  local rc=$?
  set -e
  printf "%s\n" "$out" >> "$LOG_FILE"

  if [[ $rc -eq 0 ]]; then
    ok+=("$pkg"); log "✅ Sucesso: $pkg"; return 0
  fi

  if grep -qiE "(unable to locate package|package .* not found|no packages found|Não foi possível localizar o pacote|pacote .* não|inexistente)" <<< "$out"; then
    missing+=("$pkg"); log "⚠️  Inexistente no APT: $pkg"
  else
    failed+=("$pkg"); log "❌ Falhou: $pkg (rc=$rc)"
  fi
}

install_list() {
  local pkgs=("$@")
  for p in "${pkgs[@]}"; do _install_pkg "$p"; done
}

summary() {
  echo; log "===== RESUMO ====="
  printf "   ✅ Instalados: %s\n" "${#ok[@]}"; ((${#ok[@]})) && printf '      - %s\n' "${ok[@]}"
  printf "   ⚠️  Inexistentes: %s\n" "${#missing[@]}"; ((${#missing[@]})) && printf '      - %s\n' "${missing[@]}"
  printf "   ❌ Falhas: %s\n" "${#failed[@]}"; ((${#failed[@]})) && printf '      - %s\n' "${failed[@]}"
}

# --- Start ---
echo -e "\n#-------------------- INICIANDO CONFIGURAÇÃO INICIAL (APT) --------------------#\n"
sleep 1

echo -e "\n[+] Ajustando APT para scripts...\n"
sudo tee /etc/apt/apt.conf.d/99custom-noninteractive >/dev/null <<'EOF'
APT::Get::Assume-Yes "true";
APT::Color "0";
Dpkg::Use-Pty "0";
Acquire::Retries "3";
# Paralelismo é automático em versões novas; não forçamos aqui.
EOF

echo -e "\n[+] Habilitando repositórios adicionais (universe/multiverse) ...\n"
set +e
sudo add-apt-repository -y universe    >/dev/null 2>&1
sudo add-apt-repository -y multiverse  >/dev/null 2>&1
set -e

echo -e "\n[+] Atualizando sistema pela primeira vez...\n"
sudo apt-get update -y
sudo apt-get upgrade -y

# ---------------- Pacotes essenciais (um por um) ----------------
echo -e "\n[+] Instalando pacotes essenciais (um por um)...\n"
install_list \
  curl unzip git jq build-essential \
  ntfs-3g gedit \
  fonts-firacode fonts-jetbrains-mono fonts-ubuntu \
  alacritty vlc steam \
  gvfs dosbox samba flameshot zoxide fzf kitty \
  neovim nodejs python3 python3-pip

# ---------------- Wine / Gaming (Ubuntu/Pop) ----------------
echo -e "\n[+] Habilitando arquitetura i386 para Wine/games...\n"
sudo dpkg --add-architecture i386 || true
sudo apt-get update -y

echo -e "\n[+] Instalando bibliotecas para Wine/Gaming...\n"
install_list \
  wine winetricks \
  vulkan-tools mesa-vulkan-drivers \
  libgl1-mesa-dri:i386 libglu1-mesa:i386 \
  libasound2-plugins:i386 libpulse0:i386 \
  libxcomposite1:i386 libxinerama1:i386 \
  libgnutls30:i386 libgstreamer1.0-0:i386 gstreamer1.0-plugins-base:i386 \
  libsdl2-2.0-0:i386

# ---------------- Neovide via Rust (opcional) ----------------
echo -e "\n[+] Instalando Rust (rustup) e Neovide (opcional)...\n"
if ! command -v cargo >/dev/null 2>&1; then
  curl --proto '=https' --tlsv1.2 -sSf "https://sh.rustup.rs" | sh -s -- -y
  # shellcheck disable=SC1090
  source "$HOME/.cargo/env"
fi
# Dependências de compilação
install_list fontconfig libfontconfig1-dev libfreetype6-dev \
  libexpat1-dev libxcb1-dev libx11-xcb-dev libxcb-render0-dev \
  libxcb-shape0-dev libxcb-xfixes0-dev pkg-config libssl-dev \
  libgtk-3-dev
# Neovide (se cargo disponível)
if command -v cargo >/dev/null 2>&1; then
  set +e; cargo install --git https://github.com/neovide/neovide 2>&1 | tee -a "$LOG_FILE"; set -e
else
  log "⚠️  Cargo não encontrado após rustup; pulando Neovide."
fi

# ---------------- Flatpak / Flathub ----------------
echo -e "\n[+] Instalando Flatpak e configurando Flathub...\n"
install_list flatpak
set +e
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
set -e

# Exemplos (opcional); com --noninteractive exige confirmação em alguns casos, então usamos flatpak padrão
set +e
flatpak -y install flathub net.davidotek.pupgui2
flatpak -y install flathub com.spotify.Client
flatpak -y install flathub com.mattjakeman.ExtensionManager
set -e

# ---------------- Oh-My-Zsh e plugins ----------------
echo -e "\n[+] Configurando Oh-My-Zsh e plugins...\n"
install_list zsh git
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  log "Instalando Oh-My-Zsh..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
# Plugins
set +e
git clone --depth=1 https://github.com/unixorn/fzf-zsh-plugin ~/.oh-my-zsh/custom/plugins/fzf-zsh-plugin 2>>"$LOG_FILE"
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions 2>>"$LOG_FILE"
git clone --depth=1 https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-completions 2>>"$LOG_FILE"
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting 2>>"$LOG_FILE"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" 2>>"$LOG_FILE"
set -e

# ---------------- Visual Studio Code (repo oficial Microsoft) ----------------
echo -e "\n[+] Instalando Visual Studio Code (repo Microsoft)...\n"
install_list wget gpg apt-transport-https ca-certificates software-properties-common
# Chave e repo
sudo install -d -m 0755 /etc/apt/keyrings
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /etc/apt/keyrings/packages.microsoft.gpg
sudo chmod go+r /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | \
  sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
sudo apt-get update -y
_install_pkg code

# ---------------- Git config ----------------
echo -e "\n[+] Configurando Git...\n"
if ! git config --global user.email >/dev/null 2>&1; then
  git config --global user.email "you@example.com"
fi
if ! git config --global user.name >/dev/null 2>&1; then
  git config --global user.name "Your Name"
fi

# ---------------- qtile-extras via pip (opcional) ----------------
echo -e "\n[+] (Opcional) Instalando qtile-extras via pip...\n"
_install_pkg python3-pip
set +e
pip install --user qtile-extras 2>&1 | tee -a "$LOG_FILE"
set -e

# ---------------- Summary ----------------
summary
echo -e "\n✅ Configuração inicial (APT) concluída!\n"
