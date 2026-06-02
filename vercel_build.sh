#!/usr/bin/env bash
#
# Vercel build script for the SplitLLM Flutter web app.
#
# Vercel's build image is Node-based and has no Flutter SDK, so this script:
#   1. writes a .env (consumed by flutter_dotenv) from Vercel env vars,
#   2. installs the Flutter SDK (stable),
#   3. builds the web release into build/web (Vercel's outputDirectory).
#
# Required Vercel Environment Variables (Project Settings → Environment Variables):
#   SUPABASE_URL, SUPABASE_ANON_KEY, API_BASE_URL
set -euo pipefail

echo "==> Writing .env from environment"
cat > .env <<EOF
SUPABASE_URL=${SUPABASE_URL:-}
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY:-}
API_BASE_URL=${API_BASE_URL:-}
EOF

FLUTTER_DIR="${FLUTTER_HOME:-$HOME/flutter}"
FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-stable}"

if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  echo "==> Installing Flutter SDK ($FLUTTER_CHANNEL)"
  git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_CHANNEL" "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$PATH"

echo "==> Flutter version"
flutter --version
flutter config --enable-web --no-analytics

echo "==> Resolving dependencies"
flutter pub get

echo "==> Building web (release)"
flutter build web --release --tree-shake-icons

echo "==> Build complete: build/web"
