#!/usr/bin/env bash
set -euo pipefail

BRIDGES=(
  br-core-core
  br-core1-edge-a
  br-core2-edge-a
  br-core1-edge-b
  br-core2-edge-b
  br-core1-edge-c
  br-core2-edge-c
  br-lan-a
  br-lan-b
  br-lan-c
)

for br in "${BRIDGES[@]}"; do
  if ip link show "$br" &>/dev/null; then
    echo "[OK] Bridge já existe: $br"
  else
    echo "[INFO] Criando bridge: $br"
    ip link add name "$br" type bridge
    ip link set "$br" up
  fi
done

echo "[DONE] Bridges prontas."
