#!/usr/bin/env bash
set -euo pipefail

# =========[ CONFIG EDITÁVEL ]=========
BACKUP_MNT="/run/media/lm/dev" # SSD de backup
BACKUP_ROOT_DIR_NAME="arch-migrate"
# =====================================

RED=$'\033[31m'
GRN=$'\033[32m'
YLW=$'\033[33m'
BLU=$'\033[34m'
CLR=$'\033[0m'

die() {
  echo "${RED}[ERRO]${CLR} $*" >&2
  exit 1
}
log() { echo "${GRN}[OK]${CLR} $*"; }
info() { echo "${BLU}[INFO]${CLR} $*"; }
warn() { echo "${YLW}[AVISO]${CLR} $*"; }

require() {
  command -v "$1" >/dev/null 2>&1 || die "Comando obrigatório não encontrado: $1"
}

timestamp() { date +%F-%H%M%S; }

detect_backup_dir() {
  local subdir
  subdir="${HOSTNAME}-$(date +%F)"
  echo "${BACKUP_MNT}/${BACKUP_ROOT_DIR_NAME}/${subdir}"
}

assert_mountpoint() {
  [[ -d "$BACKUP_MNT" ]] || die "Ponto de montagem não existe: $BACKUP_MNT"
  [[ -w "$BACKUP_MNT" ]] || die "Sem permissão de escrita em: $BACKUP_MNT"
}

backup_repo_pkglist() {
  local outdir="$1"

  # Pacotes explicitamente instalados (repo)
  # -Qqe: explicit; -Qqm: foreign (AUR). Vamos separar.
  pacman -Qqe >"${outdir}/pkglist_raw.txt"
  pacman -Qqm >"${outdir}/aurlist.txt" || true

  # Filtra para garantir apenas pacotes de repo existentes (evita falhas no restore)
  pacman -Slq | sort -u >"${outdir}/repo_available_all.txt"
  sort -u "${outdir}/pkglist_raw.txt" >"${outdir}/pkglist_raw_sorted.txt"
  comm -12 "${outdir}/pkglist_raw_sorted.txt" "${outdir}/repo_available_all.txt" >"${outdir}/pkglist.txt"

  # Remove metapacotes comuns que variam entre distros derivadas
  sed -i '/^base$/d;/^base-devel$/d;/^linux$/d;/^linux-headers$/d;/^endeavouros-/d' "${outdir}/pkglist.txt" || true

  rm -f "${outdir}/pkglist_raw_sorted.txt" "${outdir}/repo_available_all.txt"
  log "Listas salvas: pkglist.txt (repo), aurlist.txt (AUR)"
}

backup_flatpak_list() {
  local outdir="$1"
  if command -v flatpak >/dev/null 2>&1; then
    flatpak list --app --columns=application >"${outdir}/flatpak.txt" || true
    log "Lista Flatpak salva (se houver): flatpak.txt"
  else
    info "Flatpak não encontrado; pulando."
  fi
}

backup_services() {
  local outdir="$1"
  # Serviços de sistema habilitados
  systemctl list-unit-files --type=service --state=enabled --no-legend | awk '{print $1}' >"${outdir}/systemd_system_enabled.txt" || true
  # Serviços de usuário habilitados
  systemctl --user list-unit-files --type=service --state=enabled --no-legend | awk '{print $1}' >"${outdir}/systemd_user_enabled.txt" || true
  log "Listas de serviços systemd salvas."
}

backup_configs() {
  local outdir="$1"
  mkdir -p "${outdir}/etc"
  # Alguns configs úteis
  for f in /etc/pacman.conf /etc/makepkg.conf; do
    [[ -f "$f" ]] && sudo cp -a "$f" "${outdir}/etc/" || true
  done

  # Mirrorlists (se existirem)
  [[ -f /etc/pacman.d/mirrorlist ]] && sudo cp -a /etc/pacman.d/mirrorlist "${outdir}/etc/" || true

  log "Configs do /etc relevantes salvas (quando existentes)."
}

