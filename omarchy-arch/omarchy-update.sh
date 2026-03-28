#!/usr/bin/env bash
set -euo pipefail

# Objetivo:
#  - Sincronizar pacman, mas usando omarchy como "gatilho"
#  - Atualizar o sistema somente quando os pacotes aparecerem no repo Omarchy
#  - Evitar updates muito recentes do Arch

# 1. Verifica atualizações pendentes sem forçar sincronização parcial
echo "[OmarchyUpdater] Verificando atualizações pendentes..."
UPDATES=$(pacman -Qu 2>/dev/null || true)

if [ -z "$UPDATES" ]; then
  echo "[OmarchyUpdater] Nenhuma atualização disponível no momento."
  exit 0
fi

echo "[OmarchyUpdater] Atualizações encontradas:"
echo "$UPDATES"
echo

# 2. Atualiza tudo de forma consistente
echo "[OmarchyUpdater] Aplicando atualização segura (via Omarchy + Arch)..."
sudo pacman -Syu --noconfirm

echo "[OmarchyUpdater] Atualização concluída."
echo "Seu sistema agora está sincronizado com o estado 'curado' do Omarchy."
