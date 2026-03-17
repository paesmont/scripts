# Blueprint Estrutural - bashln-scripts

## Visao Geral do Projeto

**bashln-scripts** e uma colecao abrangente de scripts Bash para pos-instalacao e configuracao completa de ambientes Linux. O projeto automatiza a instalacao de ferramentas de desenvolvimento, linguagens de programacao, utilitarios e configuracoes pessoais, suportando multiplas distribuicoes Linux.

---

## Proposito Principal

O objetivo do projeto e facilitar a configuracao rapida e reprodutivel de novos ambientes de trabalho Linux, permitindo:

- Recriar rapidamente o ambiente de desenvolvimento completo
- Executar scripts individualmente ou em sequencia
- Evitar reinstalacoes desnecessarias atraves de idempotencia
- Manter scripts legiveis, simples e padronizados

---

## Distribuicoes Suportadas

### 1. Arch Linux / CachyOS

Diretorio: `scripts/arch/`

- Gerenciador de pacotes: pacman
- Suporte a AUR (via yay/paru)
- Suporte a Flatpak

### 2. Ubuntu / Pop!_OS

Diretorio: `scripts/apt/`

- Gerenciador de pacotes: APT
- Scripts para Pop!_OS e Ubuntu

### 3. Ubuntu WSL

Diretorio: `scripts/ubuntu-wsl/`

- Bootstrap e setup para WSL com Ubuntu
- Scripts de instalacao: base, shell, cli-tools, dev-tools, dotfiles

Diretorio: `go/ubuntu-wsl-bootstrap/`

- Aplicativo TUI Go (Bubble Tea) para gerenciamento

### 4. Fedora WSL

Diretorio: `go/fedora-wsl-bootstrap/`

- Bootstrap e setup para WSL com Fedora
- Aplicativo TUI Go (Bubble Tea) para gerenciamento
- Scripts de instalacao: base, shell, cli-tools, dev-tools, dotfiles

### 5. Fedora Atomic Desktop

Diretorios: `scripts/fedora-atomic-{variant}/` (onde {variant} é bazzite, silverblue, kinoite, nordic)

- Scripts de instalacao para variantes Fedora Atomic/Desktop Imutavel
- Suporte a detecção automática via VARIANT_ID em /etc/os-release

---

## Estrutura de Diretorios

