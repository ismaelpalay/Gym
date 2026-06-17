#!/bin/bash
# Script interno para push a GitHub con auto-deploy en Vercel
set -e
BRANCH=$(git rev-parse --abbrev-ref HEAD)
git push origin "$BRANCH"
# Sincronizar main para que Vercel auto-despliegue
git push origin "$BRANCH":main
echo "✓ Push a $BRANCH + main completado → Vercel desplegará automáticamente"
