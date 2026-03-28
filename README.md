# bshln-scripts

Colecao de scripts Bash para pos-instalacao e setup completo de ambiente Linux.
Suporta **Arch Linux**, **Fedora Workstation**, e **Pop!_OS/Ubuntu**.

Automatiza a instalacao de ferramentas de desenvolvimento, linguagens, utilitarios e configuracoes pessoais.

Cada script foi projetado para ser **idempotente** -- voce pode executa-los quantas vezes quiser sem quebrar o sistema ou repetir tarefas desnecessarias.

---

## Objetivo

Facilitar a configuracao de novos sistemas e ambientes de trabalho de forma segura, reprodutivel e modular.

Esses scripts foram escritos para:

- Recriar rapidamente o ambiente de desenvolvimento completo.
- Serem executados individualmente ou em sequencia.
- Evitar reinstalacoes desnecessarias.
- Ser legiveis, simples e padronizados.

---

## Estrutura do Projeto

```
bshln-scripts/
├── README.md
├── scripts/arch/              # Scripts para Arch Linux / CachyOS
│   ├── install-all.sh         # Orquestrador principal
│   ├── update.sh              # Atualizacao leve
│   ├── full-update.sh         # Atualizacao completa
│   ├── lib/
│   │   └── utils.sh           # Biblioteca core (pacman/yay)
│   └── assets/
│       └── install-*.sh       # Scripts individuais
│
├── scripts/fedora-wsl/        # Scripts para Fedora Workstation 41+
│   ├── install-all.sh         # Orquestrador principal
│   ├── update.sh              # Atualizacao leve
│   ├── full-update.sh         # Atualizacao completa
│   ├── copr-manager.sh        # Gerenciador de repos COPR
│   ├── flatpak-manager.sh     # Gerenciador de apps Flatpak
│   ├── distrobox-setup.sh     # Container Arch para pacotes AUR
│   ├── system-maintenance.sh  # Manutencao completa do sistema
│   ├── lib/
│   │   └── utils.sh           # Biblioteca core (dnf/copr)
│   └── assets/
│       └── install-*.sh       # Scripts individuais
│
├── scripts/apt/               # Scripts para Pop!_OS / Ubuntu
│   ├── post-install-apt.sh
│   ├── pop-update.sh
│   ├── pop-clean.sh
│   └── npm-install-fnm-rootless.sh
│
└── docs/
    ├── EQUIVALENCES.md        # Tabela pacman -> dnf
    └── MIGRATION.md           # Guia de migracao Arch -> Fedora
```

---

## Como Usar

## Uso da TUI (MVP)

O `pomo-tui` atual opera sobre `scripts/arch`.

Execute a interface TUI a partir da raiz do repositorio:

```bash
go run ./cmd/pomo-tui --root ./scripts/arch
```

Para gerar ou atualizar o binario local:

```bash
go build -o ./pomo-tui ./cmd/pomo-tui
./pomo-tui --root ./scripts/arch
```

Atalhos principais:

- `j/k` ou setas: navegar na lista
- `espaco` ou `enter`: habilitar/desabilitar script
- `a`: toggle all
- `r`: executar scripts habilitados
- `esc`/`ctrl+c`: cancelar execucao em andamento
- `q`: sair

Observacoes:

- Scripts marcados como `interactive` tomam o terminal em foreground temporariamente. Responda ao prompt e a TUI volta ao final.
- Se o binario `./pomo-tui` se comportar diferente do codigo atual, recompile antes de usar.

Flags disponiveis:

- `--root <path>`: define a raiz do repositorio ou o diretorio `scripts/arch`
- `--no-alt-screen`: desativa a tela alternativa do terminal

### Arch Linux / CachyOS

```bash
git clone <repo-url>
cd scripts/arch
chmod +x *.sh assets/*.sh

# Dependencias minimas
sudo pacman -S --needed git base-devel curl

# Instalar tudo
./install-all.sh

# Atualizar sistema
./update.sh
```

### Fedora Workstation

```bash
git clone <repo-url>
cd scripts/fedora-wsl
chmod +x *.sh assets/*.sh

# Dependencias minimas (ja vem com Fedora)
sudo dnf install -y git curl

# Instalar tudo
./install-all.sh

# Atualizar sistema
./update.sh

# Manutencao completa
./system-maintenance.sh

# Preview sem executar
./system-maintenance.sh --dry-run
```

