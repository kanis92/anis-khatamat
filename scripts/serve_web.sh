#!/bin/bash
# Script pour construire et servir l'app ANIS Khatamat sur un serveur local
# Usage: ./scripts/serve_web.sh

set -e
cd "$(dirname "$0")/.."

# Trouver Flutter (chemin connu, fvm, ou PATH)
FLUTTER_CMD=""
[ -x "$HOME/development/flutter/bin/flutter" ] && FLUTTER_CMD="$HOME/development/flutter/bin/flutter"
[ -z "$FLUTTER_CMD" ] && command -v fvm >/dev/null 2>&1 && FLUTTER_CMD="fvm flutter"
[ -z "$FLUTTER_CMD" ] && command -v flutter >/dev/null 2>&1 && FLUTTER_CMD="flutter"

if [ -z "$FLUTTER_CMD" ]; then
  echo "❌ Flutter non trouvé. Installez Flutter ou ajoutez-le au PATH."
  echo "   https://flutter.dev/docs/get-started/install"
  exit 1
fi

echo "📦 Utilisation de: $FLUTTER_CMD"
echo "🔨 Construction de l'app web..."
$FLUTTER_CMD build web --release

if [ ! -d "build/web" ]; then
  echo "❌ Le dossier build/web n'existe pas."
  exit 1
fi

echo ""
echo "✅ Build terminé !"
echo "🌐 Démarrage du serveur sur http://localhost:8080"
echo "   Ouvrez ce lien dans votre navigateur pour voir l'app."
echo "   Appuyez sur Ctrl+C pour arrêter le serveur."
echo ""

# Servir avec Python si disponible, sinon npx serve
if command -v python3 &> /dev/null; then
  python3 -m http.server 8080 --directory build/web
elif command -v python &> /dev/null; then
  python -m SimpleHTTPServer 8080
elif command -v npx &> /dev/null; then
  npx serve build/web -l 8080
else
  echo "❌ Aucun serveur trouvé (python, npx). Installez Python ou Node.js."
  exit 1
fi
