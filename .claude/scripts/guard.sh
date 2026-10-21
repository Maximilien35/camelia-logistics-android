#!/usr/bin/env bash
# Garde-fou sur les commandes et modifications risquant de casser le lien
# avec l'app V1 déjà publiée sur les stores.
# Déclenché par le hook PreToolUse sur Bash et Edit.

set -uo pipefail

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")
FILE_PATH=$(printf '%s' "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null || echo "")

block() {
  echo "Commande bloquée par le garde-fou projet : $1" >&2
  exit 2
}

# Réinitialisation complète du projet Flutter (perd la config native iOS/Android)
case "$CMD" in
  *"flutter create ."*|*"flutter create ./"*) block "recréerait le projet et écraserait la config native (bundle ID, signature) de l'app déjà publiée." ;;
esac

# Historique Git réécrit ou changement de branche destructeur
case "$CMD" in
  *"git push --force"*|*"git push -f"*) block "push forcé interdit." ;;
  *"git reset --hard"*) block "reset --hard détruit du travail non commité. Demande confirmation à l'utilisateur." ;;
esac

# Fichiers sensibles à l'identité de l'app publiée
case "$FILE_PATH" in
  *"android/app/build.gradle"*|*"android/app/build.gradle.kts"*)
    echo "⚠️  Modification de build.gradle détectée : vérifie que applicationId n'est pas modifié — c'est l'identité de l'app sur Google Play." >&2
    ;;
  *"ios/Runner.xcodeproj"*|*"ios/Runner/Info.plist"*)
    echo "⚠️  Modification de la config iOS détectée : vérifie que le bundle ID n'est pas modifié — c'est l'identité de l'app sur l'App Store." >&2
    ;;
  *"codemagic.yaml"*)
    echo "⚠️  Modification de codemagic.yaml détectée : vérifie que la configuration de signature n'est pas touchée." >&2
    ;;
esac

exit 0
