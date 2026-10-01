#!/bin/sh
set -eu

# Dokploy supplies environment variables only when the container starts.
# Generate a small public runtime config file so browser code can use the API
# URL without depending on Docker build arguments.
node -e 'const fs = require("fs"); const apiUrl = process.env.API_BASE_URL || process.env.NEXT_PUBLIC_API_BASE_URL || ""; fs.writeFileSync("/app/public/runtime-config.js", `window.__APP_CONFIG__ = ${JSON.stringify({ apiBaseUrl: apiUrl })};\n`);'

exec "$@"
