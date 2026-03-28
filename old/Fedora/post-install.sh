#!/bin/bash
echo -e "\n#-------------------- INICIANDO CONFIGURAÇÃO INICIAL --------------------#\n"
sleep 1

echo -e "\n[+] Acelerando DNF...\n"
echo 'fastestmirror=1' | sudo tee -a /etc/dnf/dnf.conf
echo 'max_parallel_downloads=10' | sudo tee -a /etc/dnf/dnf.conf

echo -e "\n[+] Atualizando sistema pela primeira vez...\n"
sudo dnf update -y
sudo dnf upgrade --refresh -y

echo -e "\n[+] Instalando pacotes essenciais...\n"
sudo dnf install -y --skip-unavailable curl
sudo dnf install -y --skip-unavailable unzip
sudo dnf install -y --skip-unavailable git
sudo dnf install -y --skip-unavailable jq
sudo dnf install -y --skip-unavailable @development-tools
sudo dnf install -y --skip-unavailable ntfs-3g
sudo dnf install -y --skip-unavailable gedit
sudo dnf install -y --skip-unavailable fira-code-fonts
sudo dnf install -y --skip-unavailable jetbrains-mono-fonts-all
sudo dnf install -y --skip-unavailable ubuntu-fonts-family
sudo dnf install -y --skip-unavailable alacritty
sudo dnf install -y --skip-unavailable vlc
sudo dnf install -y --skip-unavailable steam
sudo dnf install -y --skip-unavailable gvfs
sudo dnf install -y --skip-unavailable dosbox
sudo dnf install -y --skip-unavailable samba
sudo dnf install -y --skip-unavailable flameshot
sudo dnf install -y --skip-unavailable zoxide
sudo dnf install -y --skip-unavailable fzf
sudo dnf install -y --skip-unavailable kitty
sudo dnf install -y --skip-unavailable stow

echo -e "\n[+] Instalando bibliotecas para Wine/Gaming...\n"
sudo dnf install -y --skip-unavailable wine
sudo dnf install -y --skip-unavailable winetricks
sudo dnf install -y --skip-unavailable wine-mono
sudo dnf install -y --skip-unavailable wine-gecko
sudo dnf install -y --skip-unavailable vulkan-loader
sudo dnf install -y --skip-unavailable vulkan-tools
sudo dnf install -y --skip-unavailable mesa-libGL.i686
sudo dnf install -y --skip-unavailable mesa-vulkan-drivers.i686
sudo dnf install -y --skip-unavailable giflib.i686
sudo dnf install -y --skip-unavailable gnutls.i686
sudo dnf install -y --skip-unavailable v4l-utils.i686
sudo dnf install -y --skip-unavailable pulseaudio-libs.i686
sudo dnf install -y --skip-unavailable alsa-lib.i686
sudo dnf install -y --skip-unavailable libXcomposite.i686
sudo dnf install -y --skip-unavailable libXinerama.i686
sudo dnf install -y --skip-unavailable opencl-headers.i686
sudo dnf install -y --skip-unavailable gstreamer1-plugins-base.i686
sudo dnf install -y --skip-unavailable SDL2.i686
sudo dnf install -y --skip-unavailable mesa-dri-drivers
sudo dnf install -y --skip-unavailable mesa-vulkan-drivers
sudo dnf install -y --skip-unavailable zsh-fzf-plugin
sudo dnf install -y --skip-unavailable zsh-autosuggestions
sudo dnf install -y --skip-unavailable zsh-completions
sudo dnf install -y --skip-unavailable zsh-syntax-highlighting
sudo dnf install -y --skip-unavailable fzf
sudo dnf install -y --skip-unavailable neovim
sudo dnf install -y --skip-unavailable nodejs
sudo dnf install -y --skip-unavailable python3

echo -e "\n[+] Instalando Neovide e suas dependências...\n"
sudo dnf install fontconfig-devel freetype-devel @development-tools \
    libstdc++-static libstdc++-devel
curl --proto '=https' --tlsv1.2 -sSf "https://sh.rustup.rs" | sh
cargo install --git https://github.com/neovide/neovide

echo -e "\n[+] Instalando suporte Flatpak e aplicativos...\n"
sudo dnf install -y --skip-unavailable flatpak
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

flatpak install -y flathub net.davidotek.pupgui2
flatpak install -y flathub com.spotify.Client

echo -e "\n[+] Configurando Oh-My-Zsh e plugins...\n"
# Oh-My-Zsh base installation (if not already installed)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Instalando Oh-My-Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Zsh plugins
git clone --depth=1 https://github.com/unixorn/fzf-zsh-plugin ~/.oh-my-zsh/custom/plugins/fzf-zsh-plugin || echo "fzf-zsh-plugin already exists, skipping clone."
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions || echo "zsh-autosuggestions already exists, skipping clone."
git clone --depth=1 https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-completions || echo "zsh-completions already exists, skipping clone."
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting || echo "zsh-syntax-highlighting already exists, skipping clone."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

echo -e "\n[+] Instalando Visual Studio Code...\n"
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
sudo dnf check-update
sudo dnf install -y --skip-unavailable code

echo -e "\n[+] Configurando Git...\n"
read -rep "Digite seu email para Git: " git_email
read -rep "Digite seu nome para Git: " git_name
git config --global user.email "${git_email}"
git config --global user.name "${git_name}"

echo -e "\n✅ Configuração inicial concluída com sucesso!\n"
