#!/usr/bin/env bash
# =============================================================================
# host-base.sh - Camada minima de host para Fedora Atomic / Bazzite
# =============================================================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/utils.sh"

check_root

info "Preparando camada minima do host para ${ATOMIC_VARIANT:-atomic}"

# No Atomic, so vale a pena layerar o que integra com o sistema host.
# Apps graficos vao para Flatpak; CLIs de usuario vao para Homebrew; stacks
# de desenvolvimento mutaveis vao para Distrobox.
rpm_ostree_install \
    distrobox \
    podman \
    wl-clipboard \
    flatpak

ok "Camada base do host concluida"
