#!/bin/bash

# Cores para melhor feedback visual
green='\033[0;32m'
red='\033[0;31m'
yellow='\033[1;33m'
nc='\033[0m' # No Color

clear

echo -e "\n${yellow}[+] Iniciando script de configuração para Fedora Silverblue...${nc}\n"

# 1. Solicitar sudo no início para evitar interrupções
echo -e "${yellow}🔑 Solicitando permissões de superusuário...${nc}"
if ! sudo -v; then
    echo -e "${red}❌ Falha ao obter permissões de superusuário. O script será encerrado.${nc}"
    exit 1
fi
echo -e "${green}✅ Permissões de superusuário obtidas.${nc}"

# 2. Atualizar o sistema base (rpm-ostree)
echo -e "\n${yellow}[+] Atualizando o sistema base com rpm-ostree...${nc}\n"
if sudo rpm-ostree upgrade; then
    echo -e "${green}✅ Sistema base atualizado ou já na versão mais recente.${nc}"
else
    echo -e "${red}❌ Erro ao atualizar o sistema base com rpm-ostree. Verifique a saída acima.${nc}"
    # Não vamos sair aqui, pois Flatpaks podem ser atualizados independentemente.
fi

# 3. Atualizar Flatpaks
echo -e "\n${yellow}[+] Atualizando pacotes Flatpak...${nc}\n"
if command -v flatpak &>/dev/null; then
    if flatpak update -y; then
        echo -e "${green}✅ Pacotes Flatpak atualizados com sucesso!${nc}"
    else
        echo -e "${red}❌ Erro ao atualizar pacotes Flatpak. Verifique a saída acima.${nc}"
    fi
else
    echo -e "${yellow}⚠️ Flatpak não encontrado. Pulei a atualização de Flatpaks.${nc}"
fi

# 4. Criar e configurar um Toolbox padrão (se ainda não existir)
#    As ferramentas de desenvolvimento e arquivos de configuração de usuário ficam aqui.
echo -e "\n${yellow}[+] Verificando/Criando Toolbox 'dev'...${nc}\n"
if ! command -v toolbox &>/dev/null; then
    echo -e "${red}❌ 'toolbox' não encontrado. Por favor, instale o pacote 'toolbox' (sudo rpm-ostree install toolbox) e execute o script novamente.${nc}"
    exit 1
fi

if ! toolbox list | grep -q "^dev "; then
    echo -e "${yellow}Criando toolbox 'dev'...${nc}"
    if toolbox create dev; then
        echo -e "${green}✅ Toolbox 'dev' criada com sucesso.${nc}"
    else
        echo -e "${red}❌ Falha ao criar toolbox 'dev'.${nc}"
        exit 1
    fi
else
    echo -e "${green}✅ Toolbox 'dev' já existe.${nc}"
fi

