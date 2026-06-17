#!/usr/bin/env sh
set -eu

# Configurable PDF base name — single source of truth in params.toml
PREFIX=$(sed -nE 's/^cvPdfPrefix[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/p' config/_default/params.toml)
[ -n "$PREFIX" ] || { echo "cvPdfPrefix not found in config/_default/params.toml" >&2; exit 1; }

# Build the static site (extra args pass through, e.g. --baseURL in CI)
hugo --gc --minify "$@"

# Serve public/ on a throwaway port so WeasyPrint resolves root-relative CSS (/css/...)
PORT=8919
python3 -m http.server "$PORT" --directory public >/dev/null 2>&1 &
SERVER_PID=$!
trap 'kill "$SERVER_PID" 2>/dev/null || true' EXIT

# Wait until the server answers
until wget -q -O /dev/null "http://127.0.0.1:$PORT/" 2>/dev/null; do sleep 0.2; done

# Render both language variants (fr at root, en under /en/)
weasyprint "http://127.0.0.1:$PORT/cv/"    "public/${PREFIX}.fr.pdf"
weasyprint "http://127.0.0.1:$PORT/en/cv/" "public/${PREFIX}.en.pdf"
