#!/bin/bash
# Simple auto-refill for tokens.sqlite
# Usage: bash token_watchdog.sh

TARGET="${TARGET:-150}"
REFILL_BELOW="${REFILL_BELOW:-80}"
CHECK_EVERY="${CHECK_EVERY:-120}"
DB="${DB_PATH:-./tokens.sqlite}"
COLLECTOR="${COLLECTOR_BIN:-./token-collector}"
LOG="${LOG_FILE:-./watchdog.log}"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"; }

count_tokens() {
  python3 - "$DB" <<'PY' 2>/dev/null || echo -1
import sqlite3, sys
try:
    con = sqlite3.connect("file:" + sys.argv[1] + "?mode=ro", uri=True)
    print(con.execute("SELECT COUNT(*) FROM tokens").fetchone()[0])
    con.close()
except Exception:
    print(-1)
PY
}

log "Watchdog started | target=$TARGET | refill_below=\( REFILL_BELOW | every= \){CHECK_EVERY}s"

while true; do
  pool=$(count_tokens)

  if [ "$pool" -lt 0 ]; then
    log "WARN: could not read $DB — retrying next cycle"
    sleep "$CHECK_EVERY"
    continue
  fi

  if [ "$pool" -lt "$REFILL_BELOW" ]; then
    need=$((TARGET - pool))
    [ "$need" -gt 200 ] && need=200
    log "pool=$pool below $REFILL_BELOW → topping up +$need tokens (--topup)"
    "$COLLECTOR" --topup --no-tui --tokens "$need" --batch 1 --parallel 1 >> "$LOG" 2>&1
    rc=$?
    after=$(count_tokens)
    log "REFILL done (rc=$rc) pool $pool → $after"
  else
    if [ $((RANDOM % 15)) -eq 0 ]; then
      log "pool=$pool ok"
    fi
  fi

  sleep "$CHECK_EVERY"
done