backup_home() {
  local outdir="$1"
  local user_home="$HOME"

  # Excluir caches/pastas pesadas. Ajuste à vontade.
  local excludes=(
    "--exclude=.cache/"
    "--exclude=.local/share/Trash/"
    "--exclude=.local/share/Steam/"
    "--exclude=.local/share/flatpak/"
    "--exclude=.npm/_cacache/"
    "--exclude=.cargo/registry/"
    "--exclude=**/node_modules/"
    "--exclude=Downloads/"
    "--exclude=Videos/"
    "--exclude=Music/"
    "--exclude=Pictures/"
    "--exclude=*.iso"
  )

  mkdir -p "${outdir}/home"
  rsync -aHAX --info=progress2 --numeric-ids "${excludes[@]}" "$user_home/" "${outdir}/home/"
  log "Backup da HOME concluído em ${outdir}/home/"

  # --- Snapshot de dotfiles: configurável via SNAPSHOT_MODE=off|minimal|full ---
  #  off     -> não faz snapshot (recomendado; rsync já copiou tudo)
  #  minimal -> só dotfiles leves (.bashrc, .zshrc, .profile, .gitconfig, .editorconfig)
  #  full    -> inclui .config (pode ser MUITO lento e é redundante)
  local SNAPSHOT_MODE="${SNAPSHOT_MODE:-minimal}"
  local snapshot="${outdir}/dotfiles-snapshot.tar.zst"

  case "$SNAPSHOT_MODE" in
  off)
    info "Snapshot de dotfiles DESLIGADO (SNAPSHOT_MODE=off)."
    ;;
  minimal)
    local include=(.bashrc .zshrc .profile .gitconfig .editorconfig)
    local present=()
    for f in "${include[@]}"; do [[ -e "$user_home/$f" ]] && present+=("$f"); done
    if ((${#present[@]} > 0)); then
      tar --use-compress-program="zstd -19 -T0" \
        --checkpoint=5000 --checkpoint-action=echo="tar: %(read)s entradas..." \
        -cf "$snapshot" -C "$user_home" "${present[@]}"
      log "Snapshot minimal salvo em $(basename "$snapshot")"
    else
      info "Nenhum dotfile leve para snapshot (ok)."
    fi
    ;;
  full)
    local include=(.bashrc .zshrc .profile .gitconfig .config)
    local present=()
    for f in "${include[@]}"; do [[ -e "$user_home/$f" ]] && present+=("$f"); done
    if ((${#present[@]} > 0)); then
      tar --use-compress-program="zstd -19 -T0" \
        --checkpoint=10000 --checkpoint-action=echo="tar: %(read)s entradas..." \
        -cf "$snapshot" -C "$user_home" "${present[@]}"
      log "Snapshot FULL salvo em $(basename "$snapshot")"
    else
      info "Nada para snapshot full (ok)."
    fi
    ;;
  *)
    warn "SNAPSHOT_MODE desconhecido: $SNAPSHOT_MODE (usando 'minimal')."
    ;;
  esac
}

do_backup() {
  assert_mountpoint
  require pacman
  require rsync
  local bdir
  bdir="$(detect_backup_dir)"
  mkdir -p "$bdir"

  info "Iniciando BACKUP em: $bdir"
  backup_repo_pkglist "$bdir"
  backup_flatpak_list "$bdir"
  backup_services "$bdir"
  backup_configs "$bdir"
  backup_home "$bdir"

  log "Backup finalizado! Pasta: $bdir"
  echo
  echo "👉 Guarde este caminho. Você vai usá-lo no restore:"
  echo "   $bdir"
}

install_paru_if_needed() {
  if ! command -v paru >/dev/null 2>&1; then
    info "Instalando paru (helper AUR)…"
    sudo pacman -S --needed --noconfirm base-devel git
    rm -rf /tmp/paru
    git clone --depth=1 https://aur.archlinux.org/paru.git /tmp/paru
    (cd /tmp/paru && makepkg -si --noconfirm)
    log "paru instalado."
  else
    info "paru já presente."
  fi
}

restore_repo_pkgs() {
  local bdir="$1"
  if [[ -f "${bdir}/pkglist.txt" ]]; then
    info "Instalando pacotes de repositório (pkglist.txt)…"
    sudo pacman -Syu --noconfirm
    # Instala ignorando pacotes que falharem por inexistência (filtramos antes, mas por segurança)
    sudo pacman -S --needed --noconfirm $(<"${bdir}/pkglist.txt") || warn "Alguns pacotes podem não existir no CachyOS; siga instalando."
    log "Repo packages restaurados."
  else
    warn "pkglist.txt não encontrado; pulando pacotes de repositório."
  fi
}

restore_aur_pkgs() {
  local bdir="$1"
  if [[ -f "${bdir}/aurlist.txt" ]]; then
    install_paru_if_needed
    info "Instalando pacotes AUR (aurlist.txt)…"
    paru -S --needed --noconfirm - <"${bdir}/aurlist.txt" || warn "Alguns AUR podem ter mudado de nome/estado."
    log "AUR packages restaurados."
  else
    info "Nenhum aurlist.txt para restaurar."
  fi
}

restore_flatpak() {
  local bdir="$1"
  if [[ -f "${bdir}/flatpak.txt" ]]; then
    if command -v flatpak >/dev/null 2>&1; then
      info "Restaurando apps Flatpak…"
      # Garante remotes padrão
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
      xargs -r -a "${bdir}/flatpak.txt" -I {} flatpak install -y flathub {}
      log "Flatpaks restaurados."
    else
      warn "Flatpak não instalado; pulando restauração de Flatpak."
    fi
  fi
}

restore_home() {
  local bdir="$1"
  if [[ -d "${bdir}/home" ]]; then
    info "Restaurando HOME (rsync)…"
    rsync -aHAX --info=progress2 --numeric-ids "${bdir}/home/" "$HOME/"
    log "HOME restaurada."
  elif [[ -f "${bdir}/dotfiles-snapshot.tar.gz" ]]; then
    info "Restaurando snapshot de dotfiles (tar)…"
    tar -xzf "${bdir}/dotfiles-snapshot.tar.gz" -C "$HOME"
    log "Dotfiles restaurados do snapshot."
  else
    warn "Nenhum backup da HOME/dotfiles encontrado."
  fi
}

restore_services() {
  local bdir="$1"
  # Serviços de sistema
  if [[ -f "${bdir}/systemd_system_enabled.txt" ]]; then
    info "Reabilitando serviços de SISTEMA…"
    while read -r svc; do
      [[ -n "$svc" ]] || continue
      sudo systemctl enable "$svc" || warn "Falhou habilitar $svc (talvez não exista no CachyOS)."
    done <"${bdir}/systemd_system_enabled.txt"
    log "Serviços de sistema processados."
  fi
  # Serviços de usuário
  if [[ -f "${bdir}/systemd_user_enabled.txt" ]]; then
    info "Reabilitando serviços de USUÁRIO…"
    while read -r svc; do
      [[ -n "$svc" ]] || continue
      systemctl --user enable "$svc" || warn "Falhou habilitar (user) $svc."
    done <"${bdir}/systemd_user_enabled.txt"
    log "Serviços de usuário processados."
  fi
}

restore_etc_snippets() {
  local bdir="$1"
  if [[ -d "${bdir}/etc" ]]; then
    info "Copiando trechos úteis de /etc (sem sobrescrever à força)…"
    for f in pacman.conf makepkg.conf; do
      [[ -f "${bdir}/etc/${f}" ]] && sudo cp -n "${bdir}/etc/${f}" "/etc/${f}" || true
    done
    [[ -f "${bdir}/etc/mirrorlist" ]] && sudo cp -n "${bdir}/etc/mirrorlist" "/etc/pacman.d/mirrorlist" || true
    log "Arquivos de /etc copiados (modo conservador). Compare com meld/diff se quiser fundir configs."
  fi
}

do_restore() {
  [[ $# -ge 1 ]] || die "Use: $0 restore /caminho/do/backup"
  local bdir="$1"
  [[ -d "$bdir" ]] || die "Diretório de backup não encontrado: $bdir"

  require pacman
  info "Iniciando RESTORE a partir de: $bdir"

  restore_repo_pkgs "$bdir"
  restore_aur_pkgs "$bdir"
  restore_flatpak "$bdir"
  restore_home "$bdir"
  restore_services "$bdir"
  restore_etc_snippets "$bdir"

  log "Restore concluído!"
  echo "⚠️  Reinicie a sessão (ou o sistema) para garantir que serviços e shells peguem as novas configs."
}

usage() {
  cat <<EOF
Uso: $0 <backup|restore> [CAMINHO_BACKUP]

  backup               Executa o backup no SSD (${BACKUP_MNT})
  restore <caminho>    Restaura a partir do diretório de backup gerado

Exemplo:
  $0 backup
  # Anote o caminho impresso, algo como:
  # ${BACKUP_MNT}/${BACKUP_ROOT_DIR_NAME}/$(hostname)-$(date +%F)

  $0 restore ${BACKUP_MNT}/${BACKUP_ROOT_DIR_NAME}/MEU-HOST-AAAA-MM-DD
EOF
}

main() {
  local action="${1:-}"
  case "$action" in
  backup)
    assert_mountpoint
    do_backup
    ;;
  restore)
    shift || true
    do_restore "$@"
    ;;
  *)
    usage
    exit 1
    ;;
  esac
}

main "$@"
