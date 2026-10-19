#!/usr/bin/env bash
# Publish the current folder to GitHub Pages (the site updates ~1 minute after a push).
# Usage:  ./deploy.sh "what changed"
set -euo pipefail
msg="${1:-Update game}"
git add -A
git commit -m "$msg" || { echo "Nothing to deploy."; exit 0; }
git push origin main
echo "Pushed. Live in about a minute: https://nivzadik88-ship-it.github.io/rei-da-areia/"
