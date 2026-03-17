#!/usr/bin/env bash
# =============================================================================
# lib/utils.sh - Biblioteca de utilitários compartilhada para scripts/wsl
# Suporta tanto Fedora (dnf) quanto Ubuntu/Debian (apt)
# =============================================================================

set -euo pipefail

detect_pkg_manager() {
    if [ -x /usr/bin/dnf ]; then
        echo "dnf"
    elif [ -x /usr/bin/apt ]; then
        echo "apt"
    else
        echo "unknown"
    fi
}

if [ -z "${PKG_MANAGER:-}" ]; then
    PKG_MANAGER="$(detect_pkg_manager)"
fi

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*" >&2; }
log_ok() { echo -e "${GREEN}[OK]${NC} $*" >&2; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

info() { log_info "$@"; }
ok() { log_ok "$@"; }

is_wsl() {
	[[ -f /proc/version ]] && grep -qi microsoft /proc/version
}

has_command() {
	command -v "$1" &>/dev/null
}

has_package() {
    case "$PKG_MANAGER" in
        dnf) rpm -q "$1" &>/dev/null ;;
        apt) dpkg -l "$1" &>/dev/null ;;
        *) return 1 ;;
    esac
}

refresh_pkg_cache() {
    if [[ "${PKG_CACHE_REFRESHED:-0}" -eq 0 ]]; then
        log_info "Atualizando metadados do pacote..."
        case "$PKG_MANAGER" in
            dnf) sudo dnf makecache -y ;;
            apt) sudo apt-get update ;;
        esac
        export PKG_CACHE_REFRESHED=1
    fi
}

ensure_pkg() {
    local pkg="$1"
    if has_package "$pkg"; then
        log_info "Pacote já instalado: $pkg"
        return 0
    fi
    refresh_pkg_cache
    log_info "Instalando: $pkg"
    case "$PKG_MANAGER" in
        dnf) sudo dnf install -y "$pkg" && ok "$pkg instalado" ;;
        apt) sudo apt-get install -y "$pkg" && ok "$pkg instalado" ;;
    esac
}

install_list() {
    local pkgs=("$@")
    local ok=() missing=() failed=()

    refresh_pkg_cache

    for pkg in "${pkgs[@]}"; do
        log_info "Instalando: $pkg"
        local out rc
        (set +e
        case "$PKG_MANAGER" in
            dnf)
                out="$(sudo dnf install -y "$pkg" 2>&1)"
                rc=$?
                ;;
            apt)
                out="$(sudo apt-get install -y "$pkg" 2>&1)"
                rc=$?
                ;;
        esac
        )

        if [[ $rc -eq 0 ]]; then
            ok+=("$pkg")
            ok "$pkg instalado"
        elif grep -qiE "no match for argument|unable to find a match|not found|package.*is not available" <<<"$out"; then
            missing+=("$pkg")
            log_warn "Pacote não encontrado: $pkg"
        else
            failed+=("$pkg")
            log_error "Falha ao instalar: $pkg"
        fi
    done

    echo
    log_info "===== RESUMO ====="
    echo "OK: ${#ok[@]}"
    [[ ${#ok[@]} -gt 0 ]] && printf '   - %s\n' "${ok[@]}"
    echo "Missing: ${#missing[@]}"
    [[ ${#missing[@]} -gt 0 ]] && printf '   - %s\n' "${missing[@]}"
    echo "Failed: ${#failed[@]}"
    [[ ${#failed[@]} -gt 0 ]] && printf '   - %s\n' "${failed[@]}"
    [[ ${#failed[@]} -gt 0 ]] && return 1
    return 0
}

backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup="${file}.backup.$(date +%Y%m%d-%H%M%S)"
        cp "$file" "$backup"
        log_info "Backup criado: $backup"
    fi
}

check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "Não execute como root/sudo"
        exit 1
    fi
}

confirm() {
    local msg="${1:-Continuar?}"
    read -rp "$msg [y/N]: " response
    [[ "$response" =~ ^[Yy]$ ]]
}

link_config() {
    local source="$1"
    local target="$2"

    if [[ -L "$target" ]]; then
        rm "$target"
    elif [[ -e "$target" ]]; then
        backup_file "$target"
        rm -rf "$target"
    fi

    ln -s "$source" "$target"
    ok "Link criado: $target -> $source"
}

export -f log_info log_ok log_warn log_error info ok
export -f is_wsl has_command has_package refresh_pkg_cache ensure_pkg install_list
export -f backup_file check_root confirm link_config
