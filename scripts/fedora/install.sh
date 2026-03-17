#!/usr/bin/env bash
# =============================================================================
# install.sh - Orquestrador para WSL (Fedora/Ubuntu)
# Detecta automaticamente a distro e aplica a configuração apropriada
# =============================================================================

set -euo pipefail

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "${ID:-unknown}"
    else
        echo "unknown"
    fi
}

validate_steps() {
    local distro="$1"
    for step in "${STEPS[@]}"; do
        if [ "$step" = "# bootstrap.sh" ]; then
            continue
        fi
        if [ ! -f "$step" ]; then
            echo "Error: Missing step file: $step"
            exit 1
        fi
    done
}

run_steps() {
    local distro="$1"
    export distro
    for step in "${STEPS[@]}"; do
        if [ "$step" = "# bootstrap.sh" ]; then
            continue
        fi
        echo "Running $step..."
        source "$step"
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
      cli-tools.sh
      dev-tools.sh
      terminal.sh
      dotfiles.sh
      # bootstrap.sh  # instala distro no WSL (rodar no Windows antes)
    )
    
    validate_steps "$distro"
    run_steps "$distro"
    
    echo "WSL setup complete!"
}

main "$@"
