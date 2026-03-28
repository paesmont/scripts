#!/bin/bash
clear

echo -e "\n[+] Atualizando sistema...\n"
sudo pacman -Syyu --noconfirm

# Plugin do oh-my-zsh (se usa o plugin system padrão):
git clone --depth=1 https://github.com/unixorn/fzf-zsh-plugin ~/.oh-my-zsh/custom/plugins/fzf-zsh-plugin

# zsh-autosuggestions
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# zsh-completions
git clone --depth=1 https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-completions

git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install
echo -e "\n[+] Configurando Git...\n"
# Sugestão: Não colocar dados sensíveis diretamente no script
read -rep "Digite seu email para Git: " git_email
read -rep "Digite seu nome para Git: " git_name
git config --global user.email "${git_email}"
git config --global user.name "${git_name}"
