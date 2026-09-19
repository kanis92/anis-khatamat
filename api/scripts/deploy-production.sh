#!/usr/bin/env bash
# Déploiement API ANIS → serveur Infomaniak (même hébergement qu'aujourd'hui).
#
# Usage (après configuration une fois) :
#   cd api && ./scripts/deploy-production.sh
#
# Config : copier .deploy.env.example → .deploy.env (jamais commité)

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ -f "$ROOT/.deploy.env" ]]; then
  # shellcheck disable=SC1091
  source "$ROOT/.deploy.env"
fi

: "${DEPLOY_SSH:?Définir DEPLOY_SSH dans api/.deploy.env (ex. anis-api ou user@host)}"
: "${DEPLOY_PATH:?Définir DEPLOY_PATH dans api/.deploy.env (chemin absolu sur le serveur)}"
PM2_NAME="${PM2_NAME:-anis-api}"
HEALTH_URL="${HEALTH_URL:-https://api.anis-khatamat.com/health}"
METADATA_PROBE="${METADATA_PROBE:-https://api.anis-khatamat.com/v1/khatmat/deploy-probe/metadata}"

echo "→ Build local…"
npm run build

echo "→ Sync vers ${DEPLOY_SSH}:${DEPLOY_PATH} …"
rsync -avz --progress \
  --exclude node_modules \
  --exclude .env \
  --exclude .deploy.env \
  --exclude test \
  --exclude coverage \
  "$ROOT/src" \
  "$ROOT/lib" \
  "$ROOT/package.json" \
  "$ROOT/package-lock.json" \
  "${DEPLOY_SSH}:${DEPLOY_PATH}/"

echo "→ Install + build sur le serveur…"
ssh "$DEPLOY_SSH" "cd '${DEPLOY_PATH}' && npm install --production && npm run build"

if ssh "$DEPLOY_SSH" "command -v pm2 >/dev/null 2>&1"; then
  echo "→ Redémarrage PM2 (${PM2_NAME})…"
  ssh "$DEPLOY_SSH" "pm2 restart '${PM2_NAME}' || pm2 start lib/server.js --name '${PM2_NAME}'"
else
  echo "⚠️  PM2 introuvable sur le serveur — redémarrez l’app Node depuis le Manager Infomaniak."
fi

echo "→ Vérification /health …"
curl -sf "$HEALTH_URL" | head -c 200
echo ""

echo "→ Vérification route metadata (doit répondre AUTH_REQUIRED, pas NOT_FOUND)…"
PROBE_BODY="$(curl -s -X POST "$METADATA_PROBE" -H 'Content-Type: application/json' -d '{"title":"x"}' || true)"
echo "$PROBE_BODY"
if echo "$PROBE_BODY" | grep -q 'NOT_FOUND'; then
  echo "❌ Route metadata absente — déploiement incomplet ou mauvais serveur."
  exit 1
fi
if echo "$PROBE_BODY" | grep -q 'AUTH_REQUIRED'; then
  echo "✅ Déploiement OK (route metadata présente)."
else
  echo "⚠️  Réponse inattendue — vérifiez manuellement."
fi
