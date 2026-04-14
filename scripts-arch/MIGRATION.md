# MIGRATION: scripts-arch -> scripts-dnf

Este repositório foi refatorado para Fedora (Workstation/Silverblue) mantendo a estrutura modular original.

## Premissas

- **Fedora Workstation** usa `dnf` para pacotes do host.
- **Fedora Silverblue** usa `rpm-ostree` para pacotes em camadas (requer reboot para aplicar).
- **Flatpak** é preferido para aplicações GUI quando faz sentido.
- **Toolbox/Distrobox** são preferidos para ambientes de desenvolvimento isolados.

## Diferenças-chave

- **Gerenciador de pacotes**: `pacman/yay/paru` foram removidos e substituídos por `dnf` ou `rpm-ostree` (detecção automática no `lib/utils.sh`).
- **AUR**: não existe no Fedora. Scripts que dependiam de AUR agora usam Flatpak, instalação via git, ou contêm `TODO` explícito.
- **Atualizações do sistema** (`update.sh` e `full-update.sh`): agora usam `dnf upgrade --refresh` ou `rpm-ostree upgrade`, além de limpeza com `dnf autoremove/clean` ou `rpm-ostree cleanup`.
- **Pacotes e nomes**: vários nomes foram ajustados (ex.: `go` -> `golang`, `python` -> `python3`, `vulkan-icd-loader` -> `vulkan-loader`).
- **Fontes e Nerd Fonts**: fontes oficiais foram mapeadas para pacotes Fedora; Nerd Fonts ficam como instalação manual (ver TODO).

## TODOs explícitos

Quando o mapeamento não é confiável em Fedora, os scripts incluem `TODO` com explicação (ex.: Ghostty, Yazi, resvg). Isso evita suposições erradas e preserva a intenção original.

## Observações de uso

- Em Silverblue, instalações via `rpm-ostree` exigem reboot após a execução.
- Para aplicativos GUI, valide se o Flathub já está configurado (use `install-flatpak-flathub.sh`).
