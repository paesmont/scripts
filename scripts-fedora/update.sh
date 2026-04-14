#!/bin/bash
# ==============================================================================
# SYSADMIN UPDATE SCRIPT - FEDORA WAY
# Foco: Estabilidade, Rollback seguro e Detecção automática (dnf vs rpm-ostree).
# ==============================================================================

set -euo pipefail

# --- Configurações ---
LOG_FILE="/var/log/sys_update.log"

# --- Helpers de Log (Estilo SysAdmin) ---
log() {
    local msg="[$(date +'%H:%M:%S')] [*] $1"
    echo "$msg"
    # Opcional: descomente para salvar em arquivo (requer permissão de escrita)
    # echo "$msg" >> "$LOG_FILE"
}

ok() {
    echo -e "\033[32m[+] $1\033[0m"
}

warn() {
    echo -e "\033[33m[!] ALERTA: $1\033[0m"
}

die() {
    echo -e "\033[31m[X] ERRO CRÍTICO: $1\033[0m" >&2
    exit 1
}

# --- Verificação de Privilégios ---
if [[ $EUID -eq 0 ]]; then
    SUDO=""
else
    SUDO="sudo"
    if ! command -v sudo >/dev/null 2>&1; then
        die "Este script requer root ou sudo."
    fi
fi

# --- Funções Core ---

check_internet() {
    log "Verificando conectividade..."
    if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        die "Sem conexão com a internet. Abortando."
    fi
}


system_update() {
    if [[ -f /run/ostree-booted ]] && command -v rpm-ostree >/dev/null 2>&1; then
        log "Iniciando atualização do sistema (rpm-ostree)..."
        if ! $SUDO rpm-ostree upgrade; then
            die "Falha crítica na atualização do rpm-ostree."
        fi
        ok "Deployment atualizado (reboot necessário)."
        return
    fi

    log "Iniciando atualização do sistema (dnf)..."
    if ! $SUDO dnf upgrade -y --refresh; then
        die "Falha crítica na atualização do dnf."
    fi
    ok "Pacotes oficiais atualizados."
}

cleanup_smart() {
    log "Iniciando limpeza inteligente..."

    if [[ -f /run/ostree-booted ]] && command -v rpm-ostree >/dev/null 2>&1; then
        log "Limpando deployments antigos (rpm-ostree cleanup)..."
        $SUDO rpm-ostree cleanup -m || warn "Falha no cleanup de metadata (rpm-ostree)."
        $SUDO rpm-ostree cleanup -p || warn "Falha no cleanup de pacotes (rpm-ostree)."
    else
        log "Removendo pacotes órfãos (dnf autoremove)..."
        $SUDO dnf autoremove -y || warn "Falha ao remover pacotes órfãos."

        log "Limpando cache do dnf..."
        $SUDO dnf clean all || warn "Falha ao limpar cache do dnf."
    fi

    # Journal (Logs do Systemd)
    log "Vacuuming logs do systemd (>50M)..."
    $SUDO journalctl --vacuum-size=50M >/dev/null 2>&1
}

check_rpmnew() {
    log "Verificando arquivos .rpmnew/.rpmsave (Configurações pendentes)..."
    local rpms
    rpms=$(find /etc -name "*.rpmnew" -o -name "*.rpmsave" 2>/dev/null)

    if [[ -n "$rpms" ]]; then
        warn "ATENÇÃO: Arquivos .rpmnew/.rpmsave detectados. Mescle manualmente:"
        echo "$rpms"
    else
        ok "Nenhum arquivo .rpmnew/.rpmsave encontrado. Configurações limpas."
    fi
}

# --- Main Execution ---

main() {
    clear
    echo "====================================================="
    echo "   UNIVERSAL LINUX MAINTENANCE - $(hostname)"
    echo "====================================================="

    check_internet
    system_update

    if command -v flatpak >/dev/null 2>&1; then
        log "Atualizando Flatpaks..."
        flatpak update -y
    fi

    cleanup_smart
    check_rpmnew

    echo "====================================================="
    ok "Manutenção concluída. Reinicie se houve atualização de Kernel."
    echo "====================================================="
}

main "$@"
