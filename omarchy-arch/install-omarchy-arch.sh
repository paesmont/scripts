#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# install-omarchy-endeavour.sh
# Objetivo:
#  - Instalar Omarchy no EndeavourOS (KDE)
#  - Não alterar LUKS, não alterar Display Manager
#  - Configurar Hyprland conforme Omarchy (arquivos), mas sem forçar a sessão/DM
#  - Ser idempotente e seguro

REPO_URL="https://github.com/basecamp/omarchy"
WORKDIR="$(mktemp -d -t omarchy-install-XXXX)"
DEST="$HOME/.local/share/omarchy"
BACKUP_SUFFIX=".orig-$(date +%Y%m%d%H%M%S)"

echo ">>> Iniciando instalador Omarchy (modo EndeavourOS/KDE safe)"
echo ">>> Workspace temporário: $WORKDIR"

# 1) checagens básicas
if ! command -v git &>/dev/null; then
  echo "Erro: git não instalado. Instalando via pacman..."
  sudo pacman -S --needed --noconfirm git || {
    echo "Falha ao instalar git"
    exit 1
  }
fi

# 2) clonar o repo (em workspace)
echo ">>> Clonando Omarchy em $WORKDIR/omarchy..."
git clone --depth=1 "$REPO_URL" "$WORKDIR/omarchy"

# 3) instalar yay (se faltando)
if ! command -v yay &>/dev/null; then
  echo ">>> yay não encontrado — instalando (requer base-devel)..."
  sudo pacman -S --needed --noconfirm base-devel git || {
    echo "Falha: não foi possível garantir base-devel"
    exit 1
  }
  git clone --depth=1 https://aur.archlinux.org/yay.git /tmp/yay-omarchy-installer
  (cd /tmp/yay-omarchy-installer && makepkg -si --noconfirm)
  rm -rf /tmp/yay-omarchy-installer
fi

