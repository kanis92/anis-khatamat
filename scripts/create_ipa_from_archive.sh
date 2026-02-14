#!/bin/bash
# Script pour créer un IPA valide à partir de Runner.xcarchive
# Usage: ./create_ipa_from_archive.sh [chemin/vers/Runner.xcarchive]

set -e

XCARCHIVE="${1:-build/ios/archive/Runner.xcarchive}"
OUTPUT_IPA="${2:-Runner.ipa}"

if [ ! -d "$XCARCHIVE" ]; then
    echo "❌ Erreur: Archive introuvable: $XCARCHIVE"
    echo ""
    echo "Usage: $0 [chemin/vers/Runner.xcarchive] [nom_sortie.ipa]"
    echo ""
    echo "Exemples:"
    echo "  $0                                    # cherche build/ios/archive/Runner.xcarchive"
    echo "  $0 build/ios/archive/Runner.xcarchive"
    echo "  $0 ~/Downloads/ios/archive/Runner.xcarchive"
    exit 1
fi

APP_BUNDLE="$XCARCHIVE/Products/Applications/Runner.app"
if [ ! -d "$APP_BUNDLE" ]; then
    echo "❌ Erreur: Runner.app introuvable dans l'archive"
    echo "   Attendu: $APP_BUNDLE"
    exit 1
fi

echo "📦 Création de l'IPA à partir de: $XCARCHIVE"
echo ""

# Nettoyer si un run précédent a échoué
rm -rf Payload SwiftSupport WatchKitSupport "$OUTPUT_IPA"

# 1. Créer le dossier Payload
mkdir -p Payload

# 2. Copier Runner.app DANS Payload (structure requise par Apple)
cp -R "$APP_BUNDLE" Payload/

# 3. Inclure SwiftSupport (requis par Apple - erreur 90426)
if [ -d "$XCARCHIVE/SwiftSupport" ]; then
    echo "✓ Ajout SwiftSupport"
    cp -Rp "$XCARCHIVE/SwiftSupport" .
fi
if [ -d "$XCARCHIVE/WatchKitSupport" ]; then
    cp -Rp "$XCARCHIVE/WatchKitSupport" .
fi

# 4. Créer le ZIP (Payload + SwiftSupport + WatchKitSupport)
echo "⏳ Compression..."
ZIP_ARGS="Payload"
[ -d "SwiftSupport" ] && ZIP_ARGS="$ZIP_ARGS SwiftSupport"
[ -d "WatchKitSupport" ] && ZIP_ARGS="$ZIP_ARGS WatchKitSupport"
zip -r -y "$OUTPUT_IPA" $ZIP_ARGS

# 5. Nettoyer
rm -rf Payload SwiftSupport WatchKitSupport

echo ""
echo "✅ IPA créé avec succès: $OUTPUT_IPA"
echo ""
echo "Vérification de la structure:"
unzip -l "$OUTPUT_IPA" | head -15
echo ""
echo "👉 Vous pouvez maintenant envoyer $OUTPUT_IPA via Transporter"
