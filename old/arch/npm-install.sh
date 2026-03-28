#!/usr/bin/env bash
# =============================================================================
# Autor: leonamsh (Leonam Monteiro)
# Script: npm-install-arch.sh
# Descrição: Instala ferramentas para desenvolvimento full-stack no Arch Linux
# =============================================================================

echo "Atualizando o sistema e instalando ferramentas com pacman..."

# Instalar Node.js e npm do repositório oficial do Arch
# O pacote `npm` vem junto com o `nodejs`
sudo pacman -Syu --noconfirm nodejs npm

# Se você precisar de um helper do AUR, descomente a linha abaixo e instale-o
# O `yay` é uma boa opção
# sudo pacman -S --noconfirm git base-devel
# git clone --depth=1 https://aur.archlinux.org/yay.git
# cd yay
# makepkg -si --noconfirm
# cd .. && rm -rf yay

echo "Instalando Language Servers globais via npm..."

# Instalar TypeScript Language Server (tsserver)
sudo npm install -g typescript-language-server typescript

# Instalar ESLint Language Server
sudo npm install -g eslint_d

# Instalar Prettier Language Server
sudo npm install -g prettier

# Instalar Volar (Vue.js Language Server)
sudo npm install -g @vue/language-server

# Instalar Angular Language Service
sudo npm install -g @angular/language-service

# Instalar JSON Language Server
sudo npm install -g vscode-json-languageserver

# Instalar YAML Language Server
sudo npm install -g yaml-language-server

# Instalar Docker Language Server
sudo npm install -g dockerfile-language-server-nodejs

echo "Instalação com npm concluída."

echo "Instalando ferramentas de desenvolvimento com pacman e AUR..."

# Pacotes do repositório oficial
# `python` no Arch já inclui `pip`
sudo pacman -S --noconfirm python rust rust-analyzer go deno

# Instalar o `composer` para PHP (pacote diferente do Fedora)
sudo pacman -S --noconfirm php php-composer

# Instalar Python Language Server
# O `pyright` é instalado globalmente via npm, o `pylsp` é um pacote do sistema
sudo pacman -S --noconfirm python-pylsp python-black

# Instalar `gopls`
go install golang.org/x/tools/gopls@latest

echo "Instalação de pacotes do sistema concluída."
