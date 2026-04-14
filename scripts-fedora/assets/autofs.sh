#!/bin/bash
# Flag para o install-all.sh saber que precisa de sudo
REQUIRES_ROOT=1 

set -euo pipefail
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Carrega a biblioteca de logs centralizada
source "$SCRIPTS_DIR/lib/utils.sh"

# --- Configuração ---
# Autoconfig EXT4 mounts for dev and 1TB
# Monta: /mnt/dev e /mnt/1TB
# Estratégia: Systemd Automount (On-demand)

# Labels e Dispositivos Candidatos
LABEL_DEV="${LABEL_DEV:-dev}"
LABEL_1TB="${LABEL_1TB:-1TB}"
DEV_DEV_CAND="${DEV_DEV_CAND:-/dev/sda1}"
DEV_1TB_CAND="${DEV_1TB_CAND:-/dev/sdb2}"

# Pontos de montagem
MP_DEV="/mnt/dev"
MP_1TB="/mnt/1TB"

# --- Helpers Locais ---
# Função die local adaptada para usar o fail da lib
die() {
  fail "$*"
  exit 1
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    die "Comando requerido não encontrado: $1"
  fi
}

# --- Checagens Iniciais ---

# Detecção do usuário real (pois estamos rodando como root via sudo)
# Se SUDO_USER não existir, assume que logou direto como root (fallback)
REAL_USER="${SUDO_USER:-$USER}"

if [[ "$REAL_USER" == "root" ]]; then
    warn "Executando como root puro. Symlinks serão criados em /root/."
fi

REAL_UID="$(id -u "$REAL_USER")"
REAL_GID="$(id -g "$REAL_USER")"
HOME_DIR="$(getent passwd "$REAL_USER" | cut -d: -f6)"

info "Configurando automount para usuário: $REAL_USER ($REAL_UID)"

require_cmd blkid
require_cmd lsblk
require_cmd findmnt
require_cmd systemctl
require_cmd mount

# --- Helpers de Disco ---
dev_by_label() { blkid -t "LABEL=$1" -o device 2>/dev/null | head -n1 || true; }
uuid_of()      { blkid -s UUID -o value "$1" 2>/dev/null || true; }
fstype_of()    { lsblk -ndo FSTYPE "$1" 2>/dev/null || true; }

# --- Localizar Partições ---

# Processar DEV
DEV_DEV="$(dev_by_label "$LABEL_DEV")"
[[ -z "$DEV_DEV" ]] && DEV_DEV="$DEV_DEV_CAND"

[[ -b "$DEV_DEV" ]] || die "Partição 'dev' não encontrada (LABEL=${LABEL_DEV} ou ${DEV_DEV_CAND})."
[[ "$(fstype_of "$DEV_DEV")" == "ext4" ]] || die "Esperado ext4 em $DEV_DEV."
UUID_DEV="$(uuid_of "$DEV_DEV")"
[[ -n "$UUID_DEV" ]] || die "Sem UUID para $DEV_DEV."

info "Detectado 'dev': $DEV_DEV ($UUID_DEV)"

# Processar 1TB
DEV_1TB="$(dev_by_label "$LABEL_1TB")"
[[ -z "$DEV_1TB" ]] && DEV_1TB="$DEV_1TB_CAND"

[[ -b "$DEV_1TB" ]] || die "Partição '1TB' não encontrada (LABEL=${LABEL_1TB} ou ${DEV_1TB_CAND})."
[[ "$(fstype_of "$DEV_1TB")" == "ext4" ]] || die "Esperado ext4 em $DEV_1TB."
UUID_1TB="$(uuid_of "$DEV_1TB")"
[[ -n "$UUID_1TB" ]] || die "Sem UUID para $DEV_1TB."

info "Detectado '1TB': $DEV_1TB ($UUID_1TB)"

# --- Preparação do Sistema ---

info "Limpando montagens antigas..."
mkdir -p "$MP_DEV" "$MP_1TB"

# Systemctl stop silenciado
systemctl stop mnt-dev.automount mnt-dev.mount 2>/dev/null || true
systemctl stop mnt-1TB.automount mnt-1TB.mount 2>/dev/null || true

umount -l "$MP_DEV" 2>/dev/null || true
umount -l "$MP_1TB" 2>/dev/null || true

# --- Manipulação do FSTAB ---

EXT4_OPTS="defaults,noatime,x-systemd.automount,nofail"
FSTAB_LINE_DEV="UUID=${UUID_DEV} ${MP_DEV} ext4 ${EXT4_OPTS} 0 2"
FSTAB_LINE_1TB="UUID=${UUID_1TB} ${MP_1TB} ext4 ${EXT4_OPTS} 0 2"

FSTAB="/etc/fstab"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP="/etc/fstab.bak-${TS}"
TMP="$(mktemp)"

cp -a "$FSTAB" "$BACKUP"
info "Backup do fstab criado: $BACKUP"

# AWK Magic: Remove referências antigas aos UUIDs ou Mountpoints
awk -v uuid1="$UUID_DEV" -v uuid2="$UUID_1TB" -v mp1="$MP_DEV" -v mp2="$MP_1TB" '
BEGIN { IGNORECASE = 1 }
{
  # Se a linha contém o UUID ou o Mount Point, pula (deleta)
  if ($0 ~ uuid1 || $0 ~ uuid2 || $2 == mp1 || $2 == mp2) next;
  print $0
}
' "$FSTAB" >"$TMP"

# Adiciona as novas linhas
{
  echo ""
  echo "# >>> auto-added by autofs-fedora-ext4 (${TS})"
  echo "$FSTAB_LINE_DEV"
  echo "$FSTAB_LINE_1TB"
  echo "# <<<"
} >>"$TMP"

# --- Validação e Aplicação ---

info "Verificando integridade do novo fstab..."
if ! findmnt --verify -F "$TMP" >> "$LOG_FILE" 2>&1; then
  rm -f "$TMP"
  die "findmnt --verify falhou. O fstab original foi mantido intacto."
fi

# Commit
mv -f "$TMP" "$FSTAB"
systemctl daemon-reload

# --- Teste de Montagem ---

info "Testando montagem (mount -a)..."
if ! mount -a >> "$LOG_FILE" 2>&1; then
  warn "mount -a falhou! Restaurando backup..."
  cp -af "$BACKUP" "$FSTAB"
  systemctl daemon-reload
  die "Erro crítico ao montar. Rollback aplicado com sucesso."
fi

# Trigger do automount
ls "$MP_DEV" >/dev/null 2>&1 || true
ls "$MP_1TB" >/dev/null 2>&1 || true

# --- Symlinks na Home ---

info "Atualizando symlinks em $HOME_DIR..."
ln -sfn "$MP_DEV" "$HOME_DIR/dev"
ln -sfn "$MP_1TB" "$HOME_DIR/1TB"

# Correção de permissão crítica: O symlink foi criado pelo root, 
# precisamos garantir que o dono seja o usuário.
chown -h "$REAL_UID:$REAL_GID" "$HOME_DIR/dev" "$HOME_DIR/1TB"

ok "Configuração de disco concluída. Acesso em ~/dev e ~/1TB"
