#!/usr/bin/env bash
# =============================================================================
# distrobox.sh - Ambiente mutavel de desenvolvimento para Atomic / Bazzite
# =============================================================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/utils.sh"

check_root

if ! has_command distrobox; then
    fail "distrobox nao encontrado. Rode host-base.sh e reinicie se necessario."
    exit 1
fi

if ! has_command podman && ! has_command docker; then
    fail "Nenhum runtime de container encontrado"
    exit 1
fi

CONTAINER_NAME="${ATOMIC_DEVBOX_NAME:-devbox}"
CONTAINER_IMAGE="${ATOMIC_DEVBOX_IMAGE:-ghcr.io/ublue-os/toolboxes:fedora}"

info "Configurando Distrobox para desenvolvimento"

ensure_distrobox_container "$CONTAINER_NAME" "$CONTAINER_IMAGE"

exec_distrobox "$CONTAINER_NAME" "
    sudo dnf upgrade -y &&
    sudo dnf install -y \
        gcc gcc-c++ make cmake \
        python3 python3-pip python3-devel pipx python3-lsp-server python3-black \
        ShellCheck shfmt \
        golang \
        rust cargo rust-analyzer \
        ruby ruby-devel \
        postgresql postgresql-server postgresql-contrib \
        ImageMagick ffmpegthumbnailer poppler-utils p7zip
"

exec_distrobox "$CONTAINER_NAME" "
    pipx ensurepath >/dev/null 2>&1 || true
"

exec_distrobox "$CONTAINER_NAME" "
    command -v psql >/dev/null 2>&1 && distrobox-export --bin \$(command -v psql) --export-path \$HOME/.local/bin || true
    command -v black >/dev/null 2>&1 && distrobox-export --bin \$(command -v black) --export-path \$HOME/.local/bin || true
    command -v pylsp >/dev/null 2>&1 && distrobox-export --bin \$(command -v pylsp) --export-path \$HOME/.local/bin || true
"

ok "Distrobox de desenvolvimento concluido"
