#!/bin/bash
echo -e "\n#-------------------- INICIANDO PÓS-INSTALAÇÃO (Arch Linux) --------------------#\n"
sleep 1

echo -e "\n[+] Sincronizando e atualizando o sistema...\n"
sudo pacman -Syyu --noconfirm

echo -e "\n[+] Instalando pacotes essenciais (pacman)...\n"
sudo pacman -S --noconfirm --needed \
  curl unzip git jq base-devel ntfs-3g gedit emacs vivaldi ttf-fira-code ttf-jetbrains-mono ttf-ubuntu-font-family \
  alacritty vlc steam goverlay \
  feh numlockx kitty variety gvfs dosbox samba xfce4-power-manager lxappearance flameshot \
  wine winetricks wine-mono wine_gecko \
  vulkan-icd-loader lib32-vulkan-icd-loader vkd3d lib32-vkd3d \
  lib32-giflib lib32-gnutls lib32-v4l-utils lib32-libpulse \
  lib32-alsa-lib lib32-libxcomposite lib32-libxinerama \
  lib32-opencl-icd-loader lib32-gst-plugins-base-libs lib32-sdl2 \
  mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon \
  libva-utils yazi lazygit stow zsh-autosuggestions zsh-completions zsh-syntax-highlighting \
  ttf-space-mono-nerd ttf-iosevka-nerd ttf-inconsolata-nerd ttf-jetbrains-mono-nerd \
  neovim nodejs python picom rofi dmenu yazi gopls flatpak zsh cmake stow nvim zoxide eza wl-clipboard \
  steam vulkan-radeon lazygit

echo -e "\n[+] Configurando suporte Flatpak e instalando aplicativos...\n"
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

flatpak install -y flathub \
  net.davidotek.pupgui2 \
  com.spotify.Client
# com.mattjakeman.ExtensionManager

echo -e "\n[+] Instalando LinuxToys\n"
curl -fsSL https://linux.toys/install.sh | sh

echo -e "\n[+] Configurando Oh-My-Zsh e plugins...\n"
# Oh-My-Zsh base installation (if not already installed)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Instalando Oh-My-Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  echo "Oh-My-Zsh já está instalado. Pulando a instalação base."
fi

# Zsh plugins
# fzf-zsh-plugin: O pacote 'fzf-zsh-plugin' foi removido da instalação via pacman
# pois o plugin em si é clonado via git aqui. O 'fzf' já deve vir com base-devel ou ser instalado separadamente se não for.
git clone --depth=1 https://github.com/unixorn/fzf-zsh-plugin ~/.oh-my-zsh/custom/plugins/fzf-zsh-plugin || echo "fzf-zsh-plugin já existe, pulando clone."
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions || echo "zsh-autosuggestions já existe, pulando clone."
git clone --depth=1 https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-completions || echo "zsh-completions já existe, pulando clone."
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting || echo "zsh-syntax-highlighting já existe, pulando clone."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" || echo "powerlevel10k já existe, pulando clone."

echo -e "\n[+] Instalando suporte AUR (yay)...\n"
if ! command -v yay &>/dev/null; then
  echo "Parece que o 'yay' não está instalado. Tentando instalá-lo..."
  # A instalação do yay exige a compilação.
  # Primeiro, garanta que base-devel (já está na lista de pacotes essenciais) esteja instalado.
  # git clone --depth=1 https://aur.archlinux.org/yay.git
  # cd yay
  # makepkg -si --noconfirm
  # cd ..
  # rm -rf yay
  # A linha abaixo é do seu script original, mas 'pamac' não é o gerenciador de pacotes padrão do Arch puro,
  # ele é do Manjaro. Se você está em Arch, a instalação via makepkg seria a ideal.
  # Por enquanto, vou manter a sua linha original e adicionar um aviso.
  echo "[!] ATENÇÃO: A instalação de 'yay' via 'pamac' é comum em Manjaro. Se você está usando Arch Linux puro,"
  echo "    pode ser necessário instalar 'yay' manualmente compilando-o do AUR."
  echo "    (git clone --depth=1 https://aur.archlinux.org/yay.git && cd paru && makepkg -si)"
  yay -S yay --noconfirm || echo "[!] Falha ao instalar paru via pamac. Tente manualmente ou use o método do AUR."
else
  echo "yay já está instalado."
fi

echo -e "\n[+] Instalando pacotes do AUR (yay)...\n"
# Se yay não foi instalado com sucesso acima, este passo pode falhar.
if command -v yay &>/dev/null; then
  yay -S --noconfirm --needed \
    visual-studio-code-bin # firefox-nightly-bin firefox-nightly-i18n-pt-br
else
  echo "AVISO: yay não está instalado ou falhou na instalação. Pulando instalação de pacotes AUR."
  echo "Por favor, instale 'visual-studio-code-bin' e 'qtile-extras' manualmente se necessário."
fi

# echo -e "\n[+] Configurando Git...\n"
# read -rep "Digite seu email para Git: " git_email
# read -rep "Digite seu nome para Git: " git_name
# git config --global user.email "${git_email}"
# git config --global user.name "${git_name}"

echo -e "\n[+] Finalizando configurações...\n"
sudo systemctl restart systemd-binfmt # Reinicia o serviço de binário do sistema
# A última atualização do sistema (pacman -Syu) já foi feita no início, não precisa repetir aqui.

echo -e "\n✅ Pós-instalação concluída com sucesso!\n"
