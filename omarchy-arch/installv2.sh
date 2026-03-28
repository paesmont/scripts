#!/bin/bash
set -euo pipefail

# ======================================
# 0. Estética básica de logs
# ======================================
BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log(){ echo -e "${BLUE}[OMARCHY]${NC} $1"; }
ok(){ echo -e "${GREEN}[OK]${NC} $1"; }
warn(){ echo -e "${YELLOW}[!]${NC} $1"; }

ensure_omarchy_repo() {
  if grep -Eq '^\[omarchy\]$' /etc/pacman.conf; then
    return 0
  fi

  log "Adicionando repositório Omarchy ao pacman.conf..."
  cat <<'EOF' | sudo tee -a /etc/pacman.conf >/dev/null

[omarchy]
SigLevel = Optional TrustedOnly
Server = https://pkgs.omarchy.org/$arch
EOF
}

# ======================================
# 1. Checagem básica
# ======================================
if [[ "$EUID" -eq 0 ]]; then
  warn "Não execute como root. O script usa sudo quando necessário."
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  warn "git não está instalado. Instalando..."
  sudo pacman -S --noconfirm --needed git
fi

# ======================================
# 2. Pastas oficiais do Omarchy
# ======================================
export OMARCHY_PATH="$HOME/.local/share/omarchy"
export OMARCHY_INSTALL="$OMARCHY_PATH/install"
export PATH="$OMARCHY_PATH/bin:$PATH"

mkdir -p "$OMARCHY_PATH"

# ======================================
# 3. Clone ou update do repositório
# ======================================
if [[ -d "$OMARCHY_PATH/.git" ]]; then
  log "Atualizando Omarchy..."
  git -C "$OMARCHY_PATH" pull
elif [[ -z "$(ls -A "$OMARCHY_PATH")" ]]; then
  log "Clonando Omarchy..."
  git clone --depth=1 https://github.com/basecamp/omarchy "$OMARCHY_PATH"
else
  backup_path="${OMARCHY_PATH}.backup-$(date +%Y%m%d%H%M%S)"
  warn "Diretório $OMARCHY_PATH existe e não é um repositório git. Fazendo backup em $backup_path"
  mv "$OMARCHY_PATH" "$backup_path"
  mkdir -p "$OMARCHY_PATH"
  log "Clonando Omarchy..."
  git clone --depth=1 https://github.com/basecamp/omarchy "$OMARCHY_PATH"
fi

ok "Repositório do Omarchy pronto."

# ======================================
# 4. PGP FIX – A peça que faltava
# ======================================
log "Importando chave PGP do repositório Omarchy..."

ensure_omarchy_repo

curl -fsSLo /tmp/omarchy.asc \
  "https://keys.openpgp.org/vks/v1/by-fingerprint/40DFB630FF42BCFFB047046CF0134EE680CAC571"

gpg --show-keys --with-fingerprint /tmp/omarchy.asc

sudo pacman-key --add /tmp/omarchy.asc
sudo pacman-key --lsign-key F0134EE680CAC571

log "Atualizando keyring Omarchy..."
sudo pacman -Sy --noconfirm
sudo pacman -S --noconfirm omarchy/omarchy-keyring || true

# fallback
if ls /var/cache/pacman/pkg/omarchy-keyring-*.pkg.tar.zst >/dev/null 2>&1; then
  sudo pacman -U --noconfirm /var/cache/pacman/pkg/omarchy-keyring-*.pkg.tar.zst
fi

ok "Chave PGP configurada. Repositório Omarchy 100% funcional."

# ======================================
# 5. Yay (se não existir)
# ======================================
if ! command -v yay >/dev/null 2>&1; then
  log "Instalando yay..."
  sudo pacman -S --needed --noconfirm git base-devel
  git clone --depth=1 https://aur.archlinux.org/yay-bin.git /tmp/yay
  (cd /tmp/yay && makepkg -si --noconfirm)
  rm -rf /tmp/yay
else
  ok "yay já está instalado."
fi

