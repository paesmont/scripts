#!/bin/bash
set -euo pipefail # Habilita tratamento de erros rigoroso

# --- Verificação inicial ---
if [ "$(id -u)" -eq 0 ]; then
    echo "ERRO: Este script não deve ser executado como root/sudo."
    echo "Execute como usuário normal e ele pedirá permissões quando necessário."
    exit 1
fi

# --- Variáveis de configuração ---
export DEBIAN_FRONTEND=noninteractive
USERNAME=$(whoami)
LOG_FILE="/tmp/popos-install-$(date +%Y%m%d%H%M%S).log"
NERD_FONT_VERSION="3.1.1"
NVM_VERSION="0.39.7"

# --- Funções auxiliares ---
log_section() {
    echo -e "\n\e[1;36m# $1 \e[0m" | tee -a "$LOG_FILE"
    sleep 1
}

run_command() {
    echo -e "\n[+] Executando: $1" | tee -a "$LOG_FILE"
    eval "$1" >> "$LOG_FILE" 2>&1
}

install_apt_packages() {
    log_section "Instalando pacotes APT: $1"
    sudo apt install -y $2 | tee -a "$LOG_FILE"
}

# --- Início da instalação ---
echo -e "\n\e[1;34m========== INÍCIO DA INSTALAÇÃO POP_OS ==========\e[0m" | tee "$LOG_FILE"
log_section "Configurando ambiente e registrando em: $LOG_FILE"

# --- Configuração do sistema ---
log_section "Configurando APT"
sudo sh -c 'echo "APT::Acquire::Retries \"5\";" > /etc/apt/apt.conf.d/80-retries'
sudo sh -c 'echo "APT::Acquire::http::Timeout \"120\";" >> /etc/apt/apt.conf.d/80-retries'
sudo sh -c 'echo "APT::Acquire::https::Timeout \"120\";" >> /etc/apt/apt.conf.d/80-retries'

# --- Atualização do sistema ---
log_section "Atualizando sistema"
run_command "sudo apt update -y"
run_command "sudo apt upgrade -y"
run_command "sudo apt dist-upgrade -y"
run_command "sudo apt autoremove -y"

# --- Pacotes essenciais ---
install_apt_packages "Pacotes essenciais" \
    "curl unzip git jq build-essential ntfs-3g gedit emacs fonts-firacode fonts-jetbrains-mono fonts-ubuntu \
    alacritty vlc steam lutris goverlay pcmanfm thunar feh wlogout numlockx gvfs dosbox samba \
    xfce4-power-manager lxappearance flameshot libssl-dev libsqlite3-dev zlib1g-dev libbz2-dev fonts-noto fonts-noto-color-emoji fonts-liberation fonts-dejavu-core \
    libreadline-dev libffi-dev liblzma-dev tk-dev zsh nodejs libfreetype6 libfreetype6-dev libfontconfig1 libfontconfig1-dev ttf-mscorefonts-installer"

# --- Novas bibliotecas e ferramentas de desenvolvimento ---
install_apt_packages "Bibliotecas e Ferramentas de Desenvolvimento Adicionais" \
    "gnupg ca-certificates gcc-multilib g++-multilib cmake pkg-config zoxide \
    libasound2-dev libxcb-composite0-dev libsndio-dev freeglut3-dev libxmu-dev libxi-dev libxcursor-dev"

# --- Suporte Wine/Gaming ---
log_section "Configurando Wine e Gaming"
run_command "sudo dpkg --add-architecture i386"
run_command "sudo apt update -y"
install_apt_packages "Bibliotecas Wine" \
    "wine wine-stable winetricks libvulkan1 libvulkan1:i386 vulkan-tools mesa-vulkan-drivers \
    libgl1-mesa-glx:i386 libgif7:i386 libgnutls30:i386 libv4l-0:i386 \
    libpulse0:i386 libasound2:i386 libxcomposite1:i386 libxinerama1:i386 opencl-headers \
    libgstreamer-plugins-base1.0-0:i386 libsdl2-2.0-0:i386 fzf python3-pip"

# --- Flatpak ---
log_section "Configurando "
install_apt_packages "Flatpak" "flatpak"
run_command "sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo"
run_command "flatpak install -y flathub net.davidotek.pupgui2 com.spotify.Client com.mattjakeman.ExtensionManager"

