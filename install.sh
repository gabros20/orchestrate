#!/usr/bin/env bash
# Install one runtime skill without exposing repository-only docs, evals, or release files.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
target="${1:-claude}"
skill_name="orchestrate"
source_dir="$here/skills/$skill_name"

[ -f "$source_dir/SKILL.md" ] || { echo "install: missing $source_dir/SKILL.md" >&2; exit 1; }

install_to() {
  parent="$1"
  dest="$parent/$skill_name"
  staging="$parent/.${skill_name}.install.$$"
  backup="$parent/.${skill_name}.backup.$$"

  mkdir -p "$parent"
  trap 'rm -rf "$staging" "$backup"' RETURN
  cp -R "$source_dir" "$staging"

  if [ -e "$dest" ]; then
    mv "$dest" "$backup"
  fi
  if mv "$staging" "$dest"; then
    rm -rf "$backup"
  else
    [ ! -e "$backup" ] || mv "$backup" "$dest"
    echo "install: failed; previous installation restored" >&2
    return 1
  fi
  echo "installed → $dest"
}

case "$target" in
  claude)      install_to "$HOME/.claude/skills" ;;
  codex)       install_to "${CODEX_HOME:-$HOME/.codex}/skills" ;;
  agents)      install_to "$HOME/.agents/skills" ;;
  cursor)      install_to "$HOME/.cursor/skills" ;;
  antigravity) install_to "$HOME/.gemini/config/skills"
               install_to "$HOME/.gemini/antigravity-cli/skills" ;;
  opencode)    install_to "$HOME/.config/opencode/skills" ;;
  grok)        install_to "$HOME/.grok/skills" ;;
  hermes)      install_to "$HOME/.hermes/skills" ;;
  all)         install_to "$HOME/.claude/skills"
               install_to "${CODEX_HOME:-$HOME/.codex}/skills"
               install_to "$HOME/.agents/skills" ;;
  *) echo "usage: ./install.sh [claude|codex|agents|cursor|antigravity|opencode|grok|hermes|all]" >&2; exit 1 ;;
esac

echo "Codex explicit invocation: \$$skill_name. Other clients may use slash commands, @mentions, a skill tool, or natural language."