```
bashln-scripts/
|
+-- README.md                    # Documentacao principal
+-- project.md                  # Planejamentos e objetivos do projeto
+-- current-state.md            # Estado atual do desenvolvimento
+-- blueprints.md                # Este arquivo
+-- go.mod                      # Modulo Go principal
+-- .prettierrc                 # Configuracao de formatting
|
+-- cmd/
|   +-- bashln-tui/            # Aplicativo TUI Go (Bubble Tea) - TUI principal
|       +-- main.go            # Entry point
|
+-- go/
|   +-- ubuntu-wsl-bootstrap/  # TUI Go para Ubuntu WSL
|   |   +-- main.go
|   |   +-- model.go
|   |   +-- views.go
|   |   +-- commands.go
|   |
|   +-- fedora-wsl-bootstrap/  # TUI Go para Fedora WSL
|       +-- main.go
|       +-- model.go
|       +-- views.go
|       +-- commands.go
|
+-- internal/                   # Pacotes Go internos
|   +-- app/                   # Modelo e logica TUI (Bubble Tea)
|   |   +-- model.go           # Estado da aplicacao
|   |   +-- distro.go          # Deteccao de distribuicao
|   |   +-- logrotate.go       # Rotacao de logs
|   |   +-- model_test.go      # Testes
|   |
|   +-- runner/                # Executor de scripts com streaming
|   |   +-- runner.go
|   |   +-- runner_test.go
|   |
|   +-- scripts/               # Descoberta e manifest de scripts
|       +-- discovery.go       # Descobrir scripts disponiveis
|       +-- discovery_test.go
|       +-- manifest.go        # Definicao de metadata de scripts
|
+-- docs/
|   +-- EQUIVALENCES.md         # Tabela comparativa pacman vs dnf
|   +-- MIGRATION.md            # Guia migracao Arch -> Fedora
|   +-- planning/               # Documentacao de planejamento
|
+-- scripts/                    # Scripts organizados por distribuicao (Bash)
|   +-- arch/                  # Scripts Arch Linux
|   |   +-- install.sh         # Orquestrador principal
|   |   +-- update.sh          # Atualizacao
|   |   +-- full-update.sh     # Atualizacao completa
|   |   +-- lib/
|   |   |   +-- utils.sh      # Biblioteca core (pacman/AUR/funcoes de ajudante)
|   |   +-- assets/
|   |   |   +-- install-*.sh  # Scripts individuais de instalacao
|   |   +-- backup_scripts/   # Scripts de backup/legado (movido para antigos/)
|   |
|   +-- apt/                   # Scripts Ubuntu/Pop!_OS
|   |   +-- install.sh        # Instalador principal
|   |   +-- update.sh         # Atualizacao
|   |   +-- clean.sh          # Limpeza
|   |   +-- assets/           # Scripts e dotfiles
|   |
|   +-- fedora/                # Scripts Fedora regular (não-Atomic)
|   |   +-- install.sh        # Instalador principal
|   |   +-- lib/
|   |   |   +-- utils.sh      # Biblioteca core (dnf/funcoes de ajudante)
|   |   +-- assets/
|   |   |   +-- *.sh          # Scripts individuais
|   |
|   +-- fedora-atomic-bazzite/     # Scripts para Fedora Atomic Bazzite
|   |   +-- install.sh        # Instalador principal
|   |
|   +-- fedora-atomic-silverblue/  # Scripts para Fedora Atomic Silverblue
|   |   +-- install.sh        # Instalador principal
|   |
|   +-- fedora-atomic-kinoite/     # Scripts para Fedora Atomic Kinoite
|   |   +-- install.sh        # Instalador principal
|   |
|   +-- fedora-atomic-nordic/      # Scripts para Fedora Atomic Nordic
|   |   +-- install.sh        # Instalador principal
|   |
+-- antigos/                   # Arquivos antigos e desatualizados
|   +-- arch/                 # Scripts Arch antigos
|   +-- scripts-fedora/       # Scripts Fedora antigos
|   +-- powershell/           # Scripts PowerShell antigos
|   +-- wsl-binaries/         # Binarios wsl-bootstrap antigos
|   +-- automate_trello_to_git/
```
bashln-scripts/
|
+-- README.md                    # Documentacao principal
+-- project.md                  # Planejamentos e objetivos do projeto
+-- current-state.md            # Estado atual do desenvolvimento
+-- blueprints.md                # Este arquivo
+-- go.mod                      # Modulo Go principal
+-- .prettierrc                 # Configuracao de formatting
|
+-- cmd/
|   +-- bashln-tui/            # Aplicativo TUI Go (Bubble Tea)
|       +-- main.go            # Entry point
|
+-- internal/                   # Pacotes Go internos
|   +-- app/                   # Modelo e logica TUI
|   +-- runner/                # Executor de scripts
|   +-- scripts/                # Descoberta e parsing de scripts
|
+-- docs/
|   +-- EQUIVALENCES.md         # Tabela comparativa pacman vs dnf
|   +-- MIGRATION.md            # Guia migracao Arch -> Fedora
|   +-- planning/               # Documentacao de planejamento
|
+-- scripts/                    # Scripts organizados por distribuicao
|   +-- arch/                  # Scripts Arch Linux
|   |   +-- install.sh         # Orquestrador principal
|   |   +-- update.sh          # Atualizacao
|   |   +-- full-update.sh     # Atualizacao completa
|   |   +-- lib/
|   |   |   +-- utils.sh      # Biblioteca core (pacman/AUR)
|   |   +-- assets/
|   |   |   +-- install-*.sh  # Scripts individuais
|   |   +-- backup_scripts/   # Scripts de backup/legado (movido para antigos/)
|   |
|   +-- apt/                   # Scripts Ubuntu/Pop!_OS
|   |   +-- install.sh        # Instalador principal
|   |   +-- update.sh         # Atualizacao
|   |   +-- clean.sh          # Limpeza
|   |   +-- assets/           # Scripts e dotfiles
|   |
|   +-- ubuntu-wsl/            # Scripts Ubuntu WSL
|   |   +-- main.sh           # Dispatcher CLI
|   |   +-- go/ubuntu-wsl-bootstrap/  # Aplicativo TUI Go
|   |   +-- install/          # Scripts de instalacao
|   |   +-- system/           # Scripts de sistema
|   |   +-- utils/            # Utilitarios
|   |   +-- wsl/              # Scripts WSL
|   |   +-- lib/              # Biblioteca compartilhada
|   |
|   +-- fedora-wsl/           # Scripts Fedora WSL
|       +-- main.sh           # Dispatcher CLI
|       +-- go/fedora-wsl-bootstrap/     # Aplicativo TUI Go
|       +-- install/          # Scripts de instalacao
|       +-- system/           # Scripts de sistema
|       +-- utils/           # Utilitarios
|       +-- wsl/             # Scripts WSL
|       +-- lib/             # Biblioteca compartilhada
|
+-- antigos/                   # Arquivos antigos e desatualizados
|   +-- arch/                 # Scripts Arch antigos
|   +-- scripts-fedora/       # Scripts Fedora antigos
|   +-- powershell/           # Scripts PowerShell antigos
|   +-- wsl-binaries/         # Binarios wsl-bootstrap antigos
|   +-- automate_trello_to_git/
```

---

## Tecnologias e Ferramentas

### Gerenciadores de Pacotes

| Tecnologia | Descricao                        | Uso                 |
| ---------- | -------------------------------- | ------------------- |
| pacman     | Gerenciador Arch                 | scripts/arch        |
| dnf        | Gerenciador Fedora               | scripts/fedora      |
| yay/paru   | AUR Helper                       | scripts/arch        |
| copr       | Repositorios comunitarios Fedora | scripts/fedora-wsl/antigos/ |
| rpmfusion  | Repositorio extras Fedora        | scripts/fedora-wsl/antigos/ |
| flatpak    | Empacotamento universal          | Ambas distribuicoes |

### Ferramentas TUI

| Ferramenta  | Descricao                        | Uso                                 |
| ----------- | -------------------------------- | ----------------------------------- |
| Bubble Tea  | Framework TUI em Go              | cmd/bashln-tui (principal)         |
| Bubble Tea  | Framework TUI em Go              | go/*-wsl-bootstrap/ (WSL)          |

### Ferramentas de Container

| Ferramenta | Descricao         | Uso                            |
| ---------- | ----------------- | ------------------------------ |
| Distrobox  | Container Linux   | Executar pacotes AUR no Fedora |
| Podman     | Container runtime | Backend para Distrobox         |

### Linguagens e Runtimes Instalados

- Node.js (via install-nodejs.sh)
- Python (via install-python.sh)
- Rust/Cargo (via install-rust.sh)
- Ruby (via install-ruby.sh)
- Go (via install-go-tools.sh)
- PostgreSQL (via install-postgresql.sh)
- ASDF (version manager multi-linguagem)

### Aplicativos e Ferramentas

- **Terminal Emulators**: Alacritty, Kitty, Ghostty
- **Shells**: Zsh, Oh My Bash, Starship prompt
- **File Managers**: Yazi, Nautilus (GVFS)
- **Tools**: Git, LazyGit, Neovim, Emacs, VS Code, Tmux
- **Browsers**: Brave, Vivaldi, Microsoft Edge (Flatpak)
- **Multimedia**: VLC, Spotify (Flatpak), Steam
- **Development**: CMake, Node.js, NPM, Git, PostgreSQL
- **Fonts**: Fira Code, JetBrains Mono, Nerd Fonts

---

## Arquitetura de Scripts

### Biblioteca Core (lib/utils.sh)

Cada distribuicao possui sua propria implementacao da biblioteca utils.sh com funcoes equivalentes:

#### Funcoes de Logging

```bash
info()   # Log nivel INFO (azul)
ok()     # Log nivel OK (verde)
warn()   # Log nivel WARN (amarelo)
fail()   # Log nivel FAIL (vermelho)
die()    # Log erro e sai
```

#### Funcoes de Verificacao

```bash
# Fedora
ensure_package "pkg"              # Instala via DNF
ensure_group "grp"               # Instala grupo DNF
ensure_copr_package "repo" "pkg" # Habilita COPR + instala
ensure_flatpak_package "app"     # Instala Flatpak
ensure_rpmfusion                 # Habilita RPM Fusion
ensure_cargo_package "pkg"       # Instala via Cargo
ensure_npm_global "pkg"           # Instala via NPM global

