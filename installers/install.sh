#!/usr/bin/env sh
set -eu

usage() {
  cat <<'EOF'
Usage:
  install.sh [--action install|uninstall] [--target auto|agents|codex|gemini|opencode|antigravity|claude|workspace] [--project PATH] [--mode copy|link]

Targets:
  auto       Install global agent-compatible skills, plus Claude skills when ~/.claude exists.
  agents     Install global skills into ~/.agents/skills.
  codex      Alias for agents; Codex reads ~/.agents/skills.
  gemini     Alias for agents; Gemini CLI reads ~/.agents/skills.
  opencode   Alias for agents; OpenCode reads ~/.agents/skills.
  antigravity Alias for agents; Antigravity uses Agent Skills customization.
  claude     Install global Claude Code skills into ~/.claude/skills.
  workspace  Install project-local skills into .agents/skills.

Options:
  --action ACTION  install (default) or uninstall.
  --project PATH  Project path for workspace installs. Defaults to current directory.
  --mode MODE     copy (default) or link.
EOF
}

die() {
  printf '%s\n' "$*" >&2
  exit 1
}

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
root_dir=$(CDPATH= cd -- "$script_dir/.." && pwd)
target=auto
project_dir=$(pwd)
mode=copy
action=install

while [ "$#" -gt 0 ]; do
  case "$1" in
    --action)
      [ "$#" -ge 2 ] || die "Missing value for --action"
      action=$2
      shift 2
      ;;
    --target)
      [ "$#" -ge 2 ] || die "Missing value for --target"
      target=$2
      shift 2
      ;;
    --project)
      [ "$#" -ge 2 ] || die "Missing value for --project"
      project_dir=$2
      shift 2
      ;;
    --mode)
      [ "$#" -ge 2 ] || die "Missing value for --mode"
      mode=$2
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
done

[ -d "$root_dir/skills" ] || die "Substrato skills directory not found: $root_dir/skills"

case "$target" in
  auto|agents|codex|gemini|opencode|antigravity|claude|workspace) ;;
  *) die "Unsupported target: $target" ;;
esac

case "$action" in
  install|uninstall) ;;
  *) die "Unsupported action: $action" ;;
esac

case "$mode" in
  copy|link) ;;
  *) die "Unsupported mode: $mode" ;;
esac

copy_or_link_dir() {
  src=$1
  dst=$2
  rm -rf "$dst" || return 1
  mkdir -p "$(dirname "$dst")" || return 1
  if [ "$mode" = "link" ]; then
    ln -s "$src" "$dst" || return 1
  else
    mkdir -p "$dst" || return 1
    cp -R "$src/." "$dst/" || return 1
  fi
}

install_skill_dirs() {
  dst_root=$1
  mkdir -p "$dst_root"
  for skill in "$root_dir"/skills/*; do
    [ -d "$skill" ] || continue
    copy_or_link_dir "$skill" "$dst_root/$(basename "$skill")" || return 1
  done
}

uninstall_skill_dirs() {
  dst_root=$1
  for skill in "$root_dir"/skills/*; do
    [ -d "$skill" ] || continue
    rm -rf "$dst_root/$(basename "$skill")"
  done
}

install_workspace() {
  abs_project=$(CDPATH= cd -- "$project_dir" && pwd)
  install_skill_dirs "$abs_project/.agents/skills"
  printf 'Installed workspace Substrato skills at %s/.agents/skills\n' "$abs_project"
}

uninstall_workspace() {
  abs_project=$(CDPATH= cd -- "$project_dir" && pwd)
  uninstall_skill_dirs "$abs_project/.agents/skills"
  printf 'Removed workspace Substrato skills from %s/.agents/skills\n' "$abs_project"
}

install_agents() {
  install_skill_dirs "$HOME/.agents/skills" || return 1
  printf 'Installed agent-compatible skills at %s/.agents/skills\n' "$HOME"
}

uninstall_agents() {
  uninstall_skill_dirs "$HOME/.agents/skills"
  printf 'Removed agent-compatible Substrato skills from %s/.agents/skills\n' "$HOME"
}

install_claude() {
  install_skill_dirs "$HOME/.claude/skills" || return 1
  printf 'Installed Claude Code skills at %s/.claude/skills\n' "$HOME"
}

uninstall_claude() {
  uninstall_skill_dirs "$HOME/.claude/skills"
  printf 'Removed Claude Code Substrato skills from %s/.claude/skills\n' "$HOME"
}

case "$target" in
  workspace)
    if [ "$action" = "install" ]; then install_workspace; else uninstall_workspace; fi
    ;;
  agents|codex|gemini|opencode|antigravity)
    if [ "$action" = "install" ]; then install_agents; else uninstall_agents; fi
    ;;
  claude)
    if [ "$action" = "install" ]; then install_claude; else uninstall_claude; fi
    ;;
  auto)
    if [ "$action" = "install" ]; then install_agents; else uninstall_agents; fi
    if [ -d "$HOME/.claude" ]; then
      if [ ! -w "$HOME/.claude" ]; then
        printf 'Skipped Claude %s during auto target; use --target claude to fail strictly.\n' "$action" >&2
      else
        set +e
        if [ "$action" = "install" ]; then install_claude; else uninstall_claude; fi
        claude_status=$?
        set -e
        if [ "$claude_status" -ne 0 ]; then
          printf 'Skipped Claude %s during auto target; use --target claude to fail strictly.\n' "$action" >&2
        fi
      fi
    fi
    ;;
esac
