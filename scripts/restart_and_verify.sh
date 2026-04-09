#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="/root/CPA-X/.env"
CPA_URL="http://127.0.0.1:8317"
PANEL_URL="http://127.0.0.1:8080"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing env file: $ENV_FILE" >&2
  exit 1
fi

get_env() {
  local key="$1"
  local line
  line="$(grep -E "^${key}=" "$ENV_FILE" | tail -n 1 || true)"
  printf '%s' "${line#*=}"
}

MGMT_KEY="$(get_env CLIPROXY_PANEL_MANAGEMENT_KEY)"
MODELS_KEY="$(get_env CLIPROXY_PANEL_MODELS_API_KEY)"
PANEL_KEY="$(get_env CLIPROXY_PANEL_PANEL_ACCESS_KEY)"

echo "[1/4] Restarting cpa"
systemctl restart cpa
sleep 3

echo "[2/4] Restarting cliproxy-panel"
systemctl restart cliproxy-panel
sleep 2

echo "[3/4] Service status"
systemctl --no-pager --full status cpa cliproxy-panel

echo
echo "[4/4] Verifying endpoints"

curl -sS -o /dev/null -w 'mgmt: %{http_code}\n' \
  -H "X-Management-Key: ${MGMT_KEY}" \
  "${CPA_URL}/v0/management/usage"

curl -sS -o /dev/null -w 'models: %{http_code}\n' \
  -H "Authorization: Bearer ${MODELS_KEY}" \
  "${CPA_URL}/v1/models"

curl -sS \
  -H "X-Panel-Key: ${PANEL_KEY}" \
  "${PANEL_URL}/api/status" | head -c 1000

echo
echo
echo "Done."