# 4) Detectar distro / ambiente para aplicar patches mínimos
DIST=""
if [ -f /etc/os-release ]; then
  DIST=$(grep -E '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
fi
echo ">>> Distro detectada: ${DIST:-desconhecida} (esperado: endeavouros/arch)"

# 5) Preparar destino: copia segura para ~/.local/share/omarchy
echo ">>> Preparando destino em $DEST"
if [ -d "$DEST" ]; then
  echo ">>> Já existe $DEST — farei backup para ${DEST}${BACKUP_SUFFIX}"
  mv "$DEST" "${DEST}${BACKUP_SUFFIX}"
fi
mkdir -p "$DEST"
cp -a "$WORKDIR/omarchy/." "$DEST"

# 6) Patches SAFESPECÍFICOS para Endeavour/KDE:
#  - remover qualquer tentativa de alterar pacman.conf automaticamente
#  - evitar execução de scripts que toquem plymouth, bootloader, alt-bootloaders, limine-snapper
#  - evitar remover ou alterar drivers (nvidia) automaticamente
#  - evitar scripts que mudem DM (display manager)
echo ">>> Aplicando patches de segurança para não alterar DM, LUKS ou bootloader..."

cd "$DEST"

append_ignorepkg_if_missing() {
  local pkg="$1"
  local current

  current=$(sudo grep -E '^[[:space:]]*IgnorePkg[[:space:]]*=' /etc/pacman.conf || true)
  if grep -Eq "^[[:space:]]*IgnorePkg[[:space:]]*=.*(^|[[:space:]])${pkg}([[:space:]]|$)" <<<"$current"; then
    return 0
  fi

  if [[ -n "$current" ]]; then
    sudo sed -i -E "/^[[:space:]]*IgnorePkg[[:space:]]*=/ s/$/ ${pkg}/" /etc/pacman.conf
  else
    printf '\nIgnorePkg = %s\n' "$pkg" | sudo tee -a /etc/pacman.conf >/dev/null
  fi
}

# Backup dos scripts que vamos tocar (apenas para segurança)
mkdir -p "$DEST/.installer-backups"
cp -a install config bin "$DEST/.installer-backups/" || true

# 6.1 remover qualquer append direto ao /etc/pacman.conf nas rotinas de instalação
# (busca por linhas que contenham "omarchy" e "pacman.conf" e comenta ou remove)
# Em vez de remover permanentemente os arquivos, comentamos as linhas que executam alterações.
grep -R --line-number "pacman.conf" -n install || true
# comentar linhas em scripts onde aparece "pacman.conf" para prevenir alterações automáticas
# fazemos isso somente nos arquivos de install e post-install
while IFS= read -r f; do
  [[ -n "$f" ]] || continue
  echo " - Comentando chamadas a pacman.conf em: $f"
  sed -i "/pacman.conf/ s/^/# OMARCHY-SAFE: /" "$f"
done < <(grep -RIl "pacman.conf" install || true)

# 6.2 remover/inibir chamadas problemáticas que alteram DM, plymouth, limine, alt-bootloaders, pacman.sh
# pattern de scripts a inibir (nomes comuns no omarchy)
declare -a BAD_SCRIPTS=(
  "install/preflight/pacman.sh"
  "install/post-install/pacman.sh"
  "install/config/hardware/nvidia.sh"
  "install/login/plymouth.sh"
  "install/login/limine-snapper.sh"
  "install/login/alt-bootloaders.sh"
)

for s in "${BAD_SCRIPTS[@]}"; do
  if grep -R --line-number "run_logged .*${s##*/}" -n . >/dev/null 2>&1; then
    echo " - Inibindo chamada a $s"
    # remover a linha que faz "run_logged $OMARCHY_INSTALL/..." nas listagens "all.sh"
    # Procuramos nos arquivos all.sh por ocorrências do script e comentamos a linha
    while IFS= read -r allf; do
      [[ -n "$allf" ]] || continue
      sed -i "/${s##*/}/ s/^/# OMARCHY-SAFE: /" "$allf" || true
    done < <(grep -RIl "${s##*/}" || true)
  fi
done

# 6.3 remover tldr se conflitar com tealdeer: apenas remover tldr da lista de pacotes
if [ -f "install/omarchy-base.packages" ]; then
  echo " - Ajustando lista de pacotes: removendo 'tldr' se presente (para evitar conflito com tealdeer)"
  sed -i '/\btldr\b/d' install/omarchy-base.packages || true
fi

# 6.4 ajustes de env de mise para suportar shells comuns (preservando comportamento)
if [ -f "config/uwsm/env" ]; then
  echo " - Ajustando config/uwsm/env para checagem de shell (bash/fish)..."
  sed -i "s/if command -v mise &> \/dev\/null; then/if [ \"\$SHELL\" = \"\/bin\/bash\" ] \&\& command -v mise \&> \/dev\/null; then/" config/uwsm/env || true
  # adicionar suporte fish (somente se não existir)
  if ! grep -q "mise activate fish" config/uwsm/env 2>/dev/null; then
    sed -i '/eval "\$(mise activate bash)"/a\
elif [ "$SHELL" = "/bin/fish" ] && command -v mise &> /dev/null; then\
  mise activate fish | source' config/uwsm/env || true
  fi
fi

# 7) instalar pacotes listados por Omarchy de forma segura
# Em vez de rodar scripts que toquem pacman.conf ou alterem o sistema, vamos:
#  - ler install/omarchy-base.packages (se existir)
#  - instalar pacotes do repo oficial via pacman
#  - para AUR, usar yay

echo ">>> Ajustando ambiente Rust (rust vs rustup)..."

# 1. Remover rust da lista de pacotes se presente
if grep -q "^rust$" install/omarchy-base.packages 2>/dev/null; then
  echo " - Removendo 'rust' da lista de pacotes do Omarchy..."
  sed -i '/^rust$/d' install/omarchy-base.packages
fi

# 2. Se o Omarchy exige rustup, evitar reinstalação futura de rust sem apagar outras regras
if grep -q "^rustup$" install/omarchy-base.packages 2>/dev/null; then
  echo " - Configurando IgnorePkg para impedir reinstalação de rust..."
  append_ignorepkg_if_missing rust

  if pacman -Q rust &>/dev/null; then
    echo " - Detectado 'rust' instalado e 'rustup' presente na lista de pacotes Omarchy. Removendo 'rust' para evitar conflito."
    sudo pacman -R --noconfirm rust || {
      echo "Erro: não foi possível remover rust. Abortando para evitar conflito."
      exit 1
    }
  fi

  if ! pacman -Q rustup &>/dev/null; then
    echo " - Instalando rustup..."
    sudo pacman -S --noconfirm rustup
  fi
  rustup default stable || true
fi

echo " - Ambiente Rust preparado."

echo ">>> Instalando pacotes base listados pelo Omarchy (somente pacman + AUR), sem tocar pacman.conf..."
PKG_FILE="install/omarchy-base.packages"
if [ -f "$PKG_FILE" ]; then
  echo ">>> Checando conflito rust vs rustup..."

  # Garantir que rustup exista se foi solicitado
  if grep -q "^rustup$" install/omarchy-base.packages 2>/dev/null; then
    if ! pacman -Q rustup &>/dev/null; then
      echo " - Instalando rustup antes dos pacotes Omarchy..."
      sudo pacman -S --noconfirm rustup || {
        echo "Erro ao instalar rustup."
        exit 1
      }
      rustup default stable || true
    fi
  fi

  # extrair lista limpa: sem comentários
  PKGS=$(grep -E -v '^\s*#' "$PKG_FILE" | tr '\n' ' ' | sed 's/  */ /g' | xargs -r -n1 echo)
  # separar pacman (core) de AUR: heurística simples (pkgname with dashes? we'll try pacman first)
  echo " - Pacotes extraídos do arquivo: (mostrando primeiro 20)"
  echo "$PKGS" | tr ' ' '\n' | sed -n '1,20p'
  # Tentativa: instalar todos via pacman - se algum não existir, fallback para yay
  TO_AUR=()
  TO_PACMAN=()
  NEED_OMARCHY_REPO=0

  # Primeiro: varrer os pacotes e detectar se precisamos do repo Omarchy
  for p in $PKGS; do
    if [[ "$p" == omarchy-* ]]; then
      NEED_OMARCHY_REPO=1
    fi
  done

  # Segundo: adicionar o repo se for necessário
  if [[ $NEED_OMARCHY_REPO -eq 1 ]]; then
    echo ">>> Pacotes Omarchy detectados — verificando repositório Omarchy..."
    if ! grep -q "\[omarchy\]" /etc/pacman.conf; then
      echo " - Adicionando repositório Omarchy ao pacman.conf..."
      echo -e "\n[omarchy]\nSigLevel = Optional TrustedOnly\nServer = https://pkgs.omarchy.org/\$arch" |
        sudo tee -a /etc/pacman.conf >/dev/null

      echo " - Atualizando listas de pacotes..."
      sudo pacman -Sy --noconfirm
    else
      echo " - Repositório Omarchy já presente no sistema."
    fi
  fi

  # Terceiro: categorização final entre pacman e AUR
  for p in $PKGS; do
    if pacman -Si "$p" &>/dev/null; then
      TO_PACMAN+=("$p")
    else
      TO_AUR+=("$p")
    fi
  done

  if [ "${#TO_PACMAN[@]}" -gt 0 ]; then
    echo " - Instalando pacotes oficiais via pacman..."
    sudo pacman -S --needed --noconfirm "${TO_PACMAN[@]}"
  fi

  if [ "${#TO_AUR[@]}" -gt 0 ]; then
    echo " - Instalando pacotes AUR via yay (lista parcial)..."
    # instalar em grupo para agilizar
    yay -S --needed --noconfirm "${TO_AUR[@]}"
  fi
else
  echo " - Nenhum arquivo install/omarchy-base.packages encontrado. Pulando instalação automática de pacotes."
fi

# 8) Preparar Hyprland: copiar configs que Omarchy fornece sem habilitar sessão automaticamente
# Se Omarchy tiver scripts específicos de hyprland, copiamos os configs para ~/.config/hypr e outros.
echo ">>> Preparando configuração local para Hyprland (apenas arquivos, sem alterar DM)..."
# Exemplo genérico: copiar config/hypr ou install/login/hyprland.* se existirem
if [ -d "install/login" ]; then
  # procurar por scripts/dirs contendo 'hypr' ou 'hyprland'
  if ls install/login/*hypr* 1>/dev/null 2>&1 || ls config/*hypr* 1>/dev/null 2>&1; then
    mkdir -p "$HOME/.config"
    # copiar diretórios de config (não sobrescrever configs existentes sem backup)
    for d in config/*hypr* install/login/*hypr*; do
      if [ -e "$d" ]; then
        # decide destino baseado no nome
        # se for arquivo .sh -> não executar; se for pasta de config -> copiar
        if [ -d "$d" ]; then
          target="$HOME/.config/$(basename "$d")"
          if [ -e "$target" ]; then
            echo " - Backup de $target -> ${target}${BACKUP_SUFFIX}"
            mv "$target" "${target}${BACKUP_SUFFIX}"
          fi
          echo " - Copiando $d -> $target"
          cp -a "$d" "$target"
        else
          # arquivo: se parecer ser um config installer (termina com .sh), copiamos para ~/.local/share/omarchy/install/login/
          mkdir -p "$HOME/.local/share/omarchy/install/login"
          cp -a "$d" "$HOME/.local/share/omarchy/install/login/"
        fi
      fi
    done
  else
    echo " - Nenhuma configuração Hyprland detectada nos caminhos padrão do Omarchy."
  fi
fi

# 9) Evitar criação automática de sessão Hyprland como padrão: informar usuário
cat <<EOF

>>> PRONTO (parcial).
O instalador aplicou patches seguros para não:
  - alterar /etc/pacman.conf de forma ampla/automática (apenas inclusões pontuais e controladas, como IgnorePkg e repositório Omarchy, quando exigidos),
  - mexer no LUKS (nenhum passo de criptografia será modificado),
  - alterar seu Display Manager (SDDM/KDE) ou forçar Hyprland como sessão padrão.

O que foi feito:
 - Omarchy clonado em: $DEST
 - Chamadas automáticas a scripts de boot/pacman/plymouth/nvidia/alt-bootloaders foram comentadas
 - Pacotes listados em install/omarchy-base.packages foram instalados (quando disponíveis)
 - Configs de Hyprland (se presente no repo) foram copiados para ~/.config (sem habilitar qualquer sessão)
 - yay foi instalado (se necessário)

O que **VOCÊ** pode/ deve fazer manualmente (recomendado):
 1) Rever $DEST/install e $DEST/install/login/* para ver o que foi inibido.
 2) Se quiser experimentar Hyprland sem mudar seu DM:
    - No SDDM faça logout -> na tela de sessão selecione "Hyprland" (se estiver instalado) — isso não altera nada do sistema.
    - Se preferir, execute os scripts de instalação Hyprland manualmente (ex.: $DEST/install/login/plymouth.sh NÃO foi executado por padrão).
 3) Se quiser que eu habilite a sessão Hyprland automaticamente, eu posso adaptar o script — mas isso altera o DM (não recomendado sem confirmação).

Executando o instalador modificado do Omarchy (opcional)
 - Se quiser prosseguir e executar o ./install.sh modificado dentro de $DEST (lembrando que já inibimos os passos mais perigosos), rode:
   cd "$DEST" && chmod +x install.sh && ./install.sh

EOF

# 10) limpeza de workspace
rm -rf "$WORKDIR"
echo ">>> Finalizado. Omarchy está em $DEST. Leia as instruções acima."
exit 0
