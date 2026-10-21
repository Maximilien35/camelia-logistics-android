#!/usr/bin/env bash
# Formate et vérifie un fichier Dart après édition par Claude Code.
# Déclenché par le hook PostToolUse sur Edit/Write.

set -uo pipefail

INPUT=$(cat)
FILE_PATH=$(printf '%s' "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null || echo "")

case "$FILE_PATH" in
  *.dart) ;;
  *) exit 0 ;;
esac

[ -f "$FILE_PATH" ] || exit 0

if command -v dart >/dev/null 2>&1; then
  dart format "$FILE_PATH" >/dev/null 2>&1

  if ! ANALYZE_OUT=$(dart analyze "$FILE_PATH" 2>&1); then
    echo "Analyse Dart en échec sur $FILE_PATH :" >&2
    echo "$ANALYZE_OUT" >&2
    echo "Corrige ces erreurs avant de continuer." >&2
    exit 2
  fi
fi

exit 0
