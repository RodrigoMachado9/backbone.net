#!/usr/bin/env bash
# backbone.net — Cria redes virtuais isoladas no KVM/libvirt
# Uso: sudo bash scripts/create-networks.sh
set -euo pipefail

NETWORK_DIR="/tmp/backbone-net-xml"
mkdir -p "$NETWORK_DIR"

declare -A NETWORKS=(
  [net-core-link]="Link inter-core (core-dc1 <-> core-dc2)"
  [net-dc1-edgea]="core-dc1 <-> edge-a"
  [net-dc2-edgea]="core-dc2 <-> edge-a"
  [net-dc1-edgeb]="core-dc1 <-> edge-b"
  [net-dc2-edgeb]="core-dc2 <-> edge-b"
  [net-dc1-edgec]="core-dc1 <-> edge-c"
  [net-dc2-edgec]="core-dc2 <-> edge-c"
  [net-cliente-a]="LAN Cliente A (10.10.1.0/24)"
  [net-cliente-b]="LAN Cliente B (10.10.2.0/24)"
  [net-cliente-c]="LAN Cliente C (10.10.3.0/24)"
)

# Redes reservadas para fases futuras
declare -A NETWORKS_FUTURE=(
  [net-isp-fg]="ISP <-> FortiGate WAN (Fase 05)"
  [net-isp-dc2]="ISP <-> core-dc2 (Fase 05)"
  [net-fg-dc1]="FortiGate CORE <-> core-dc1 (Fase 05)"
  [net-mgmt]="Rede de gerencia FortiGate (Fase 05)"
)

echo "============================================"
echo " backbone.net — Criação de Redes Virtuais"
echo " Ambiente: KVM/libvirt"
echo "============================================"
echo ""

create_isolated_network() {
  local name="$1"
  local desc="$2"
  local bridge="br-${name#net-}"

  # Truncar nome do bridge se > 15 chars (limite do kernel)
  if [ ${#bridge} -gt 15 ]; then
    bridge="${bridge:0:15}"
  fi

  if virsh net-info "$name" &>/dev/null; then
    local state
    state=$(virsh net-info "$name" 2>/dev/null | grep "^Active:" | awk '{print $2}')
    if [ "$state" = "yes" ]; then
      echo "[OK]  $name (já ativa) — $desc"
    else
      virsh net-start "$name" >/dev/null 2>&1
      echo "[UP]  $name (iniciada) — $desc"
    fi
    return
  fi

  cat > "${NETWORK_DIR}/${name}.xml" << EOF
<network>
  <name>${name}</name>
  <bridge name='${bridge}' stp='on' delay='0'/>
</network>
EOF

  virsh net-define "${NETWORK_DIR}/${name}.xml" >/dev/null
  virsh net-start "$name" >/dev/null
  virsh net-autostart "$name" >/dev/null
  echo "[NEW] $name (criada e ativa) — $desc"
}

echo "--- Redes do Lab (Fase 01-04) ---"
for name in net-core-link net-dc1-edgea net-dc2-edgea net-dc1-edgeb net-dc2-edgeb net-dc1-edgec net-dc2-edgec net-cliente-a net-cliente-b net-cliente-c; do
  create_isolated_network "$name" "${NETWORKS[$name]}"
done

echo ""
read -p "Criar redes para fases futuras (05-07)? [s/N] " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Ss]$ ]]; then
  echo "--- Redes Futuras (Fase 05+: FortiGate + ISP) ---"
  for name in net-isp-fg net-isp-dc2 net-fg-dc1 net-mgmt; do
    create_isolated_network "$name" "${NETWORKS_FUTURE[$name]}"
  done
fi

echo ""
echo "--- Resumo ---"
virsh net-list --all | grep -E "net-|Nome"
echo ""
echo "[DONE] Redes prontas."

# Cleanup
rm -rf "$NETWORK_DIR"
