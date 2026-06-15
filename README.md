<p align="center">
  <img src="assets/substrato.png" alt="Logo do Substrato" width="180">
</p>

<h1 align="center">Substrato</h1>

<p align="center">
  <a href="README.en.md">English</a> | <a href="README.md">Português</a>
</p>

Substrato é um pacote neutro de skills em Markdown para agentes de IA no
terminal. Ele fornece instruções reutilizáveis para fluxos de inferência de
repositórios:

- `repo-distiller`: cria `.distill/`, uma base compacta de conhecimento do código para agentes.
- `backlog-builder`: transforma um projeto ou ideia em cards `.backlog/`.
- `spec-compiler`: compila cards confirmados em specs prontas para implementação.
- `repo-reviver`: revive projetos parados com atualização segura de dependências e toolchain.

O formato canônico do pacote é composto por arquivos simples:

```text
substrato.yaml
skills/<skill-name>/SKILL.md
assets/
installers/
bin/
```

Nenhum pacote npm é necessário. Git é o transporte, e os instaladores usam
apenas shell POSIX no Linux/macOS ou PowerShell no Windows.

## Instalação

Linux/macOS:

```sh
git clone --depth 1 https://github.com/yan-vidal/Substrato.git ~/.substrato
~/.substrato/bin/substrato install --target auto
```

Configuração opcional do shell:

```sh
export PATH="$HOME/.substrato/bin:$PATH"
```

Depois disso, rode `substrato` de qualquer diretório.

Windows PowerShell:

```powershell
git clone --depth 1 https://github.com/yan-vidal/Substrato.git "$env:USERPROFILE\.substrato"
& "$env:USERPROFILE\.substrato\bin\substrato.ps1" install -Target auto
```

## Como Funciona

O clone em `~/.substrato` é a fonte e o wrapper de comando. O comando de
instalação copia ou cria symlinks das skills para o caminho de descoberta usado
por cada agente. Você não precisa trabalhar dentro do repositório clonado do
Substrato.

Instalações globais afetam a máquina local. Elas ficam disponíveis para CLIs e
produtos locais que leem o mesmo filesystem. Produtos remotos/cloud não enxergam
seu diretório home local; use instalação de workspace para skills portáveis por
projeto.

## Targets

Targets globais instalam as skills no seu diretório home para que agentes
suportados as descubram a partir de qualquer projeto nesta máquina. Targets de
workspace instalam as skills em um repositório específico para que o projeto
carregue suas próprias instruções de agente.

`agents` instala o pacote globalmente no caminho compatível com Agent Skills:

```sh
~/.substrato/bin/substrato install --target agents
```

Isso cria:

```text
~/.agents/skills/
  repo-distiller/
  backlog-builder/
  spec-compiler/
  repo-reviver/
```

Use esse target para Codex, Gemini CLI, OpenCode e Google Antigravity CLI. Os
adapters deles são aliases para o mesmo caminho global:

```sh
~/.substrato/bin/substrato install --target codex
~/.substrato/bin/substrato install --target gemini
~/.substrato/bin/substrato install --target opencode
~/.substrato/bin/substrato install --target antigravity
```

`claude` instala o pacote globalmente no caminho pessoal de skills do Claude
Code:

```sh
~/.substrato/bin/substrato install --target claude
```

Isso cria:

```text
~/.claude/skills/
  repo-distiller/
  backlog-builder/
  spec-compiler/
  repo-reviver/
```

`workspace` instala o pacote em um projeto:

```sh
cd /path/to/your/project
~/.substrato/bin/substrato install --target workspace
```

Ou de qualquer diretório:

```sh
~/.substrato/bin/substrato install --target workspace --project /path/to/your/project
```

Isso cria:

```text
.agents/skills/
  repo-distiller/
  backlog-builder/
  spec-compiler/
  repo-reviver/
```

`auto` instala skills globais compatíveis com agentes em `~/.agents/skills`. Se
`~/.claude` existir, também instala as skills do Claude Code em
`~/.claude/skills`.

## Cópia vs Link

Os instaladores copiam os arquivos por padrão:

```sh
~/.substrato/bin/substrato install --target agents --mode copy
```

Para desenvolvimento local, use symlink:

```sh
~/.substrato/bin/substrato install --target agents --mode link
```

No Windows, symlinks podem exigir Developer Mode ou permissões elevadas. Use
modo copy se a criação de links falhar.

## Atualização

```sh
~/.substrato/bin/substrato update
```

Depois rode `install` novamente para targets instalados em modo copy.

## Desinstalação

Remova as skills do Substrato dos targets globais padrão:

```sh
~/.substrato/bin/substrato uninstall --target auto
```

Remova de um target específico:

```sh
~/.substrato/bin/substrato uninstall --target agents
~/.substrato/bin/substrato uninstall --target claude
```

Remova de um workspace:

```sh
~/.substrato/bin/substrato uninstall --target workspace --project /path/to/your/project
```

O comando de desinstalação remove apenas os diretórios de skills conhecidos do
Substrato. Ele não remove outras skills de `~/.agents/skills`,
`~/.claude/skills` ou `.agents/skills`.

Para remover também o clone fonte do Substrato:

```sh
rm -rf ~/.substrato
```
