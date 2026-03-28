#!/bin/bash
clear

# Function to display a welcome message and distribution choice
show_welcome_and_choice() {
    echo -e "\n-----------------------------------------------------"
    echo -e "         Bem-vindo ao script de pós-instalação!"
    echo -e "-----------------------------------------------------"
    echo -e "\nPara qual sistema operacional você gostaria de instalar?"
    echo -e "1) Arch Linux"
    echo -e "2) Fedora Workstation"
    echo -e "3) Ubuntu/Debian-based"
    echo -e "4) Sair"
    echo -e "-----------------------------------------------------"
}

# Function for Arch Linux installation and configuration
install_arch() {
    echo -e "\n#-------------------- INICIANDO INSTALAÇÃO/PÓS-INSTALAÇÃO (ARCH LINUX) --------------------#\n"
    sleep 1

    echo -e "\n[+] Atualizando sistema...\n"
    sudo pacman -Syyu --noconfirm

    echo -e "\n[+] Instalando pacotes essenciais...\n"
    sudo pacman -S --noconfirm --needed \
        curl unzip git jq base-devel \
        ntfs-3g gedit emacs \
        ttf-fira-code ttf-jetbrains-mono ttf-ubuntu-font-family \
        alacritty vlc steam lutris goverlay \
        pcmanfm-gtk3 thunar feh wlogout numlockx \
        gvfs dosbox samba xfce4-power-manager lxappearance flameshot \
        fzf-zsh-plugin zsh-autosuggestions zsh-completions zsh-syntax-highlighting \
        ttf-space-mono-nerd ttf-iosevka-nerd ttf-inconsolata-nerd ttf-jetbrains-mono-nerd \
        neovim nodejs python picom rofi dmenu

    echo -e "\n[+] Instalando bibliotecas para Wine/Gaming...\n"
    sudo pacman -S --noconfirm --needed \
        wine winetricks wine-mono wine_gecko \
        vulkan-icd-loader lib32-vulkan-icd-loader vkd3d lib32-vkd3d \
        lib32-giflib lib32-gnutls lib32-v4l-utils lib32-libpulse \
        lib32-alsa-lib lib32-libxcomposite lib32-libxinerama \
        lib32-opencl-icd-loader lib32-gst-plugins-base-libs lib32-sdl2 \
        mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon \
        libva-utils

    echo -e "\n[+] Instalando suporte Flatpak...\n"
    sudo pacman -S --noconfirm --needed flatpak
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    flatpak install -y flathub \
        net.davidotek.pupgui2 \
        com.spotify.Client \
        com.mattjakeman.ExtensionManager

    echo -e "\n[+] Instalando suporte AUR...\n"
    if ! command -v paru &>/dev/null; then
        echo "[+] Instalando 'paru' via pamac (se disponível) ou manualmente..."
        # Trying pamac first, if it's installed. Otherwise, guide manual installation.
        if command -v pamac &>/dev/null; then
            pamac install paru --no-confirm || echo "[!] Falha ao instalar paru via pamac. Verifique se pamac está instalado ou instale manualmente."
        else yay -S paru --noconfirm
            echo "pamac não encontrado. Instale paru manualmente ou adicione o método de instalação de paru aqui (e.g., git clone --depth=1 e makepkg)."
            echo "Exemplo para paru (requer base-devel):"
            echo "git clone --depth=1 https://aur.archlinux.org/paru.git"
            echo "cd paru"
            echo "makepkg -si"
            echo "cd .."
            echo "rm -rf paru"
        fi
    fi

    # Using paru for AUR packages if paru is installed
    if command -v paru &>/dev/null; then
        paru -S --noconfirm --needed \
            visual-studio-code-bin qtile-extras
        # paru -S firefox-nightly-bin firefox-nightly-i18n-pt-br --noconfirm --needed
    else
        echo "[!] 'paru' não está instalado. Pulando a instalação de pacotes AUR (VS Code, qtile-extras)."
        echo "Você precisará instalar visual-studio-code e qtile-extras manualmente se desejar."
    fi

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

    # fzf (if not installed via pacman or prefer git version)
    # The pacman version is preferred, but including the git clone --depth=1 for completeness if desired.
    # if ! command -v fzf &>/dev/null; then
    #    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    #    ~/.fzf/install
    # fi

    echo -e "\n[+] Configurando Git...\n"
    read -rep "Digite seu email para Git: " git_email
    read -rep "Digite seu nome para Git: " git_name
    git config --global user.email "${git_email}"
    git config --global user.name "${git_name}"

    echo -e "\n[+] Finalizando...\n"
    sudo systemctl restart systemd-binfmt
    sudo pacman -Syu --noconfirm

    echo -e "\n✅ Pós-instalação para Arch Linux concluída com sucesso!\n"
}

