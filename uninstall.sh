#!/usr/bin/env bash
# Uninstaller for cx. Removes the `cx` symlink from PATH dirs.
# Does NOT touch ~/.codex-accounts (your accounts/auth) unless --purge is given.

set -euo pipefail

PURGE="${1:-}"
ROOT="${CODEX_ACCOUNTS_ROOT:-$HOME/.codex-accounts}"

removed=0
for d in "$HOME/.local/bin" "$HOME/bin" "/usr/local/bin"; do
  link="$d/cx"
  if [ -L "$link" ] || [ -f "$link" ]; then
    rm -f "$link" && echo "uninstall: removed $link" && removed=1
  fi
done
[ "$removed" = 1 ] || echo "uninstall: no cx found on PATH dirs"

if [ "$PURGE" = "--purge" ]; then
  rm -rf "$ROOT"
  echo "uninstall: purged $ROOT (accounts + auth removed)"
else
  echo "uninstall: kept $ROOT. Use '--purge' to remove accounts/auth too."
fi
