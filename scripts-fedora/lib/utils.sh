#!/bin/bash
# lib/utils.sh

# Definição de Arquivo de Log Global
LOG_FILE="${LOG_FILE:-/tmp/install-dnf-$(date +%Y%m%d-%H%M%S).log}"

# Cores
BLUE='\e[34m'
GREEN='\e[32m'
YELLOW='\e[33m'
RED='\e[31m'
RESET='\e[0m'

# Função de Log Interna (Escreve no arquivo e na tela)
_log() {
    local level="$1"
    local color="$2"
    local msg="$3"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    # Escrita no Arquivo (Sem cores, com timestamp)
    echo "[$timestamp] [$level] $msg" >> "$LOG_FILE"

    # Escrita na Tela (Com cores)
    printf "${color}[%s] %s${RESET}\n" "$level" "$msg" >&2
}

info() { _log "INFO" "$BLUE" "$*"; }
ok()   { _log "OK"   "$GREEN" "$*"; }
warn() { _log "WARN" "$YELLOW" "$*"; }
fail() { _log "FAIL" "$RED" "$*"; }
die() {
    fail "$*"
    exit 1
}

# --- Funções de Verificação/Instalação de Pacotes (Fedora) ---
detect_package_manager() {
    if [[ -f /run/ostree-booted ]] && command -v rpm-ostree >/dev/null 2>&1; then
        echo "rpm-ostree"
        return 0
    fi

    if command -v dnf >/dev/null 2>&1; then
        echo "dnf"
        return 0
    fi

    return 1
}

PACKAGE_MANAGER="${PACKAGE_MANAGER:-$(detect_package_manager || true)}"

ensure_package() {
    local pkg="$1"

    if [[ -z "$PACKAGE_MANAGER" ]]; then
        fail "Nenhum gerenciador de pacotes suportado detectado (dnf/rpm-ostree)."
        return 1
    fi

    if rpm -q "$pkg" &>/dev/null; then
        info "Pacote '$pkg' já instalado. Pulando."
        return 0
    fi

    info "Instalando pacote: $pkg..."
    case "$PACKAGE_MANAGER" in
        dnf)
            if sudo dnf install -y "$pkg" >> "$LOG_FILE" 2>&1; then
                ok "Pacote '$pkg' instalado."
            else
                fail "Erro ao instalar '$pkg' via dnf. Verifique o log: $LOG_FILE"
                return 1
            fi
            ;;
        rpm-ostree)
            # Fedora Silverblue: instalação em camadas (requer reboot para aplicar).
            if sudo rpm-ostree install "$pkg" >> "$LOG_FILE" 2>&1; then
                ok "Pacote '$pkg' adicionado na camada rpm-ostree (reboot necessário)."
            else
                fail "Erro ao instalar '$pkg' via rpm-ostree. Verifique o log: $LOG_FILE"
                return 1
            fi
            ;;
        *)
            fail "Gerenciador de pacotes desconhecido: $PACKAGE_MANAGER"
            return 1
            ;;
    esac
}

ensure_packages() {
    local pkg
    for pkg in "$@"; do
        ensure_package "$pkg"
    done
}

ensure_dnf_group() {
    local group="$1"

    if [[ "$PACKAGE_MANAGER" != "dnf" ]]; then
        warn "Grupo '$group' só é suportado via dnf. Pulando em rpm-ostree."
        return 0
    fi

    info "Instalando grupo dnf: $group..."
    if sudo dnf groupinstall -y "$group" >> "$LOG_FILE" 2>&1; then
        ok "Grupo '$group' instalado."
    else
        fail "Erro ao instalar grupo '$group' via dnf. Verifique o log: $LOG_FILE"
        return 1
    fi
}

ensure_flatpak_package() {
    local pkg="$1"
    
    if flatpak info "$pkg" &>/dev/null; then
        info "Pacote Flatpak '$pkg' já instalado. Pulando."
        return 0
    fi

    info "Instalando pacote Flatpak: $pkg..."
    if flatpak install -y flathub "$pkg" >> "$LOG_FILE" 2>&1; then
        ok "Pacote Flatpak '$pkg' instalado."
    else
        fail "Erro ao instalar o pacote Flatpak '$pkg'. Verifique o log: $LOG_FILE"
        return 1
    fi
}
