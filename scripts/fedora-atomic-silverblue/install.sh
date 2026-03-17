#!/bin/bash
# Fedora Atomic variant installer

set -euo pipefail

# Source the library
source "$(dirname "$0")/lib/utils.sh"

# Get variant from directory name (remove fedora-atomic- prefix)
dir=$(basename "$(dirname "$0")")
case "$dir" in
  fedora-atomic-*) variant="${dir#fedora-atomic-}" ;;
  *) variant="$dir" ;;
esac

# Welcome message
info "Instalando para Fedora Atomic $variant"

# Execute base installation steps
# TODO: Add specific steps for each variant when needed

ok "Instalacao concluida para Fedora Atomic $variant"