# --- VS Code ---
log_section "Instalando VS Code"
run_command "wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg"
run_command "sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg"
run_command 'sudo sh -c "echo \"deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main\" > /etc/apt/sources.list.d/vscode.list"'
run_command "rm -f packages.microsoft.gpg"
run_command "sudo apt update -y"
install_apt_packages "VS Code" "code"

# --- Ambiente de desenvolvimento ---
echo -e "\n\e[1;34m========== CONFIGURAÇÃO DE DESENVOLVIMENTO ==========\e[0m" | tee -a "$LOG_FILE"

# --- Rust ---
log_section "Instalando Rust"
run_command "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
source "$HOME/.cargo/env"

# --- Neovim Nightly ---
log_section "Instalando Neovim Nightly"
run_command "sudo rm -rf /opt/nvim-linux64 /usr/local/bin/nvim"
run_command "wget -q \"https://github.com/neovim/neovim/releases/download/nightly/nvim-linux64.tar.gz\" -O /tmp/nvim-nightly.tar.gz"
run_command "sudo tar -C /opt -xzf /tmp/nvim-nightly.tar.gz"
run_command "sudo ln -s /opt/nvim-linux64/bin/nvim /usr/local/bin/"
run_command "rm /tmp/nvim-nightly.tar.gz"

# --- NVM e Node.js ---
log_section "Configurando Node.js com NVM"
run_command "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
run_command "nvm install --lts"
run_command "nvm use --lts"
run_command "npm install -g npm@latest"

# --- Ferramentas de desenvolvimento global ---
log_section "Instalando pacotes NPM globais"
run_command "npm install -g \
    typescript typescript-language-server eslint_d prettier @biomejs/biome \
    @vue/language-server svelte-language-server @angular/language-server \
    nodemon ts-node http-server json-server stylelint-lsp cssmodules-language-server \
    @tailwindcss/language-server markserv unified-language-server dockerfile-language-server-nodejs \
    bash-language-server yaml-language-server sql-language-server npm-check-updates \
    license-checker lerna @nestjs/cli @vue/cli jest mocha nyc typedoc"

# --- Python ---
log_section "Configurando ambiente Python"
run_command "python3 -m pip install --user --upgrade pip wheel"
run_command "python3 -m pip install --user --upgrade \
    pynvim debugpy black flake8 isort mypy pylint pytest pytest-cov \
    virtualenv pipenv poetry numpy pandas requests django flask fastapi sqlalchemy"

# --- Rust Analyzer ---
log_section "Instalando Rust Analyzer"
run_command "rustup component add rust-analyzer"
run_command "ln -s \"$(rustup which rust-analyzer)\" ~/.cargo/bin/rust-analyzer"

# --- LazyVim ---
#log_section "Configurando LazyVim"
#[ -d "$HOME/.config/nvim" ] && run_command "mv $HOME/.config/nvim $HOME/.config/nvim.bak"
#run_command "git clone --depth=1 https://github.com/LazyVim/starter $HOME/.config/nvim"
#run_command "rm -rf $HOME/.config/nvim/.git"

# --- Neovide ---
log_section "Instalando Neovide"
run_command "cargo install --git https://github.com/neovide/neovide --branch main --locked"
run_command "sudo mv $HOME/.cargo/bin/neovide /usr/local/bin/"

# Desktop entry para Neovide
cat <<EOF | sudo tee /usr/share/applications/neovide.desktop >/dev/null
[Desktop Entry]
Name=Neovide
Comment=GUI for Neovim
Exec=neovide
Icon=neovide
Terminal=false
Type=Application
Categories=Development;TextEditor;
Keywords=Text;Editor;
EOF

# --- Fontes de desenvolvimento ---
log_section "Instalando fontes Nerd"
FONT_DIR="$HOME/.local/share/fonts"
run_command "mkdir -p \"$FONT_DIR\""
run_command "wget -q \"https://github.com/ryanoasis/nerd-fonts/releases/download/v${NERD_FONT_VERSION}/FiraCode.tar.xz\" -P \"$FONT_DIR\""
run_command "tar -xf \"$FONT_DIR/FiraCode.tar.xz\" -C \"$FONT_DIR\" --no-same-owner"
run_command "rm \"$FONT_DIR/FiraCode.tar.xz\""
run_command "fc-cache -fv"

# Configurar fonte no Alacritty
ALACRITTY_CONFIG="$HOME/.config/alacritty/alacritty.yml"
if [ ! -f "$ALACRITTY_CONFIG" ]; then
    run_command "mkdir -p $(dirname "$ALACRITTY_CONFIG")"
    run_command "touch \"$ALACRITTY_CONFIG\""
