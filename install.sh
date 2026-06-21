#!/usr/bin/env bash
# Installer for cx — codex account switcher.
# Symlinks bin/cx into a PATH dir and bootstraps the first account from an
# existing ~/.codex login (if present). Safe to re-run (idempotent).

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO_DIR/bin/cx"
ROOT="${CODEX_ACCOUNTS_ROOT:-$HOME/.codex-accounts}"
SHARED="${CODEX_SHARED_HOME:-$HOME/.codex}"

[ -f "$SRC" ] || { echo "install: $SRC not found" >&2; exit 1; }
chmod +x "$SRC"

# Pick an install dir that is on PATH and writable (prefer ~/.local/bin).
on_path() { case ":$PATH:" in *":$1:"*) return 0;; *) return 1;; esac; }
INSTALL_DIR=""
for d in "$HOME/.local/bin" "$HOME/bin" "/usr/local/bin"; do
  if [ -d "$d" ] && [ -w "$d" ] && on_path "$d"; then INSTALL_DIR="$d"; break; fi
done
if [ -z "$INSTALL_DIR" ]; then
  INSTALL_DIR="$HOME/.local/bin"
  mkdir -p "$INSTALL_DIR"
fi

ln -sfn "$SRC" "$INSTALL_DIR/cx"
echo "install: linked $INSTALL_DIR/cx -> $SRC"

if ! on_path "$INSTALL_DIR"; then
  echo "install: WARNING — $INSTALL_DIR is not on PATH."
  echo "         Add to your shell rc:  export PATH=\"$INSTALL_DIR:\$PATH\""
fi

# Bootstrap first account from an existing logged-in ~/.codex, if present.
mkdir -p "$ROOT"
[ -f "$ROOT/.rr-state" ] || echo 0 > "$ROOT/.rr-state"
if [ -z "$(find "$ROOT" -mindepth 1 -maxdepth 1 -type d ! -name '.*' 2>/dev/null)" ]; then
  if [ -f "$SHARED/auth.json" ]; then
    home="$ROOT/personal"
    mkdir -p "$home"
    cp -p "$SHARED/auth.json" "$home/auth.json"
    chmod 600 "$home/auth.json"
    for item in config.toml skills rules; do
      [ -e "$SHARED/$item" ] && ln -sfn "$SHARED/$item" "$home/$item"
    done
    echo "install: adopted existing $SHARED login as account 'personal'"
  else
    echo "install: no existing $SHARED/auth.json — create your first account with: cx login <name>"
  fi
fi

echo "install: done.  Try:  cx --list   |   cx login <name>   |   cx"
