#!/usr/bin/env bash
# =============================================================================
# install.sh - Orquestrador Fedora Atomic / Bazzite
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

detect_variant() {
	if [[ -n "${ATOMIC_VARIANT:-}" ]]; then
		echo "$ATOMIC_VARIANT"
		return 0
	fi

	if [[ -f /etc/os-release ]]; then
		. /etc/os-release
		echo "${VARIANT_ID:-atomic}"
		return 0
	fi

	echo "atomic"
}

validate_steps() {
	local step
	for step in "${STEPS[@]}"; do
		if [[ ! -f "$SCRIPT_DIR/assets/$step" ]]; then
			echo "Error: Missing step file: $step" >&2
			exit 1
		fi
	done
}

run_steps() {
	local step
	for step in "${STEPS[@]}"; do
		echo "Running $step..."
		source "$SCRIPT_DIR/assets/$step"
	done
}

main() {
	export ATOMIC_VARIANT
	ATOMIC_VARIANT="$(detect_variant)"

	echo "Detected Fedora Atomic variant: $ATOMIC_VARIANT"

	STEPS=(
		host-base.sh
		flatpaks.sh
		homebrew.sh
		distrobox.sh
		dotfiles.sh
		install-rust.sh
		install-fonts.sh
		install-devtools.sh
		install-gaming.sh
	)

	validate_steps
	run_steps

	echo "Fedora Atomic setup complete!"
}

main "$@"