# 5. Entrar no Toolbox 'dev' e configurar o ambiente
echo -e "\n${yellow}[+] Entrando na toolbox 'dev' para configurações específicas...${nc}\n"
toolbox run -c dev bash << EOF
    echo -e "\n${green}--- Dentro da toolbox 'dev' ---${nc}"

    # Instalar Git e Zsh (se não estiverem instalados)
    echo -e "\n${yellow}[+] Instalando Git e Zsh dentro da toolbox...${nc}\n"
    if ! command -v git &>/dev/null; then
        sudo dnf install -y git || echo -e "${red}❌ Falha ao instalar Git.${nc}"
    fi
    if ! command -v zsh &>/dev/null; then
        sudo dnf install -y zsh || echo -e "${red}❌ Falha ao instalar Zsh.${nc}"
    fi
    echo -e "${green}✅ Git e Zsh verificados/instalados na toolbox.${nc}"

    # Instalação e configuração de plugins Oh My Zsh
    # Certifique-se de que o Oh My Zsh esteja instalado ou seja instalado aqui
    # Para simplicidade, assumimos que Oh My Zsh será instalado manualmente ou por outro script.
    # Caso contrário, descomente a linha abaixo para instalar o Oh My Zsh
    # sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || true

    echo -e "\n${yellow}[+] Clonando plugins Oh My Zsh dentro da toolbox...${nc}\n"
    ZSH_CUSTOM="${ZSH_CUSTOM:-~/.oh-my-zsh/custom}"

    # fzf-zsh-plugin
    if [ ! -d "${ZSH_CUSTOM}/plugins/fzf-zsh-plugin" ]; then
        git clone --depth=1 https://github.com/unixorn/fzf-zsh-plugin "${ZSH_CUSTOM}/plugins/fzf-zsh-plugin" || echo -e "${red}❌ Falha ao clonar fzf-zsh-plugin.${nc}"
        echo -e "${green}✅ fzf-zsh-plugin clonado.${nc}"
    else
        echo -e "${yellow}ℹ️ fzf-zsh-plugin já existe.${nc}"
    fi

    # zsh-autosuggestions
    if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]; then
        git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" || echo -e "${red}❌ Falha ao clonar zsh-autosuggestions.${nc}"
        echo -e "${green}✅ zsh-autosuggestions clonado.${nc}"
    else
        echo -e "${yellow}ℹ️ zsh-autosuggestions já existe.${nc}"
    fi

    # zsh-completions
    if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-completions" ]; then
        git clone --depth=1 https://github.com/zsh-users/zsh-completions "${ZSH_CUSTOM}/plugins/zsh-completions" || echo -e "${red}❌ Falha ao clonar zsh-completions.${nc}"
        echo -e "${green}✅ zsh-completions clonado.${nc}"
    else
        echo -e "${yellow}ℹ️ zsh-completions já existe.${nc}"
    fi

    # zsh-syntax-highlighting
    if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ]; then
        git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" || echo -e "${red}❌ Falha ao clonar zsh-syntax-highlighting.${nc}"
        echo -e "${green}✅ zsh-syntax-highlighting clonado.${nc}"
    else
        echo -e "${yellow}ℹ️ zsh-syntax-highlighting já existe.${nc}"
    fi

    # fzf
    echo -e "\n${yellow}[+] Clonando e instalando fzf dentro da toolbox...${nc}\n"
    if [ ! -d "~/.fzf" ]; then
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf || echo -e "${red}❌ Falha ao clonar fzf.${nc}"
        ~/.fzf/install --all || echo -e "${red}❌ Falha ao instalar fzf.${nc}"
        echo -e "${green}✅ fzf clonado e instalado.${nc}"
    else
        echo -e "${yellow}ℹ️ fzf já existe.${nc}"
    fi

    echo -e "\n${green}--- Saindo da toolbox 'dev' ---${nc}"
EOF

# 6. Configurar Git (fora da toolbox, pode ser global para o usuário)
#    No Silverblue, é comum que a configuração do Git seja no home do usuário,
#    mas se você usa toolboxes para cada projeto, pode ser melhor configurar
#    o Git DENTRO de cada toolbox ou ter um .gitconfig global que é montado.
#    Por simplicidade, mantive a configuração global aqui.
echo -e "\n${yellow}[+] Configurando Git globalmente...${nc}\n"
read -rep "Digite seu email para Git: " git_email
read -rep "Digite seu nome para Git: " git_name
git config --global user.email "${git_email}"
git config --global user.name "${git_name}"
echo -e "${green}✅ Configurações globais do Git salvas.${nc}"

echo -e "\n${green}✅ Script de configuração concluído!${nc}"
echo -e "${yellow}✨ Lembre-se de reiniciar seu computador para aplicar as atualizações do sistema base (rpm-ostree), se houver.${nc}"
echo -e "${yellow}✨ Para usar as ferramentas e plugins, entre na sua toolbox (ex: 'toolbox enter dev').${nc}"
