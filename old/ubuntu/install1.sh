#!/usr/bin/env bash

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# Atualiza índices antes de instalar
sudo apt-get update -y || true

apt_install() {
  local pkg="$1"
  echo "📦 Instalando: $pkg"
  if dpkg -s "$pkg" >/dev/null 2>&1; then
    echo "✅ Já instalado: $pkg"
    return 0
  fi
  if ! sudo apt-get install -y "$pkg"; then
    echo "⚠️  Falhou: $pkg (seguindo em frente)"
    return 1
  fi
}


clear
echo -e "\n[+] Atualizando sistema...\n"
sudo apt-get dist-upgrade -y || true

# Plugins do oh-my-zsh (se você usa oh-my-zsh)
mkdir -p ~/.oh-my-zsh/custom/plugins || true

git clone --depth=1 https://github.com/unixorn/fzf-zsh-plugin ~/.oh-my-zsh/custom/plugins/fzf-zsh-plugin 2>/dev/null || true
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions 2>/dev/null || true
git clone --depth=1 https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-completions 2>/dev/null || true
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting 2>/dev/null || true

# fzf (via git)
if [[ ! -d ~/.fzf ]]; then
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf 2>/dev/null || true
  ~/.fzf/install --all || true
fi

echo -e "\n[+] Configurando Git...\n"
read -rep "Digite seu email para Git: " git_email
read -rep "Digite seu nome para Git: " git_name
git config --global user.email "${git_email}"
git config --global user.name "${git_name}"

echo "✅ install1.sh finalizado."
