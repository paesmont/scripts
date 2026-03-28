#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

main() {
	info "Configurando Oh-My-Zsh e plugins..."

	if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
		info "Instalando Oh-My-Zsh (modo unattended)..."
		if ! sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
			fail "Falha ao instalar Oh-My-Zsh (verifique conexão)."
		fi
	else
		ok "Oh-My-Zsh já instalado; pulando."
	fi

	local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
	local plugin_dir
	local plugin_name

	mkdir -p "$zsh_custom/plugins" "$zsh_custom/themes"

	plugin_name="fzf-zsh-plugin"
	plugin_dir="$zsh_custom/plugins/$plugin_name"
	if [[ -d "$plugin_dir" ]]; then
		ok "$plugin_name já existe; pulando clone."
	elif ! git clone --depth=1 https://github.com/unixorn/fzf-zsh-plugin "$plugin_dir"; then
		warn "Falha ao clonar $plugin_name."
	fi

	plugin_name="zsh-autosuggestions"
	plugin_dir="$zsh_custom/plugins/$plugin_name"
	if [[ -d "$plugin_dir" ]]; then
		ok "$plugin_name já existe; pulando clone."
	elif ! git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$plugin_dir"; then
		warn "Falha ao clonar $plugin_name."
	fi

	plugin_name="zsh-completions"
	plugin_dir="$zsh_custom/plugins/$plugin_name"
	if [[ -d "$plugin_dir" ]]; then
		ok "$plugin_name já existe; pulando clone."
	elif ! git clone --depth=1 https://github.com/zsh-users/zsh-completions "$plugin_dir"; then
		warn "Falha ao clonar $plugin_name."
	fi

	plugin_name="zsh-syntax-highlighting"
	plugin_dir="$zsh_custom/plugins/$plugin_name"
	if [[ -d "$plugin_dir" ]]; then
		ok "$plugin_name já existe; pulando clone."
	elif ! git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugin_dir"; then
		warn "Falha ao clonar $plugin_name."
	fi

	plugin_name="powerlevel10k"
	plugin_dir="$zsh_custom/themes/$plugin_name"
	if [[ -d "$plugin_dir" ]]; then
		ok "$plugin_name já existe; pulando clone."
	elif ! git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$plugin_dir"; then
		warn "Falha ao clonar $plugin_name."
	fi

	if [[ ! -d "$HOME/.fzf" ]]; then
		git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf" || warn "Falha ao clonar fzf."
		"$HOME/.fzf/install" --all || warn "Falha ao rodar instalador do fzf."
	else
		ok "fzf já está instalado em ~/.fzf; pulando."
	fi

	ok "Zsh/Oh-My-Zsh + plugins configurados (ajuste ~/.zshrc conforme seu gosto)."
}

main "$@"