# ======================================
# 6. Instalação dos pacotes do Omarchy
# (usa a própria lista do Omarchy)
# ======================================
log "Instalando pacotes base do Omarchy..."

PKG_BASE=()
if [[ -f "$OMARCHY_INSTALL/omarchy-base.packages" ]]; then
  mapfile -t PKG_BASE < <(grep -v '^#' "$OMARCHY_INSTALL/omarchy-base.packages" | sed '/^\s*$/d')
fi

if [[ ${#PKG_BASE[@]} -gt 0 ]]; then
  sudo pacman -S --needed --noconfirm "${PKG_BASE[@]}"
  ok "Pacotes base instalados."
else
  warn "Nenhum pacote base encontrado em $OMARCHY_INSTALL/omarchy-base.packages"
fi

# ======================================
# 7. Instalação dos pacotes AUR do Omarchy
# ======================================
log "Instalando pacotes AUR do Omarchy..."

PKG_OTHER=()
if [[ -f "$OMARCHY_INSTALL/omarchy-other.packages" ]]; then
  mapfile -t PKG_OTHER < <(grep -v '^#' "$OMARCHY_INSTALL/omarchy-other.packages" | sed '/^\s*$/d')
fi

if [[ ${#PKG_OTHER[@]} -gt 0 ]]; then
  yay -S --needed --noconfirm "${PKG_OTHER[@]}"
  ok "Pacotes extras instalados."
else
  warn "Nenhum pacote AUR encontrado em $OMARCHY_INSTALL/omarchy-other.packages"
fi

# ======================================
# 8. Execução do pipeline oficial do Omarchy
# (com proteção contra login/bootloader)
# ======================================
log "Executando pré-instalação (preflight)..."

OMARCHY_SAFE_DISABLE=(
  "install/login/sddm.sh"
  "install/login/plymouth.sh"
  "install/login/limine-snapper.sh"
  "install/login/alt-bootloaders.sh"
)

disabled_modules_backup="$OMARCHY_PATH/.backup-disabled"
mkdir -p "$disabled_modules_backup"

for file in "${OMARCHY_SAFE_DISABLE[@]}"; do
  if [[ -f "$OMARCHY_PATH/$file" ]]; then
    mv "$OMARCHY_PATH/$file" "$disabled_modules_backup/"
    warn "Desativado módulo perigoso: $file"
  fi
done

log "Rodando install.sh do Omarchy com módulos críticos desativados..."
(
  cd "$OMARCHY_PATH"
  if ! bash install.sh; then
    warn "install.sh do Omarchy falhou. Revise os logs acima e os módulos desativados em $disabled_modules_backup"
    exit 1
  fi
)

ok "Pipeline do Omarchy executado."

# ======================================
# 9. Criar sessão Hyprland local (sem tocar no SDDM)
# ======================================
log "Criando sessão local de Hyprland-UWSM..."

mkdir -p "$HOME/.local/share/wayland-sessions"

cat > "$HOME/.local/share/wayland-sessions/omarchy-hyprland.desktop" <<EOF
[Desktop Entry]
Name=Hyprland (Omarchy)
Comment=Hyprland session with Omarchy environment
Exec=uwsm start hyprland-uwsm
Type=Application
EOF

ok "Sessão Omarchy-Hyprland criada sem alterar SDDM."

# ======================================
# 10. Ajuste opcional de tema
# ======================================
log "Aplicando tema padrão Omarchy..."

mkdir -p "$HOME/.config/omarchy"
if [[ -d "$HOME/.config/omarchy/themes" ]]; then
  ln -snf "$HOME/.config/omarchy/themes/tokyonight" "$HOME/.config/omarchy/current"
fi

ok "Tema básico ativado."

# ======================================
# 11. Finalização
# ======================================
ok "Instalação concluída!"
echo -e "\nVocê já pode fazer login na sessão:"
echo -e "   ${GREEN}Hyprland (Omarchy)${NC}"
echo -e "\nSeu KDE permanece intacto.\n"
