#!/bin/sh
# Build the Flutter web app and stage it into client/ for Catalyst hosting.
# Reads dart-defines from .env (API_BASE_URL, SUPABASE_URL, ...).
set -e

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_DIR=$(dirname "$SCRIPT_DIR")
CLIENT_DIR="$REPO_DIR/client"

# Turn .env into --dart-define flags
DEFINES=""
if [ -f "$REPO_DIR/.env" ]; then
    while IFS= read -r line; do
        case "$line" in
            ''|\#*) continue ;;
        esac
        DEFINES="$DEFINES --dart-define=$line"
    done < "$REPO_DIR/.env"
fi

echo "==> flutter build web"
cd "$REPO_DIR"
# Catalyst web hosting serves the client under /app/, so assets must resolve
# relative to that path or the page spins forever on a 404'd bootstrap JS.
# shellcheck disable=SC2086
flutter build web --release --base-href /app/ $DEFINES

echo "==> Staging build into $CLIENT_DIR"
# client-package.json identifies the Catalyst client app — keep it
mkdir -p "$CLIENT_DIR"
find "$CLIENT_DIR" -mindepth 1 ! -name "client-package.json" -delete
cp -R "$REPO_DIR/build/web/." "$CLIENT_DIR/"

echo "==> Client ready. Run 'catalyst deploy' to ship the web app."
