#!/bin/bash
# ANIS Khatamat - Script de préparation release iOS pour TestFlight
# Ce script prépare l'IPA à envoyer via Transporter

set -e

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=============================================="
echo "  ANIS Khatamat - Préparation Release iOS"
echo "=============================================="
echo ""

# Dossier des artefacts (où vous avez extrait le téléchargement Codemagic)
ARTIFACTS_DIR="${1:-.}"
ARTIFACTS_DIR="$(cd "$ARTIFACTS_DIR" 2>/dev/null && pwd)" || { echo "Dossier introuvable: $1"; exit 1; }
cd "$ARTIFACTS_DIR"

IPA_READY=""
XCARCHIVE="$ARTIFACTS_DIR/build/ios/archive/Runner.xcarchive"
IPA_DIR="$ARTIFACTS_DIR/build/ios/ipa"

# 1. Vérifier si l'IPA existe déjà (généré par flutter build ipa)
if ls "$IPA_DIR"/*.ipa 1> /dev/null 2>&1; then
    IPA_READY=$(ls "$IPA_DIR"/*.ipa | head -1)
    echo -e "${GREEN}✓ IPA trouvé: $IPA_READY${NC}"
fi

# 2. Sinon, créer l'IPA à partir du xcarchive
if [ -z "$IPA_READY" ]; then
    if [ ! -d "$XCARCHIVE" ]; then
        echo -e "${RED}❌ Erreur: Aucun IPA ni archive trouvé.${NC}"
        echo ""
        echo "Structure attendue après extraction des artefacts Codemagic:"
        echo "  $ARTIFACTS_DIR/"
        echo "  └── build/"
        echo "      └── ios/"
        echo "          ├── ipa/*.ipa       (optionnel)"
        echo "          └── archive/Runner.xcarchive/"
        echo ""
        echo "Usage: $0 [dossier_contenant_build]"
        echo "Exemple: $0 ~/Downloads/artifacts_123"
        exit 1
    fi

    echo -e "${YELLOW}IPA non trouvé. Création à partir de Runner.xcarchive...${NC}"
    
    OUTPUT_IPA="$ARTIFACTS_DIR/Runner.ipa"
    APP_BUNDLE="$XCARCHIVE/Products/Applications/Runner.app"
    
    if [ ! -d "$APP_BUNDLE" ]; then
        echo -e "${RED}❌ Runner.app introuvable dans l'archive${NC}"
        exit 1
    fi

    rm -rf "$ARTIFACTS_DIR/Payload" "$ARTIFACTS_DIR/SwiftSupport" "$ARTIFACTS_DIR/WatchKitSupport" "$OUTPUT_IPA"
    mkdir -p "$ARTIFACTS_DIR/Payload"
    cp -R "$APP_BUNDLE" "$ARTIFACTS_DIR/Payload/"

    # Inclure SwiftSupport (requis par Apple - erreur 90426)
    if [ -d "$XCARCHIVE/SwiftSupport" ]; then
        echo -e "${GREEN}✓ Ajout de SwiftSupport${NC}"
        cp -Rp "$XCARCHIVE/SwiftSupport" "$ARTIFACTS_DIR/"
    else
        echo -e "${YELLOW}⚠ SwiftSupport absent dans l'archive - l'IPA peut être rejeté (90426)${NC}"
    fi

    # Inclure WatchKitSupport si présent
    if [ -d "$XCARCHIVE/WatchKitSupport" ]; then
        cp -Rp "$XCARCHIVE/WatchKitSupport" "$ARTIFACTS_DIR/"
    fi

    cd "$ARTIFACTS_DIR"
    ZIP_ARGS="Payload"
    [ -d "SwiftSupport" ] && ZIP_ARGS="$ZIP_ARGS SwiftSupport"
    [ -d "WatchKitSupport" ] && ZIP_ARGS="$ZIP_ARGS WatchKitSupport"
    zip -r -y "Runner.ipa" $ZIP_ARGS
    rm -rf Payload SwiftSupport WatchKitSupport
    
    IPA_READY="$OUTPUT_IPA"
    echo -e "${GREEN}✓ IPA créé: $IPA_READY${NC}"
fi

echo ""
echo "=============================================="
echo -e "${GREEN}  PRÊT POUR TESTFLIGHT${NC}"
echo "=============================================="
echo ""
echo "Fichier à envoyer: $IPA_READY"
echo ""
echo "Prochaines étapes:"
echo "  1. Ouvrir Transporter (App Store sur Mac)"
echo "  2. Glisser-déposer: $IPA_READY"
echo "  3. Cliquer sur 'Deliver'"
echo "  4. Attendre la validation (5-30 min)"
echo "  5. Vérifier dans App Store Connect → TestFlight"
echo ""

# Ouvrir le dossier contenant l'IPA dans Finder
open "$(dirname "$IPA_READY")"

# Ouvrir Transporter si disponible
if open -a "Transporter" 2>/dev/null; then
    echo "Transporter ouvert. Glissez Runner.ipa dans la fenêtre."
else
    echo "Transporter non trouvé. Ouvrez-le manuellement depuis l'App Store."
fi
