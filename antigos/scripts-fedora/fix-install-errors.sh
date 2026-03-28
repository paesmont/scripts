#!/bin/bash
# fix-install-errors.sh
# Corrige os problemas identificados no install.log

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

log_info "Iniciando correções dos erros de instalação..."

# 1. Development Tools
log_info "1/5: Instalando Development Tools..."
if sudo dnf groupinstall "Development Tools" -y 2>/dev/null; then
    log_info "Development Tools instalado com sucesso!"
else
    log_warn "Tentando método alternativo..."
    sudo dnf install @development-tools -y || log_error "Falhou. Pule se não precisar."
fi

# 2. eza (via cargo)
log_info "2/5: Instalando eza via cargo..."
if command -v cargo &> /dev/null; then
    if ! command -v eza &> /dev/null; then
        cargo install eza
        log_info "eza instalado! (estará em ~/.cargo/bin/eza)"
        log_info "Adicione ao PATH: export PATH=\"\$HOME/.cargo/bin:\$PATH\""
    else
        log_info "eza já está instalado!"
    fi
else
    log_error "Cargo não encontrado. Instale Rust primeiro: sudo dnf install rust cargo"
fi

# 3. mozilla-fira-mono-fonts (corrigir nome)
log_info "3/5: Instalando fonte Fira..."
sudo dnf install -y mozilla-fira-sans-fonts || log_warn "Fonte não encontrada, mas você já tem fira-code-fonts"

# 4. vkd3d (buscar nome correto)
log_info "4/5: Instalando vkd3d..."
if sudo dnf install -y vkd3d 2>/dev/null; then
    log_info "vkd3d instalado!"
elif sudo dnf install -y mingw64-vkd3d 2>/dev/null; then
    log_info "mingw64-vkd3d instalado (alternativa)!"
else
    log_warn "vkd3d não encontrado. Pode não ser necessário se você não usa Wine/Proton."
fi

# 5. Verificar se precisa asdf (Ruby)
log_info "5/5: Verificando Ruby/asdf..."
if command -v ruby &> /dev/null; then
    log_info "Ruby do sistema já instalado: $(ruby --version)"
    log_warn "Se precisar de versões múltiplas, instale asdf manualmente."
else
    log_info "Ruby não instalado. Se precisar:"
    echo "  sudo dnf install ruby ruby-devel"
    echo "  OU instale asdf: git clone --depth=1 https://github.com/asdf-vm/asdf.git ~/.asdf"
fi

log_info ""
log_info "======================================"
log_info "Correções concluídas!"
log_info "======================================"
log_info ""
log_info "Próximos passos:"
echo "  1. Logout/Login para aplicar mudanças"
echo "  2. Copiar configs do Hyprland: cp -r ~/backup/.config/hypr ~/.config/"
echo "  3. Testar Docker: docker run hello-world"
echo "  4. Verificar Node: node --version"
echo "  5. Verificar Rust: rustc --version"
log_info ""
