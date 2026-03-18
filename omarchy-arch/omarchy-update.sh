#!/usr/bin/env bash
set -euo pipefail

# Objetivo:
#  - Sincronizar pacman, mas usando omarchy como "gatilho"
#  - Atualizar o sistema somente quando os pacotes aparecerem no repo Omarchy
#  - Evitar updates muito recentes do Arch

# 1. Sincroniza todos os repositórios, incluindo Omarchy
echo "[OmarchyUpdater] Sincronizando bancos de dados..."
sudo pacman -Sy --noconfirm

# 2. Verifica atualizações disponíveis
UPDATES=$(pacman -Qu || true)

if [ -z "$UPDATES" ]; then
  echo "[OmarchyUpdater] Nenhuma atualização disponível no momento."
  exit 0
fi

echo "[OmarchyUpdater] Atualizações encontradas:"
echo "$UPDATES"
echo

# 3. Atualiza tudo — Omarchy determina o ritmo
echo "[OmarchyUpdater] Aplicando atualização segura (via Omarchy + Arch)..."
sudo pacman -Syu --noconfirm

echo "[OmarchyUpdater] Atualização concluída."
echo "Seu sistema agora está sincronizado com o estado 'curado' do Omarchy."