# Arch
ensure_package "pkg"             # Instala via pacman
ensure_aur_package "pkg"         # Instala via AUR (yay)
ensure_flatpak_package "app"      # Instala Flatpak
```

### Orquestrador Principal (install-all.sh)

O script install-all.sh executa todos os scripts em uma ordem especifica e categorizada:

```bash
# Categorias de instalacao:
# 1. System Base & Core Utilities
# 2. RPM Fusion
# 3. Languages & Runtimes
# 4. Graphics, Multimedia & Drivers
# 5. Terminal Emulators & Shells
# 6. Networking & Storage
# 7. Browsers
# 8. Development Tools
# 9. Applications
# 10. Flatpak Applications
# 11. Desktop Environment Overrides
```

### Sistema de Logs

- **Log completo**: `install.log` - Todas as operacoes
- **Log de falhas**: `install-failures.log` - Apenas operacoes que falharam
- **Timestamp**: Formato `YYYY-MM-DD HH:MM:SS`
- **Cores**: Suporte a output colorido via ANSI ou Gum TUI

---

## Gerenciadores Dedicados (em antigos/)

Os seguintes gerenciadores foram movidos para o diretorio `antigos/`:

### COPR Manager (antigos/scripts-fedora/copr-manager.sh)

> ATENCAO: Este script foi movido para `antigos/scripts-fedora/`

Equivalente ao AUR helper do Arch, gerencia repositorios COPR:

```bash
./copr-manager.sh list              # Lista repositorios
./copr-manager.sh search <termo>   # Busca pacotes
./copr-manager.sh install <repo> <pkg>  # Instala pacote
./copr-manager.sh enable <repo>    # Habilita repositorio
./copr-manager.sh disable <repo>   # Desabilita repositorio
```

### Flatpak Manager (antigos/scripts-fedora/flatpak-manager.sh)

> ATENCAO: Este script foi movido para `antigos/scripts-fedora/`

Gerencia aplicacoes Flatpak:

```bash
./flatpak-manager.sh list          # Lista apps instalados
./flatpak-manager.sh search <termo>  # Busca no Flathub
./flatpak-manager.sh install <app>  # Instala app
./flatpak-manager.sh update         # Atualiza todos
./flatpak-manager.sh cleanup        # Remove nao utilizados
./flatpak-manager.sh size           # Espaco usado
```

### Distrobox Setup (antigos/scripts-fedora/distrobox-setup.sh)

> ATENCAO: Este script foi movido para `antigos/scripts-fedora/`

Cria container Arch Linux para pacotes AUR sem equivalente Fedora:

```bash
./distrobox-setup.sh create         # Cria container
./distrobox-setup.sh install <pkg>  # Instala pacote AUR
./distrobox-setup.sh export <app>   # Exporta app para host
./distrobox-setup.sh remove         # Remove container
```

---

## Idempotencia

Todos os scripts seguem o principio de idempotencia:

- Se pacote ja esta instalado -> apenas registra e pula
- Se repositorio ja foi clonado -> atualiza com git pull
- Se configuracao ja existe -> nada e sobrescrito

Isso permite executar os scripts multiplas vezes sem causar erros ou reinstalacoes desnecessarias.

---

## Filosofia do Projeto

1. **Idempotencia**: rodar 100 vezes deve dar o mesmo resultado
2. **Legibilidade**: codigo simples > "magico"
3. **Autonomia**: cada script faz uma coisa so
4. **Logs claros**: sempre saber o que foi feito e o que falhou
5. **Reprodutibilidade**: do zero ao ambiente pronto em minutos
6. **Multi-distro**: mesma logica, adaptada para cada gerenciador

---

## COPR Repositorios Utilizados (historico)

> ATENCAO: Estes repositorios eram utilizados pelos scripts em `antigos/scripts-fedora/`

| COPR           | Pacotes    | Descricao               |
| -------------- | ---------- | ----------------------- |
| atim/lazygit   | lazygit    | TUI Git client          |
| atim/yazi      | yazi       | Terminal file manager   |
| atim/starship  | starship   | Cross-shell prompt      |
| pgdev/ghostty  | ghostty    | Terminal emulator       |
| che/nerd-fonts | nerd-fonts | Fontes para programacao |

---

## Fluxo de Execucao Tipico

### Arch Linux

```bash
cd scripts/arch
chmod +x *.sh assets/*.sh

# Instalacao
./install.sh

# Atualizacao
./update.sh
```

### Ubuntu / Pop!_OS

```bash
cd scripts/apt

# Instalacao completa
./install.sh

# Atualizacao
./update.sh
```

### Ubuntu WSL

```bash
cd scripts/ubuntu-wsl/bootstrap-go
go run .

# Ou usar CLI direto
cd scripts/ubuntu-wsl
./main.sh install all
```

### Fedora WSL

```bash
cd scripts/fedora-wsl/bootstrap-go
go run .

# Ou usar CLI direto
cd scripts/fedora-wsl
./main.sh install all
```

---

## Documentacao

- **docs/EQUIVALENCES.md**: Tabela completa de equivalencias entre comandos pacman e dnf
- **docs/MIGRATION.md**: Guia detalhado de migracao do Arch para Fedora
- **docs/planning/**: Documentacao de planejamento do projeto
- **README.md**: Documentacao principal do projeto

---

## Contribuicao

Para adicionar novos scripts:

1. Criar branch: `git checkout -b feature/novo-script`
2. Adicionar script no diretorio da distribuicao (`scripts/<distro>/`)
3. Para Arch: adicionar ao array STEPS em `install.sh`
4. Para WSL: adicionar ao menu no TUI ou ao `main.sh`
5. Testar: executar script individualmente
6. Commit e pull request

---

## Licenca

MIT License - Use, modifique e compartilhe livremente.

---

## Fedora Atomic Desktop Support (Current State)

### Visao Geral

Suporte para detecção e execução de scripts em variantes Fedora Atomic Desktop (Bazzite, Silverblue, Kinoite, Nordic) integrado ao mecanismo existente de detecção de distribuição.

### Estado Atual

1. **Detecção de Variantes**: O sistema detecta VARIANT_ID em /etc/os-release e mapeia para diretórios específicos:
   - `bazzite` → `scripts/fedora-atomic-bazzite/`
   - `silverblue` → `scripts/fedora-atomic-silverblue/`
   - `kinoite` → `scripts/fedora-atomic-kinoite/`
   - `nordic` → `scripts/fedora-atomic-nordic/`

2. **Scripts Disponíveis**: Cada variante tem `install.sh` funcional e `lib/utils.sh` (copiado de `scripts/fedora/lib/`).

3. **Integração**: A detecção é feita pelo bashln-tui existente através de `resolveScriptsDir()` em `cmd/bashln-tui/main.go`.

### Estrutura de Diretorios Atual

```
scripts/
|   +-- arch/                  # Scripts Arch Linux
|   +-- apt/                   # Scripts Ubuntu/Pop!_OS
|   +-- fedora/                # Scripts Fedora regular
|   |
|   +-- fedora-atomic-bazzite/
|   |   +-- install.sh         # Instalador principal
|   |   +-- lib/utils.sh       # Biblioteca core (copiada de scripts/fedora/lib/)
|   |
|   +-- fedora-atomic-silverblue/
|   |   +-- install.sh
|   |   +-- lib/utils.sh
|   |
|   +-- fedora-atomic-kinoite/
|   |   +-- install.sh
|   |   +-- lib/utils.sh
|   |
|   +-- fedora-atomic-nordic/
|       +-- install.sh
|       +-- lib/utils.sh
```

### Implementacao Realizada

- `lib/utils.sh` criado em cada variante (copiado de `scripts/fedora/lib/utils.sh`)
- `install.sh` corrigido: variável `$variant` agora extraída do nome do diretório (remove prefixo `fedora-atomic-`)
- Funções `detectSystemDistro()` e `detectSystemVariant()` refatoradas em helper compartilhado `getOSReleaseValue()` em `cmd/bashln-tui/main.go`
- Diretórios `assets/` vazios removidos de todas as variantes

### Proximos Passos Planeados (Conforme Blueprint Original)

A implementação atual representa a "Fase 1: Fundação". Os próximos passos incluem:
1. Criação de TUI dedicada `cmd/fedora-atomic-tui/`
2. Implementação de gerenciadores de pacote (Flatpak, Homebrew, etc.)
3. Desenvolvimento de orquestrador com lógica de prioridade Bazzite
4. Adição de funcionalidade real aos scripts de instalação (atualmente placeholders)

### Metricas

- **~70 scripts de instalacao** no directorio assets (Arch)
- **~40 scripts de instalacao** no directorio assets (Ubuntu/Pop!_OS)
- **5 distribuicoes suportadas**: Arch, Ubuntu, Fedora, Fedora Atomic, Ubuntu WSL
- **1 implementacao TUI em Go**: cmd/bashln-tui (principal)
- **Planejado**: fedora-atomic-tui (nova TUI para Fedora Atomic)
