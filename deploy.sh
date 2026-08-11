#!/usr/bin/env bash
set -euo pipefail

# Renders the site, password-encrypts everything under reports/, and
# publishes to GitHub Pages. Requires: quarto, and node (for npx).
#
# Usage:
#   STATICRYPT_PASSWORD="a long shared password" ./deploy.sh
# or copy .env.example to .env, fill in STATICRYPT_PASSWORD there, then:
#   ./deploy.sh

if [ -z "${STATICRYPT_PASSWORD:-}" ] && [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

if [ -z "${STATICRYPT_PASSWORD:-}" ]; then
  echo "STATICRYPT_PASSWORD is not set."
  echo "Set it inline (STATICRYPT_PASSWORD=... ./deploy.sh) or put it in a .env file (see .env.example)."
  exit 1
fi

echo "==> Rendering site..."
quarto render

echo "==> Encrypting reports/ with StatiCrypt..."
npx --yes staticrypt "_site/reports/*" -r -d _site/reports \
  -p "$STATICRYPT_PASSWORD" \
  --remember 30 \
  --short \
  --template-title "In-Progress Reports" \
  --template-instructions "Enter the shared password to view this section."

echo "==> Publishing to GitHub Pages..."
quarto publish gh-pages --no-render --no-prompt --no-browser

echo "==> Done. The reports listing is at: <your-site-url>/reports/"
