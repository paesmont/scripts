#!/usr/bin/env bash
# Wrapper para usar a implementacao real em scripts/fedora-atomic

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="$(cd "$SCRIPT_DIR/../fedora-atomic" && pwd)"

export ATOMIC_VARIANT="bazzite"

exec "$COMMON_DIR/install.sh" "$@"
