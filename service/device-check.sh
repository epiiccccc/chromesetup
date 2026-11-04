#!/usr/bin/env bash
set -Eeuo pipefail

CONFIG_DIR="${HOME}/.config/chrome-setup"
CONFIG_FILE="${CONFIG_DIR}/config.sh"
ID_FILE="${CONFIG_DIR}/device-id"
CACHE_FILE="${CONFIG_DIR}/last-allowlist.txt"
TMP_FILE="${CACHE_FILE}.tmp"

close_chrome() {
  pkill -TERM -x chrome 2>/dev/null || true
  pkill -TERM -f '/opt/google/chrome/chrome' 2>/dev/null || true
  sleep 2
  pkill -KILL -x chrome 2>/dev/null || true
  pkill -KILL -f '/opt/google/chrome/chrome' 2>/dev/null || true
}

deny() {
  echo "Chrome Setup: geen geldige toestemming ($1). Chrome wordt afgesloten." >&2
  close_chrome
  exit 1
}

[[ -r "$CONFIG_FILE" ]] || deny "config ontbreekt"
# shellcheck disable=SC1090
source "$CONFIG_FILE"
[[ -n "${ALLOWLIST_URL:-}" ]] || deny "ALLOWLIST_URL is niet ingesteld"
[[ "$ALLOWLIST_URL" == https://* ]] || deny "allowlist moet via HTTPS worden opgehaald"
[[ -s "$ID_FILE" ]] || deny "apparaat-ID ontbreekt"

DEVICE_ID="$(tr -d '\\r\\n ' < "$ID_FILE")"
[[ "$DEVICE_ID" =~ ^[0-9a-fA-F-]{36}$ ]] || deny "ongeldige apparaat-ID"

# Fail closed: a fresh successful HTTPS fetch is required on every check.
if ! curl --fail --silent --show-error --location \
  --connect-timeout 8 --max-time 20 "$ALLOWLIST_URL" -o "$TMP_FILE"; then
  rm -f "$TMP_FILE"
  deny "allowlist niet bereikbaar"
fi

# Refuse empty downloads so a transient/incorrect response cannot be mistaken for a valid list.
[[ -s "$TMP_FILE" ]] || { rm -f "$TMP_FILE"; deny "lege allowlist"; }
mv "$TMP_FILE" "$CACHE_FILE"

if ! grep -Fxiq -- "$DEVICE_ID" "$CACHE_FILE"; then
  deny "apparaat-ID staat niet in allowlist"
fi

echo "Chrome Setup: apparaat is toegestaan."