Observacao: o diretorio se chama `scripts/fedora-wsl` por historico, mas atende Fedora nativo e WSL2. Apenas comandos marcados como `[WSL]` dependem de integracao com Windows.

### Pop!_OS / Ubuntu

```bash
git clone <repo-url>
cd scripts/apt

# Instalacao completa
./post-install-apt.sh

# Atualizar sistema
./pop-update.sh

# Limpeza
./pop-clean.sh
```

---

## Scripts Exclusivos do Fedora

### copr-manager.sh

Gerenciador de repositorios COPR (equivalente ao AUR helper):

```bash
./copr-manager.sh search yazi
./copr-manager.sh install atim/yazi yazi
./copr-manager.sh list
./copr-manager.sh disable atim/yazi
```

### flatpak-manager.sh

Gerenciador de aplicacoes Flatpak:

```bash
./flatpak-manager.sh search spotify
./flatpak-manager.sh install com.spotify.Client
./flatpak-manager.sh update
./flatpak-manager.sh cleanup
./flatpak-manager.sh size
```

### distrobox-setup.sh

Container Arch Linux para pacotes AUR sem equivalente Fedora:

```bash
./distrobox-setup.sh create           # Cria container Arch com yay
./distrobox-setup.sh install pkg-aur  # Instala pacote AUR
./distrobox-setup.sh export pkg-aur   # Exporta app para o host
./distrobox-setup.sh export-bin bin   # Exporta binario para ~/.local/bin
```

### system-maintenance.sh

Rotina completa de manutencao: DNF + Flatpak + Firmware + Limpeza:

```bash
./system-maintenance.sh              # Executa tudo
./system-maintenance.sh --dry-run    # Preview sem executar
```

---

## Idempotencia

Todos os scripts foram escritos para poderem ser executados varias vezes sem causar erros:

- Se o pacote ja esta instalado -> apenas registra e pula.
- Se o repositorio ja foi clonado -> apenas atualiza com git pull.
- Se a configuracao ja existe -> nada e sobrescrito.

---

## Biblioteca Core (lib/utils.sh)

Cada distro tem sua propria `utils.sh` com funcoes equivalentes:

| Funcao | Arch | Fedora |
|--------|------|--------|
| `ensure_package "pkg"` | `pacman -S` | `dnf install` |
| `ensure_aur_package "pkg"` | `yay -S` | N/A |
| `ensure_copr_package "repo" "pkg"` | N/A | `dnf copr enable + install` |
| `ensure_group "grp"` | N/A | `dnf group install` |
| `ensure_flatpak_package "app"` | `flatpak install` | `flatpak install` |
| `ensure_rpmfusion` | N/A | Habilita RPM Fusion |
| `info()`, `ok()`, `warn()`, `fail()` | Log colorido | Log colorido |

---

## Documentacao

- **[docs/EQUIVALENCES.md](docs/EQUIVALENCES.md)** - Tabela completa de equivalencias pacman -> dnf
- **[docs/MIGRATION.md](docs/MIGRATION.md)** - Guia detalhado de migracao Arch -> Fedora

---

## Filosofia

- **Idempotencia**: rodar 100 vezes deve dar o mesmo resultado.
- **Legibilidade**: codigo simples > "magico".
- **Autonomia**: cada script faz uma coisa so.
- **Logs claros**: sempre saber o que foi feito e o que falhou.
- **Reprodutibilidade**: do zero ao ambiente pronto em minutos.
- **Multi-distro**: mesma logica, adaptada para cada gerenciador.

---

## Contribuicao

1. Crie uma branch: `git checkout -b feature/novo-script`
2. Adicione seu script no diretorio da distro correspondente
3. Adicione o nome do script ao array STEPS em `install-all.sh`
4. Teste: `./assets/install-novo-script.sh`
5. Faca commit e abra um merge request

---

## Licenca

Este projeto e distribuido sob a licenca MIT.

Use, modifique e compartilhe livremente, mas mencione a origem se for reutilizar partes do codigo.
