#!/usr/bin/env bash
# =============================================================================
# Autor: leonamsh (Leonam Monteiro)
# Script: pos-instala-popos.sh
# Descrição: Pós-instalação para Pop!_OS 22.04 (Ubuntu-based), tolerante a falhas.
#            Cada instalação é tentada individualmente; erros são logados e o script continua.
# =============================================================================

set -uo pipefail
export DEBIAN_FRONTEND=noninteractive

# --- Helpers -----------------------------------------------------------------
log()  { printf "\n[INFO] %s\n" "$*"; }
ok()   { printf "[ OK ] %s\n" "$*"; }
warn() { printf "[WARN] %s\n" "$*" >&2; }
err()  { printf "[FAIL] %s\n" "$*" >&2; }

apt_update_safe() {
  log "Atualizando índices do APT..."
  if ! sudo apt-get update -y; then
    warn "Falha ao atualizar índices. Tentando prosseguir mesmo assim."
  else
    ok "APT update concluído."
  fi
}

apt_fix_broken() {
  # Tenta resolver pacotes quebrados, se houver
  if ! sudo apt-get -f install -y; then
    warn "Não foi possível corrigir pacotes quebrados automaticamente."
  fi
}

apt_install_one() {
  local pkg="$1"
  if dpkg -s "$pkg" >/dev/null 2>&1; then
    ok "Pacote já instalado: $pkg"
    return 0
  fi
  if sudo apt-get install -y "$pkg"; then
    ok "Instalado: $pkg"
  else
    warn "Falhou: $pkg (ignorando e seguindo)"
    apt_fix_broken
  fi
}

flatpak_install_one() {
  local app="$1"
  if flatpak info "$app" >/dev/null 2>&1; then
    ok "Flatpak já instalado: $app"
    return 0
  fi
  if flatpak install -y flathub "$app"; then
    ok "Flatpak instalado: $app"
  else
    warn "Falhou Flatpak: $app (ignorando e seguindo)"
  fi
}

service_restart_if_exists() {
  local svc="$1"
  if systemctl list-unit-files | grep -q "^${svc}"; then
    if sudo systemctl restart "$svc"; then
      ok "Reiniciado: $svc"
    else
      warn "Falhou ao reiniciar $svc (ignorando)"
    fi
  else
    warn "Serviço não encontrado: $svc (ignorando)"
  fi
}

# --- Início ------------------------------------------------------------------
echo -e "\n#-------------------- INICIANDO PÓS-INSTALAÇÃO (Pop!_OS 22.04) --------------------#\n"
sleep 1

log "Habilitando repositórios Universe/Multiverse (idempotente)..."
sudo add-apt-repository -y universe   || warn "Universe já pode estar ativo."
sudo add-apt-repository -y multiverse || warn "Multiverse já pode estar ativo."

apt_update_safe

log "Pacotes essenciais via APT (tentativa individual; ignora falhas)..."
ESSENCIAIS=( \
  curl unzip git jq build-essential ntfs-3g gedit emacs \
  fonts-firacode fonts-jetbrains-mono fonts-ubuntu \
  alacritty vlc pcmanfm thunar feh numlockx \
  gvfs dosbox samba xfce4-power-manager lxappearance flameshot \
  zsh zoxide nodejs npm python3 python3-pip rofi suckless-tools \
  flatpak gnome-software-plugin-flatpak \
)

for pkg in "${ESSENCIAIS[@]}"; do
  apt_install_one "$pkg"
done

# (Opcional) Tentativas de componentes de jogos/Wine — se falhar, segue em frente
log "Componentes opcionais (Wine/Vulkan) — serão ignorados se não disponíveis..."
OPCIONAIS=( \
  wine winetricks libvulkan1 libvulkan1:i386 mesa-vulkan-drivers mesa-vulkan-drivers:i386 \
  libvkd3d1 libvkd3d1:i386 libva-utils \
)
# Habilitar arquitetura i386 (idempotente) para casos em que os pacotes existam
if sudo dpkg --add-architecture i386 2>/dev/null; then
  ok "Arquitetura i386 habilitada."
else
  warn "Não foi possível habilitar i386 (talvez já esteja habilitada)."
fi
apt_update_safe
for pkg in "${OPCIONAIS[@]}"; do
  apt_install_one "$pkg"
done

# --- Flatpak/Flathub ---------------------------------------------------------
log "Configurando Flathub (idempotente)..."
if ! flatpak remote-list | grep -qi flathub; then
  if flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; then
    ok "Flathub adicionado."
  else
    warn "Falhou ao adicionar Flathub (talvez já exista)."
  fi
else
  ok "Flathub já está configurado."
fi

log "Instalando aplicativos Flatpak (ignora falhas isoladas)..."
FLATPAKS=( \
  net.davidotek.pupgui2 \
  com.spotify.Client \
  com.mattjakeman.ExtensionManager \
  com.visualstudio.code \
  com.valvesoftware.Steam \
  net.lutris.Lutris \
  com.github.benjamimgois.goverlay \
)
for app in "${FLATPAKS[@]}"; do
  flatpak_install_one "$app"
done

# --- Oh-My-Zsh & plugins -----------------------------------------------------
log "Configurando Oh-My-Zsh (idempotente)..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
    ok "Oh-My-Zsh instalado."
  else
    warn "Falha ao instalar Oh-My-Zsh (ignorando)."
  fi
else
  ok "Oh-My-Zsh já instalado."
fi

log "Clonando plugins do Zsh (ignorando se já existirem)..."
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
mkdir -p "$ZSH_CUSTOM_DIR/plugins" "$ZSH_CUSTOM_DIR/themes"

git clone --depth=1 https://github.com/unixorn/fzf-zsh-plugin               "$ZSH_CUSTOM_DIR/plugins/fzf-zsh-plugin"               2>/dev/null || warn "fzf-zsh-plugin já existe ou falhou (ignorando)"
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions        "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions"          2>/dev/null || warn "zsh-autosuggestions já existe ou falhou (ignorando)"
git clone --depth=1 https://github.com/zsh-users/zsh-completions            "$ZSH_CUSTOM_DIR/plugins/zsh-completions"              2>/dev/null || warn "zsh-completions já existe ou falhou (ignorando)"
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting    "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting"      2>/dev/null || warn "zsh-syntax-highlighting já existe ou falhou (ignorando)"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git  "$ZSH_CUSTOM_DIR/themes/powerlevel10k"                 2>/dev/null || warn "powerlevel10k já existe ou falhou (ignorando)"

# --- Git config --------------------------------------------------------------
log "Configurando Git (interativo, pode pular com Enter)..."
read -rep "Digite seu email para o Git: " git_email || true
read -rep "Digite seu nome  para o Git: " git_name  || true
if [ -n "${git_email:-}" ]; then git config --global user.email "${git_email}"; ok "git.email configurado"; fi
if [ -n "${git_name:-}"  ]; then git config --global user.name  "${git_name}";  ok "git.name configurado"; fi

# --- Serviços opcionais ------------------------------------------------------
log "Reiniciando systemd-binfmt se existir..."
service_restart_if_exists "systemd-binfmt.service"

echo -e "\n✅ Pós-instalação concluída (com tolerância a falhas)."
echo "   Revise os avisos [WARN] acima para itens que possam requerer atenção manual.\n"