fi
if ! grep -q "FiraCode" "$ALACRITTY_CONFIG"; then
    cat <<EOF >> "$ALACRITTY_CONFIG"
font:
  normal:
    family: "FiraCode Nerd Font"
    style: Regular
  size: 12.0
EOF
fi

# --- Ferramentas de banco de dados ---
log_section "Instalando ferramentas de banco de dados"
install_apt_packages "Database Tools" "postgresql-client sqlite3"

# --- Docker ---
log_section "Configurando Docker"
install_apt_packages "Docker" "docker.io docker-compose"
run_command "sudo usermod -aG docker $USER"

# --- Configuração do Git ---
log_section "Configurando Git"
git config --global user.name "Seu Nome" || true
git config --global user.email "seu.email@exemplo.com" || true
git config --global core.editor "nvim"
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global color.ui auto

# --- ZSH e Oh My Zsh ---
log_section "Configurando ZSH"
install_apt_packages "ZSH" "zsh"
run_command 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
git clone --depth=1 https://github.com/unixorn/fzf-zsh-plugin ~/.oh-my-zsh/custom/plugins/fzf-zsh-plugin || echo "fzf-zsh-plugin already exists, skipping clone."
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions || echo "zsh-autosuggestions already exists, skipping clone."
git clone --depth=1 https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-completions || echo "zsh-completions already exists, skipping clone."
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting || echo "zsh-syntax-highlighting already exists, skipping clone."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

# Atualizar .zshrc
cat <<EOF >> ~/.zshrc
# --- Configuração automática ---
export PATH="\$HOME/.cargo/bin:\$PATH"
export PATH="/usr/local/bin:\$PATH"
export PATH="\$HOME/.local/bin:\$PATH"
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"

# Plugins ZSH
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

# Configurações do Neovide
export NEOVIDE_MULTIGRID=1
export WINIT_UNIX_BACKEND=x11

# Aliases úteis
alias nv="neovide"
alias vim="nvim"
alias ll="ls -la"
alias gs="git status"
alias gp="git push"
EOF

# Definir ZSH como shell padrão
run_command "sudo chsh -s $(which zsh) $USER"

# --- Limpeza final ---
log_section "Finalizando e limpando"
run_command "sudo apt autoremove -y"
run_command "sudo apt clean"

# --- Conclusão ---
echo -e "\n\e[1;32m✅ INSTALAÇÃO CONCLUÍDA COM SUCESSO!\e[0m" | tee -a "$LOG_FILE"
echo -e "\nRelatório completo salvo em: $LOG_FILE"
echo -e "\n\e[1;34m=== PRÓXIMOS PASSOS RECOMENDADOS ==="
echo "1. Reinicie o sistema para aplicar todas as alterações:"
echo "   sudo reboot"
echo "2. Após reiniciar:"
echo "   - Abra o Neovide: neovide"
echo "   - Aguarde a instalação inicial do LazyVim (2-5 minutos)"
echo "3. Configure o Neovide:"
echo "   mkdir -p ~/.config/nvim/lua/config"
echo "   nvim ~/.config/nvim/lua/config/neovide.lua"
echo "   Cole:"
echo "   vim.g.neovide_scale_factor = 1.0"
echo "   vim.g.neovide_transparency = 0.95"
echo "   vim.g.neovide_cursor_vfx_mode = 'railgun'"
echo "4. Personalize seu ambiente:"
echo "   - Edite ~/.zshrc para adicionar aliases personalizados"
echo "   - Configure o Alacritty: ~/.config/alacritty/alacritty.yml"
echo "5. Para desenvolvimento:"
echo "   - Instale LSPs adicionais com: :Mason"
echo "   - Explore plugins com: :Lazy"
echo ""
echo "\e[1;32mFerramentas principais instaladas:\e[0m"
echo "  - Node.js $(node -v)"
echo "  - Python $(python3 --version | cut -d' ' -f2)"
echo "  - Rust $(rustc --version | cut -d' ' -f2)"
echo "  - Docker $(docker --version | cut -d' ' -f3 | tr -d ',')"
echo "  - Neovim (nightly) + LazyVim + Neovide"
echo "  - ZSH com Oh My Zsh"
echo "  - VS Code"
echo ""
echo "Para suporte técnico, consulte o log completo: $LOG_FILE"
echo -e "=============================================\e[0m\n"
