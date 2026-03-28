# WSL Bootstrap v2.0 - Guia de Uso

Aplicativo Go com interface TUI (Terminal User Interface) para gerenciar o WSL e instalar pacotes no Ubuntu.

## 🚀 Execução Rápida

```powershell
cd scripts/ubuntu-wsl
.\wsl-bootstrap.exe
```

## 🎮 Controles

| Tecla | Ação |
|-------|------|
| `↑` / `↓` ou `j` / `k` | Navegar no menu |
| `Enter` | Selecionar item |
| `ESC` | Voltar / Sair |
| `q` | Sair do aplicativo |

## 📋 Funcionalidades

### 1. Bootstrap Ubuntu WSL
Instala o Ubuntu 22.04 no WSL (se ainda não estiver instalado).

### 2. Instalação Completa
Instala todos os componentes em sequência:
- Base (pacotes essenciais)
- Shell (Fish + Starship)
- CLI Tools (ripgrep, eza, fzf, etc)
- Dev Tools (git, gh, fnm, neovim)
- Dotfiles (suas configurações)

### 3. Instalação Individual
Instalar apenas um componente específico.

### 4. Sistema
- **Atualizar Sistema**: `sudo apt update && upgrade`
- **Limpar Sistema**: Remover cache e pacotes órfãos
- **Listar Portas**: Mostrar portas em uso

### 5. Utilitários WSL
- **Abrir Explorer**: Abre pasta atual no Windows Explorer
- **Abrir VSCode**: Abre VSCode no diretório atual
- **Verificar Distros**: Lista todas as distribuições WSL

## 🔧 Compilação

### Requisitos
- Go 1.21+
- Windows 10/11

### Passos

```powershell
# Navegar para o diretório
cd scripts/ubuntu-wsl\bootstrap-go

# Baixar dependências
make deps

# Compilar para desenvolvimento
make build

# Compilar versão otimizada (release)
make release

# Limpar builds
make clean
```

## 🐛 Solução de Problemas

### "WSL não encontrado"
Certifique-se de que o WSL está instalado:
```powershell
wsl --version
```

Se não estiver instalado, execute primeiro:
```powershell
wsl --install
```

### "Ubuntu não instalado"
Selecione "📦 Bootstrap Ubuntu WSL" no menu primeiro.

### Erro durante instalação
Verifique se:
1. Está executando como Administrador (para Bootstrap)
2. Tem conexão com a internet
3. O Ubuntu WSL está configurado

## 📁 Estrutura do Código

```
bootstrap-go/
├── main.go              # Entry point
├── model.go             # Estado e dados
├── views.go             # Renderização UI
├── commands.go          # Comandos WSL
├── Makefile            # Scripts de build
├── go.mod              # Dependências
└── build/
    └── wsl-bootstrap.exe
```

## 🎨 Tecnologias

- **Bubble Tea**: Framework TUI
- **Lipgloss**: Estilização
- **Go**: Linguagem principal

## 📝 Notas

- O aplicativo detecta automaticamente se o WSL está instalado
- Categorias de menu podem ser expandidas/colapsadas
- Progresso de instalação mostrado em tempo real
- Erros são exibidos com mensagens claras

---

**Versão**: 2.0  
**Autor**: paesmont
