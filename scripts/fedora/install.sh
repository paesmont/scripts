#!/usr/bin/env bash
# =============================================================================
# install.sh - Orquestrador para Fedora (metal/WSL)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "${ID:-unknown}"
    else
        echo "unknown"
    fi
}

validate_steps() {
    for step in "${STEPS[@]}"; do
        if [ ! -f "$SCRIPT_DIR/assets/$step" ]; then
            echo "Error: Missing step file: $step"
            exit 1
        fi
    done
}

run_steps() {
    local distro="$1"
    export distro
    for step in "${STEPS[@]}"; do
        echo "Running $step..."
        source "$SCRIPT_DIR/assets/$step"
    done
}

main() {
    local distro
    distro=$(detect_distro)
    distro="${distro:-unknown}"
    
    echo "Detected distro: $distro"
    
    STEPS=(
      base.sh
      shell.sh
      # shell-default-fish.sh
      cli-tools.sh
      dev-tools.sh
      terminal.sh
      dotfiles.sh
    )
    
    validate_steps "$distro"
    run_steps "$distro"
    
    echo "Fedora setup complete!"
}

main "$@"
