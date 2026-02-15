#!/usr/bin/env bash
set -euo pipefail

# Uso:
#   sudo ./scripts/simulate-wan.sh <iface> <delay> <jitter> <loss>
#   sudo ./scripts/simulate-wan.sh <iface> off
#
# Ex:
#   sudo ./scripts/simulate-wan.sh br-core1-edge-a 50ms 10ms 0.5%
#   sudo ./scripts/simulate-wan.sh br-core1-edge-a off

IFACE="${1:-}"
MODE="${2:-}"

if [[ -z "$IFACE" ]]; then
  echo "Uso: $0 <iface> <delay> <jitter> <loss> | $0 <iface> off"
  exit 1
fi

if [[ "$MODE" == "off" ]]; then
  echo "[INFO] Removendo netem de $IFACE..."
  tc qdisc del dev "$IFACE" root 2>/dev/null || true
  echo "[DONE] netem removido."
  exit 0
fi

DELAY="${2:-50ms}"
JITTER="${3:-10ms}"
LOSS="${4:-0.5%}"

echo "[INFO] Aplicando netem em $IFACE: delay=$DELAY jitter=$JITTER loss=$LOSS"
tc qdisc del dev "$IFACE" root 2>/dev/null || true
tc qdisc add dev "$IFACE" root netem delay "$DELAY" "$JITTER" loss "$LOSS"
echo "[DONE] netem aplicado."
