<p align="center">
  <img src="assets/substrato.png" alt="Substrato logo" width="180">
</p>

<h1 align="center">Substrato</h1>

<p align="center">
  <a href="README.en.md">English</a> | <a href="README.md">Português</a>
</p>

Substrato is a vendor-neutral bundle of Markdown skills for terminal AI agents.
It gives agents reusable operating instructions for repository inference workflows:

- `repo-distiller`: create `.distill/`, a compact codebase knowledge base for agents.
- `backlog-builder`: turn a project or idea into `.backlog/` cards.
- `spec-compiler`: compile confirmed backlog cards into implementation-ready specs.
- `repo-reviver`: revive stale projects through safe dependency/toolchain updates.

The canonical package format is plain files:

```text
substrato.yaml
skills/<skill-name>/SKILL.md
assets/
installers/
bin/
```

No npm package is required. Git is the transport, and the installers use only
POSIX shell on Linux/macOS or PowerShell on Windows.

## Install

Linux/macOS:

```sh
git clone --depth 1 https://github.com/yan-vidal/Substrato.git ~/.substrato
~/.substrato/bin/substrato install --target auto
```

Optional shell setup:

```sh
export PATH="$HOME/.substrato/bin:$PATH"
```

After that, run `substrato` from any directory.

Windows PowerShell:

```powershell
git clone --depth 1 https://github.com/yan-vidal/Substrato.git "$env:USERPROFILE\.substrato"
& "$env:USERPROFILE\.substrato\bin\substrato.ps1" install -Target auto
```

## How It Works

The clone at `~/.substrato` is the source and command wrapper. The install
command copies or symlinks the skills into the discovery path used by each
agent. You do not need to work inside the cloned Substrato repository.

Global installs affect the local machine. They are available to CLI/local
products that read the same filesystem. Remote cloud products will not see your
local home directory; use a workspace install for project-portable skills.

## Targets

Global targets install skills into your home directory so supported agents can
discover them from any project on this machine. Workspace targets install skills
into one repository so the project can carry its own agent instructions.

`agents` installs the bundle globally into the Agent Skills compatible path:

```sh
~/.substrato/bin/substrato install --target agents
```

This creates:

```text
~/.agents/skills/
  repo-distiller/
  backlog-builder/
  spec-compiler/
  repo-reviver/
```

Use this target for Codex, Gemini CLI, OpenCode, and Google Antigravity CLI.
Their adapters are aliases for the same global path:

```sh
~/.substrato/bin/substrato install --target codex
~/.substrato/bin/substrato install --target gemini
~/.substrato/bin/substrato install --target opencode
~/.substrato/bin/substrato install --target antigravity
```

`claude` installs the bundle globally into Claude Code's personal skills path:

```sh
~/.substrato/bin/substrato install --target claude
```

This creates:

```text
~/.claude/skills/
  repo-distiller/
  backlog-builder/
  spec-compiler/
  repo-reviver/
```

`workspace` installs the bundle into one project:

```sh
cd /path/to/your/project
~/.substrato/bin/substrato install --target workspace
```

Or from any directory:

```sh
~/.substrato/bin/substrato install --target workspace --project /path/to/your/project
```

This creates:

```text
.agents/skills/
  repo-distiller/
  backlog-builder/
  spec-compiler/
  repo-reviver/
```

`auto` installs global agent-compatible skills into `~/.agents/skills`. If
`~/.claude` exists, it also installs Claude Code skills into `~/.claude/skills`.

## Copy vs Link

Installers copy files by default:

```sh
~/.substrato/bin/substrato install --target agents --mode copy
```

For local development, symlink instead:

```sh
~/.substrato/bin/substrato install --target agents --mode link
```

On Windows, symlink mode can require Developer Mode or elevated permissions.
Use copy mode when link creation fails.

## Update

```sh
~/.substrato/bin/substrato update
```

Then rerun `install` for copy-mode targets.

## Uninstall

Remove installed Substrato skills from the default global targets:

```sh
~/.substrato/bin/substrato uninstall --target auto
```

Remove from a specific target:

```sh
~/.substrato/bin/substrato uninstall --target agents
~/.substrato/bin/substrato uninstall --target claude
```

Remove from a workspace:

```sh
~/.substrato/bin/substrato uninstall --target workspace --project /path/to/your/project
```

The uninstall command removes only Substrato's known skill directories. It does
not remove other skills from `~/.agents/skills`, `~/.claude/skills`, or
`.agents/skills`.

To remove the Substrato source clone too:

```sh
rm -rf ~/.substrato
```
