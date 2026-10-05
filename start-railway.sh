#!/bin/sh
set -e

DB="${DB_PATH:-/app/data/tokens.sqlite}"
mkdir -p "$(dirname "$DB")"

# First boot: seed the volume from the image copy if empty
if [ ! -f "$DB" ] && [ -f /app/tokens.sqlite ]; then
  cp /app/tokens.sqlite "$DB"
fi

exec /app/zai-api --db-path "$DB"
