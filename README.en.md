<p align="center">
  <img src="assets/substrato.png" alt="Substrato logo" width="180">
</p>

<h1 align="center">Substrato</h1>

<p align="center">
  <a href="README.en.md">English</a> | <a href="README.md">Português</a>
</p>

Substrato is a vendor-neutral bundle of Markdown skills for terminal AI agents.
It gives agents reusable operating instructions for repository inference workflows:

| Skill | What it does | How to trigger it |
| --- | --- | --- |
| `repo-distiller` | Creates `.distill/`, a compact codebase knowledge base for agents. | "Map this repository so future agents can understand it quickly." |
| `backlog-builder` | Turns a project or idea into `.backlog/` cards. | "Turn this project into a prioritized backlog." |
| `spec-compiler` | Compiles confirmed backlog cards into implementation-ready specs. | "Prepare this backlog card for implementation." |
| `repo-reviver` | Revives stale projects through safe dependency/toolchain updates. | "Get this old project installing, running, and passing checks again." |

Git is the only dependency. The installers use only POSIX shell on Linux/macOS
or PowerShell on Windows.

## Index

- [Install](#install)
- [How to Use](#how-to-use)
- [Uninstall](#uninstall)
- [Skills](#skills)
- [Details](#details)
- [Targets](#targets)
- [Copy vs Link](#copy-vs-link)
- [Update](#update)

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

## How to Use

To install the default skill package into supported local targets:

```sh
~/.substrato/bin/substrato install --target auto
```

After installation, open your terminal agent in any project and ask in natural
language. Examples:

```text
Map this repository so future agents can understand it quickly.
Turn this project into a prioritized backlog.
Prepare this backlog card for implementation.
Get this old project installing, running, and passing checks again.
```

The clone at `~/.substrato` is the source and command wrapper. You can call
`~/.substrato/bin/substrato` from any project; the installer copies or links the
skills into the selected target.

By default, `install` and `uninstall` operate on the whole package. Use
`--skill` when you want to select specific skills:

```sh
~/.substrato/bin/substrato install --target agents --skill repo-distiller
~/.substrato/bin/substrato install --target workspace --project /path/to/project \
  --skill repo-distiller \
  --skill spec-compiler
```

## Uninstall

To remove installed skills from default targets and delete the source clone:

```sh
~/.substrato/bin/substrato uninstall --target auto && rm -rf ~/.substrato
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

To remove only the source clone without touching installed skills:

```sh
rm -rf ~/.substrato
```

## Skills

### `repo-distiller`

Creates `.distill/`, a compact knowledge base that helps agents understand a
repository without rereading everything. The skill treats documentation as a
codec: `MAP.md` defines the notation, `INDEX.md` routes navigation, module files
summarize important areas, and `INSIGHTS.md` captures invariants, couplings,
risks, lies, and knowledge that does not live in one file. It is the best first
step for large, unfamiliar, or paused repositories.

### `backlog-builder`

Turns a project, idea, or `.distill/` corpus into a traceable `.backlog/` board.
The skill acts like a product owner: it infers the business, researches gaps and
comparable products, proposes candidate cards, and confirms every requirement
with the user before marking anything as `confirmed`. The output is a Markdown
backlog with `BACKLOG.md`, individual card files, and `DECISIONS.md`, ready for
humans and implementation agents.

### `spec-compiler`

Compiles a `confirmed` backlog card into two implementation specs under
`.backlog/specs/`: a `compact` spec for strong models, preserving tactical
freedom, and a `full` spec for smaller models, with a step-by-step playbook.
The skill uses `.distill/`, `.backlog/`, and the real source code to define
touchpoints, interfaces, constraints, verification commands, edge cases, and
gotchas. Use it when a card is decided and needs to become executable
instructions.

### `repo-reviver`

Revives old or broken projects without changing observable behavior. The skill
requires a baseline before dependency changes, adds characterization tests when
needed, groups packages into clusters, researches changelogs/CVEs/migration
guides, and records decisions under `.revive/`. Each cluster becomes an
interactive decision and one reversible commit. Use it for projects that no
longer install, no longer run, are far behind, or depend on abandoned packages.

## Details

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