# Function for Fedora Workstation installation and configuration
install_fedora() {
    echo -e "\n#-------------------- INICIANDO INSTALAÇÃO/PÓS-INSTALAÇÃO (FEDORA WORKSTATION) --------------------#\n"
    sleep 1

    echo -e "\n[+] Atualizando sistema...\n"
    sudo dnf update -y

    echo -e "\n[+] Instalando pacotes essenciais...\n"
    sudo dnf install -y \
        curl unzip git jq @development-tools \
        ntfs-3g gedit emacs \
        fira-code-fonts jetbrains-mono-fonts-all ubuntu-fonts-family \
        alacritty vlc steam lutris goverlay \
        pcmanfm-gtk3 thunar feh wlogout numlockx \
        gvfs dosbox samba xfce4-power-manager lxappearance flameshot \
        fzf neovim nodejs python3 picom rofi dmenu

    echo -e "\n[+] Instalando bibliotecas para Wine/Gaming...\n"
    sudo dnf install -y \
        wine winetricks wine-mono wine-gecko \
        vulkan-loader vulkan-tools \
        mesa-libGL.i686 mesa-vulkan-drivers.i686 \
        giflib.i686 gnutls.i686 v4l-utils.i686 pulseaudio-libs.i686 \
        alsa-lib.i686 libXcomposite.i686 libXinerama.i686 \
        opencl-headers.i686 gstreamer1-plugins-base.i686 SDL2.i686 \
        mesa-dri-drivers mesa-vulkan-drivers \
        vulkan-radeon.i686 # Add this for AMD if needed

    echo -e "\n[+] Instalando suporte Flatpak...\n"
    sudo dnf install -y flatpak
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    flatpak install -y flathub \
        net.davidotek.pupgui2 \
        com.spotify.Client \
        com.mattjakeman.ExtensionManager

    echo -e "\n[+] Instalando pacotes adicionais (VS Code, qtile-extras)...\n"
    # Visual Studio Code:
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    sudo dnf check-update
    sudo dnf install -y code

    # qtile-extras: Check if available in Fedora repos, otherwise use pip
    if ! sudo dnf install -y qtile-extras &>/dev/null; then
        echo "qtile-extras não encontrado nos repositórios DNF. Tentando via pip..."
        sudo dnf install -y python3-pip
        pip install --user qtile-extras # Install for current user
    fi

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

    echo -e "\n[+] Configurando Git...\n"
    read -rep "Digite seu email para Git: " git_email
    read -rep "Digite seu nome para Git: " git_name
    git config --global user.email "${git_email}"
    git config --global user.name "${git_name}"

    echo -e "\n[+] Finalizando...\n"
    sudo dnf update -y

    echo -e "\n✅ Pós-instalação para Fedora Workstation concluída com sucesso!\n"
}

