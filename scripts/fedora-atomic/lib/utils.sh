#!/usr/bin/env bash
# =============================================================================
# lib/utils.sh - Utilitarios compartilhados para Fedora Atomic / Bazzite
# =============================================================================

set -euo pipefail

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
warn() { log_warn "$@"; }
fail() { log_error "$@"; }

has_command() {
    command -v "$1" >/dev/null 2>&1
}

check_root() {
    if [[ $EUID -eq 0 ]]; then
        fail "Nao execute este script como root"
        exit 1
    fi
}

run_sudo() {
    sudo "$@"
}

append_line_if_missing() {
    local line="$1"
    local file="$2"

    mkdir -p "$(dirname "$file")"
    touch "$file"

    if ! grep -Fqx "$line" "$file" 2>/dev/null; then
        printf '%s\n' "$line" >>"$file"
    fi
}

rpm_ostree_install() {
    local missing=()
    local pkg

    for pkg in "$@"; do
        if rpm -q "$pkg" >/dev/null 2>&1; then
            info "Pacote rpm-ostree ja presente: $pkg"
            continue
        fi
        missing+=("$pkg")
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        ok "Nenhum pacote novo para rpm-ostree"
        return 0
    fi

    info "Instalando no host via rpm-ostree: ${missing[*]}"
    run_sudo rpm-ostree install "${missing[@]}"
    warn "rpm-ostree concluiu. Reinicie o sistema para aplicar as camadas."
}

ensure_flathub() {
    if flatpak remotes --columns=name 2>/dev/null | grep -qx "flathub"; then
        info "Flathub ja configurado"
        return 0
    fi

    info "Adicionando repositorio Flathub"
    run_sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    ok "Flathub configurado"
}

flatpak_install() {
    local app="$1"

    if flatpak info "$app" >/dev/null 2>&1; then
        info "Flatpak ja instalado: $app"
        return 0
    fi

    info "Instalando Flatpak: $app"
    flatpak install -y flathub "$app"
    ok "Flatpak instalado: $app"
}

ensure_homebrew() {
    if has_command brew; then
        info "Homebrew ja instalado"
        return 0
    fi

    info "Instalando Homebrew"
    NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi

    append_line_if_missing 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' "$HOME/.bashrc"
    append_line_if_missing 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' "$HOME/.profile"
    append_line_if_missing '/home/linuxbrew/.linuxbrew/bin/brew shellenv | source' "$HOME/.config/fish/config.fish"

    ok "Homebrew instalado"
}

load_homebrew_env() {
    if has_command brew; then
        return 0
    fi

    if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi

    has_command brew
}

brew_install() {
    local formula="$1"

    if brew list --formula "$formula" >/dev/null 2>&1; then
        info "Formula Homebrew ja instalada: $formula"
        return 0
    fi

    info "Instalando Homebrew formula: $formula"
    brew install "$formula"
    ok "Formula instalada: $formula"
}

brew_tap() {
    local tap="$1"

    if brew tap | grep -qx "$tap"; then
        info "Tap Homebrew ja configurado: $tap"
        return 0
    fi

    info "Adicionando tap Homebrew: $tap"
    brew tap "$tap"
    ok "Tap configurado: $tap"
}

ensure_distrobox_container() {
    local name="$1"
    local image="$2"

    if distrobox list --no-color 2>/dev/null | awk '{print $1}' | grep -qx "$name"; then
        info "Container Distrobox ja existe: $name"
        return 0
    fi

    info "Criando container Distrobox: $name ($image)"
    distrobox create --name "$name" --image "$image" --yes
    ok "Container criado: $name"
}

exec_distrobox() {
    local name="$1"
    shift
    distrobox enter "$name" -- bash -lc "$*"
}

export -f info ok warn fail
export -f has_command check_root run_sudo append_line_if_missing
export -f rpm_ostree_install ensure_flathub flatpak_install
export -f ensure_homebrew load_homebrew_env brew_install brew_tap
export -f ensure_distrobox_container exec_distrobox
