# fedora-wsl

Scripts para provisionar um ambiente de desenvolvimento em Fedora Linux.

Funciona em Fedora nativo e no WSL2. O nome do diretorio e historico; scripts exclusivos de WSL sao marcados com `[WSL]`.

## Estrutura

```text
fedora-wsl/
├── main.sh             # dispatcher CLI
├── lib/
│   └── utils.sh        # funcoes compartilhadas (logging, dnf, backup)
├── install/
│   ├── base.sh         # essenciais do sistema
│   ├── shell.sh        # Fish + Starship
│   ├── cli-tools.sh    # ripgrep, fd, bat, eza, fzf, zoxide, lazygit, yazi
│   ├── terminal.sh     # Alacritty
│   ├── dev-tools.sh    # git, gh, fnm, neovim, python
│   ├── dotfiles.sh     # clonar e linkar dotfiles
│   └── bootstrap.sh    # [WSL] instalar Fedora no WSL via wsl.exe
├── system/
│   ├── update.sh       # dnf upgrade + autoremove
│   ├── clean.sh        # limpar cache e logs antigos
│   └── ports.sh        # listar portas em escuta
├── utils/
│   ├── big-files.sh    # encontrar arquivos grandes
│   ├── open-folder.sh  # [WSL] abrir pasta no Explorer
│   └── vscode.sh       # [WSL] abrir VSCode no diretorio atual
└── wsl/
    ├── clipboard.sh    # [WSL] configurar clip.exe / Get-Clipboard
    └── mount-drives.sh # [WSL] listar drives Windows montados
```

## Uso rapido

No Fedora nativo ou WSL:

```bash
git clone https://github.com/bashln/scripts ~/scripts
cd ~/scripts/scripts/fedora-wsl
./main.sh install all
```

## Bootstrap do Fedora no WSL

No Windows, via PowerShell (detecta automaticamente a release mais recente):

```powershell
cd scripts\fedora-wsl\install
.\bootstrap.ps1
```

Ou de dentro do WSL:

```bash
./main.sh install bootstrap
```

## Comandos

### Instalacao

```bash
./main.sh install base         # essenciais + update do sistema
./main.sh install shell        # Fish + Starship
./main.sh install cli-tools    # ripgrep, fd, bat, eza, fzf, etc
./main.sh install terminal     # Alacritty
./main.sh install dev-tools    # git, gh, fnm, neovim, python
./main.sh install dotfiles     # clonar e configurar dotfiles
./main.sh install bootstrap    # [WSL] instalar Fedora no WSL
./main.sh install all          # executar sequencia completa
./main.sh install list         # listar sequencia de instalacao
./main.sh install dry-run      # mostrar o que seria executado
```

### Sistema

```bash
./main.sh system update        # atualizar pacotes
./main.sh system clean         # limpar cache e pacotes orfaos
./main.sh system ports         # listar portas abertas
```

### Utilitarios

```bash
./main.sh utils big-files      # encontrar arquivos grandes
./main.sh utils open-folder    # [WSL] abrir pasta no Explorer
./main.sh utils vscode         # [WSL] abrir VSCode no diretorio atual
```

### WSL

```bash
./main.sh wsl clipboard        # [WSL] configurar clipboard
./main.sh wsl mount-drives     # [WSL] listar discos Windows montados
```

## Fedora nativo vs WSL

Funciona em qualquer Fedora:

- `install/base`, `shell`, `cli-tools`, `terminal`, `dev-tools`, `dotfiles`
- `system/update`, `clean`, `ports`
- `utils/big-files`

Exclusivo de WSL (requer `wsl.exe`, `clip.exe` ou `explorer.exe`):

- `install/bootstrap` — instala Fedora no WSL pelo Windows
- `wsl/clipboard` — integracao com clip.exe / powershell Get-Clipboard
- `wsl/mount-drives` — lista drives Windows montados em /mnt/
- `utils/open-folder` — abre Explorer no diretorio atual
- `utils/vscode` — abre VSCode via `code` no WSL

## Requisitos

- Fedora Linux (nativo ou WSL2)
- `sudo` disponivel
- Para recursos `[WSL]`: Windows 10/11 com WSL2

## Observacoes

- `Alacritty` emite aviso se o pacote nao estiver disponivel no repositorio.
- `eza`, `yazi` e `lazygit` usam fallback por download direto quando o pacote dnf nao existe.
