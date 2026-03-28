#!/bin/bash
# ==============================================================================
# DISTROBOX SETUP - Criar container Arch Linux para pacotes AUR orfaos
# Permite rodar pacotes AUR que nao tem equivalente DNF/COPR/Flatpak.
# ==============================================================================

set -euo pipefail

# --- Cores ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

CONTAINER_NAME="archbox"
CONTAINER_IMAGE="archlinux:latest"

usage() {
    cat << EOF
Uso: $(basename "$0") <comando> [opcoes]

Comandos:
  create              Cria o container Arch Linux (archbox)
  enter               Entra no container archbox
  install <pkg>       Instala um pacote AUR dentro do archbox
  export  <app>       Exporta aplicacao do container para o host
  export-bin <bin>    Exporta binario do container para o host
  list                Lista apps exportados do container
  remove              Remove o container archbox
  status              Mostra status do container

Exemplos:
  $(basename "$0") create
  $(basename "$0") install yay
  $(basename "$0") install aur-only-package
  $(basename "$0") export aur-only-package
  $(basename "$0") export-bin aur-only-binary
EOF
}

check_distrobox() {
    if ! command -v distrobox >/dev/null 2>&1; then
        log_error "Distrobox nao esta instalado."
        log_info "Instale com: sudo dnf install distrobox"
        exit 1
    fi

    if ! command -v podman >/dev/null 2>&1 && ! command -v docker >/dev/null 2>&1; then
        log_error "Nenhum container runtime encontrado (podman ou docker)."
        log_info "Instale com: sudo dnf install podman"
        exit 1
    fi
}

cmd_create() {
    if distrobox list | grep -q "$CONTAINER_NAME"; then
        log_ok "Container '$CONTAINER_NAME' ja existe."
        return 0
    fi

    log_info "Criando container Arch Linux '$CONTAINER_NAME'..."
    if distrobox create --name "$CONTAINER_NAME" --image "$CONTAINER_IMAGE" --yes; then
        log_ok "Container '$CONTAINER_NAME' criado."
        log_info "Inicializando container (primeira execucao)..."
        distrobox enter "$CONTAINER_NAME" -- bash -c "
            sudo pacman -Syu --noconfirm
            sudo pacman -S --noconfirm --needed base-devel git
            # Instala yay como AUR helper
            if ! command -v yay >/dev/null 2>&1; then
                cd /tmp
                git clone --depth=1 https://aur.archlinux.org/yay.git
                cd yay
                makepkg -si --noconfirm
                cd /tmp && rm -rf yay
            fi
            echo 'Container inicializado com sucesso!'
        "
        log_ok "Container '$CONTAINER_NAME' inicializado com yay."
    else
        log_error "Falha ao criar container."
        return 1
    fi
}

cmd_enter() {
    if ! distrobox list | grep -q "$CONTAINER_NAME"; then
        log_error "Container '$CONTAINER_NAME' nao existe. Execute: $(basename "$0") create"
        return 1
    fi

    distrobox enter "$CONTAINER_NAME"
}

cmd_install() {
    local pkg="$1"

    if ! distrobox list | grep -q "$CONTAINER_NAME"; then
        log_error "Container '$CONTAINER_NAME' nao existe. Execute: $(basename "$0") create"
        return 1
    fi

    log_info "Instalando '$pkg' dentro do container..."
    distrobox enter "$CONTAINER_NAME" -- bash -c "yay -S --noconfirm --needed $pkg"
    log_ok "Pacote '$pkg' instalado no container."
}

cmd_export_app() {
    local app="$1"

    if ! distrobox list | grep -q "$CONTAINER_NAME"; then
        log_error "Container '$CONTAINER_NAME' nao existe."
        return 1
    fi

    log_info "Exportando aplicacao '$app' do container para o host..."
    distrobox enter "$CONTAINER_NAME" -- bash -c "distrobox-export --app $app"
    log_ok "Aplicacao '$app' exportada. Deve aparecer no menu do sistema."
}

cmd_export_bin() {
    local bin="$1"

    if ! distrobox list | grep -q "$CONTAINER_NAME"; then
        log_error "Container '$CONTAINER_NAME' nao existe."
        return 1
    fi

    log_info "Exportando binario '$bin' do container para o host..."
    distrobox enter "$CONTAINER_NAME" -- bash -c "distrobox-export --bin /usr/bin/$bin --export-path ~/.local/bin"
    log_ok "Binario '$bin' exportado para ~/.local/bin/"
}

cmd_list() {
    log_info "Apps exportados do distrobox:"
    echo ""
    # Lista .desktop files que foram exportados
    local export_dir="$HOME/.local/share/applications"
    if ls "$export_dir"/*distrobox* 2>/dev/null; then
        log_ok "Apps listados acima."
    else
        log_warn "Nenhum app exportado encontrado."
    fi
}

cmd_remove() {
    if ! distrobox list | grep -q "$CONTAINER_NAME"; then
        log_warn "Container '$CONTAINER_NAME' nao existe."
        return 0
    fi

    log_warn "Removendo container '$CONTAINER_NAME'..."
    distrobox stop "$CONTAINER_NAME" --yes 2>/dev/null || true
    distrobox rm "$CONTAINER_NAME" --yes
    log_ok "Container '$CONTAINER_NAME' removido."
}

cmd_status() {
    log_info "Status dos containers Distrobox:"
    echo ""
    distrobox list
}

# --- Main ---
main() {
    check_distrobox

    if [[ $# -lt 1 ]]; then
        usage
        exit 1
    fi

    local cmd="$1"
    shift

    case "$cmd" in
        create) cmd_create ;;
        enter)  cmd_enter ;;
        install)
            [[ $# -lt 1 ]] && { log_error "Uso: $(basename "$0") install <pacote>"; exit 1; }
            cmd_install "$1"
            ;;
        export)
            [[ $# -lt 1 ]] && { log_error "Uso: $(basename "$0") export <app>"; exit 1; }
            cmd_export_app "$1"
            ;;
        export-bin)
            [[ $# -lt 1 ]] && { log_error "Uso: $(basename "$0") export-bin <binario>"; exit 1; }
            cmd_export_bin "$1"
            ;;
        list)   cmd_list ;;
        remove) cmd_remove ;;
        status) cmd_status ;;
        -h|--help|help) usage ;;
        *)
            log_error "Comando desconhecido: $cmd"
            usage
            exit 1
            ;;
    esac
}

main "$@"