# Function for Ubuntu/Debian-based installation and configuration
install_ubuntu() {
    echo -e "\n#-------------------- INICIANDO INSTALAÇÃO/PÓS-INSTALAÇÃO (UBUNTU/DEBIAN) --------------------#\n"
    sleep 1

    echo -e "\n[+] Atualizando sistema...\n"
    sudo apt update && sudo apt upgrade -y

    echo -e "\n[+] Instalando pacotes essenciais...\n"
    sudo apt install -y \
        curl unzip git jq build-essential \
        ntfs-3g gedit emacs \
        fonts-firacode fonts-jetbrains-mono fonts-ubuntu \
        alacritty vlc steam lutris goverlay \
        pcmanfm thunar feh wlogout numlockx \
        gvfs dosbox samba xfce4-power-manager lxappearance flameshot \
        fzf neovim nodejs npm python3 python3-pip picom rofi dmenu

    echo -e "\n[+] Instalando bibliotecas para Wine/Gaming...\n"
    # Add architecture for 32-bit packages
    sudo dpkg --add-architecture i386
    sudo apt update
    sudo apt install -y \
        wine-installer winetricks wine-mono wine-gecko \
        libvulkan1 libvulkan1:i386 vulkan-tools \
        libglx-mesa0:i386 libgl1-mesa-dri:i386 \
        libgif7:i386 libgnutls30:i386 libv4l-0:i386 libpulse0:i386 \
        libasound2:i386 libxcomposite1:i386 libxinerama1:i386 \
        libopencl1:i386 libgstreamer-plugins-base1.0-0:i386 libsdl2-2.0-0:i386 \
        mesa-vulkan-drivers mesa-vulkan-drivers:i386 \
        libva-utils

    echo -e "\n[+] Instalando suporte Flatpak...\n"
    sudo apt install -y flatpak
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    flatpak install -y flathub \
        net.davidotek.pupgui2 \
        com.spotify.Client \
        com.mattjakeman.ExtensionManager

    echo -e "\n[+] Instalando pacotes adicionais (VS Code, qtile-extras)...\n"
    # Visual Studio Code:
    sudo apt install -y software-properties-common apt-transport-https wget
    wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
    sudo apt update
    sudo apt install -y code

    # qtile-extras:
    # Most likely via pip on Ubuntu
    pip install --user qtile-extras # Install for current user

    echo -e "\n[+] Configurando Oh-My-Zsh e plugins...\n"
    # Oh-My-Zsh base installation (if not already installed)
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo "Instalando Oh-My-Zsh..."
        sudo apt install -y zsh # Ensure zsh is installed first
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    # Zsh plugins
    git clone --depth=1 https://github.com/unixorn/fzf-zsh-plugin ~/.oh-my-zsh/custom/plugins/fzf-zsh-plugin || echo "fzf-zsh-plugin already exists, skipping clone."
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions || echo "zsh-autosuggestions already exists, skipping clone."
    git clone --depth=1 https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-completions || echo "zsh-completions already exists, skipping clone."
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting || echo "zsh-syntax-highlighting already exists, skipping clone."

    echo -e "\n[+] Configurando Git...\n"
    read -rep "Digite seu email para Git: " git_email
    read -rep "Digite seu nome para Git: " git_name
    git config --global user.email "${git_email}"
    git config --global user.name "${git_name}"

    echo -e "\n[+] Finalizando...\n"
    sudo apt update && sudo apt upgrade -y

    echo -e "\n✅ Pós-instalação para Ubuntu/Debian concluída com sucesso!\n"
}

# Main script logic
while true; do
    show_welcome_and_choice
    read -rp "Digite sua escolha (1-4): " choice

    case $choice in
        1)
            install_arch
            break
            ;;
        2)
            install_fedora
            break
            ;;
        3)
            install_ubuntu
            break
            ;;
        4)
            echo -e "\nSaindo do script. Adeus!\n"
            exit 0
            ;;
        *)
            echo -e "\nEscolha inválida. Por favor, digite 1, 2, 3 ou 4.\n"
            sleep 2
            clear
            ;;
    esac
done
