#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

main() {
    info "Instalando toolchain básica (equivalente ao base-devel no Arch)"

    # Fedora: preferimos o grupo "Development Tools" quando possível.
    ensure_dnf_group "Development Tools"

    # Em rpm-ostree não há groupinstall; garantimos um conjunto mínimo.
    ensure_packages gcc gcc-c++ make pkgconf-pkg-config glibc-devel
}

main "$@"
