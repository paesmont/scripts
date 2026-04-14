#!/bin/bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"

# --- Configuração ---
# Define onde os pacotes globais viverão na home do usuário
NPM_GLOBAL_DIR="$HOME/.npm-global"

main() {
    # 1. Verifica existência do npm
    if ! command -v npm >/dev/null 2>&1; then
        warn "npm não encontrado no PATH. Instale o nodejs/npm antes."
        return
    fi

    info "Configurando ambiente NPM Global (User Space)..."

    # 2. Cria o diretório se não existir
    if [ ! -d "$NPM_GLOBAL_DIR" ]; then
        mkdir -p "$NPM_GLOBAL_DIR"
        ok "Diretório $NPM_GLOBAL_DIR criado."
    fi

    # 3. Configura o prefixo do npm (Isso edita o ~/.npmrc)
    # Isso garante que futuros 'npm -g' saibam onde instalar sem precisar de sudo
    npm config set prefix "$NPM_GLOBAL_DIR"
    ok "Prefixo npm configurado para: $NPM_GLOBAL_DIR"

    # 4. Instalação dos Pacotes
    info "Instalando/atualizando LSPs e ferramentas de Dev..."

    # Removemos 'set +e' porque agora temos permissão, então SE falhar, é erro real (internet/versão)
    # Redirecionamos o output chato do npm para o log, mostrando apenas erros
    if npm -g install \
        typescript typescript-language-server \
        eslint_d \
        prettier \
        @vue/language-server \
        @angular/language-service \
        vscode-langservers-extracted \
        yaml-language-server \
        dockerfile-language-server-nodejs \
        pyright >>"$LOG_FILE" 2>&1; then

        ok "Pacotes npm globais instalados com sucesso."
    else
        fail "Falha ao instalar pacotes npm. Verifique o log."
        return 1
    fi

    # Verifica se o usuário usa Fish
    if [[ "$SHELL" == */fish ]]; then
        local fish_config="$HOME/.config/fish/config.fish"

        # Verifica se o arquivo existe
        if [[ -f "$fish_config" ]]; then
            # Verifica se já está configurado para não duplicar
            if ! grep -q "npm-global" "$fish_config"; then
                info "Configurando PATH no Fish Shell..."
                # Adiciona a linha de forma segura
                echo -e "\n# NPM Global Path" >>"$fish_config"
                echo "fish_add_path $HOME/.npm-global/bin" >>"$fish_config"
                ok "Fish config atualizado."
            else
                info "Fish já está configurado."
            fi
        fi
    fi

    # 5. Validação do PATH (Crucial para que o shell encontre os comandos)
    # Verifica se o binário está visível no PATH atual
    if [[ ":$PATH:" != *":$NPM_GLOBAL_DIR/bin:"* ]]; then
        warn "O diretório '$NPM_GLOBAL_DIR/bin' não está no seu PATH atual."
        warn "Adicione a seguinte linha ao seu .bashrc ou .zshrc:"
        warn "export PATH=\"$NPM_GLOBAL_DIR/bin:\$PATH\""
    fi
}

main "$@"
