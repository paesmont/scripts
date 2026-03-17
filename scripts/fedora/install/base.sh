#!/usr/bin/env bash
# =============================================================================
# install/base.sh - Pacotes essenciais e atualização do sistema
# =============================================================================

set -euo pipefail

source "$(dirname "$0")/../lib/utils.sh"

check_root

info "Atualizando sistema..."

case "$PKG_MANAGER" in
    dnf)
        sudo dnf upgrade --refresh -y
        install_list \
            curl \
            wget \
            git \
            gcc \
            gcc-c++ \
            make \
            unzip \
            ca-certificates \
            gnupg2 \
            dnf-plugins-core \
            util-linux-user \
            procps-ng
        ;;
    apt)
        install_list \
            curl \
            wget \
            git \
            build-essential \
            unzip \
            software-properties-common \
            apt-transport-https \
            ca-certificates \
            gnupg \
            lsb-release
        ;;
esac

ok "Base instalada com sucesso!"
