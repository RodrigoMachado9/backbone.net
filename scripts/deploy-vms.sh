#!/usr/bin/env bash
# backbone.net — Cria VMs VyOS no KVM/libvirt
# Uso: bash scripts/deploy-vms.sh [--iso /caminho/vyos.iso]
set -euo pipefail

# === CONFIGURAÇÕES ===
VYOS_ISO="${VYOS_ISO:-$HOME/lab-backbone/iso/vyos-rolling-latest.iso}"
DISK_DIR="${DISK_DIR:-$HOME/lab-backbone/disks}"
RAM_MB=512
VCPUS=1
DISK_SIZE="4G"

# Parse argumentos
while [[ $# -gt 0 ]]; do
  case $1 in
    --iso) VYOS_ISO="$2"; shift 2;;
    --disk-dir) DISK_DIR="$2"; shift 2;;
    --ram) RAM_MB="$2"; shift 2;;
    *) echo "Uso: $0 [--iso caminho.iso] [--disk-dir dir] [--ram MB]"; exit 1;;
  esac
done

echo "============================================"
echo " backbone.net — Deploy de VMs"
echo " ISO:    $VYOS_ISO"
echo " Discos: $DISK_DIR"
echo " RAM:    ${RAM_MB}MB | vCPUs: $VCPUS"
echo "============================================"
echo ""

# Validações
if [ ! -f "$VYOS_ISO" ]; then
  echo "[ERRO] ISO não encontrada: $VYOS_ISO"
  echo "       Baixe de: https://vyos.net/get/"
  echo "       Ou defina: export VYOS_ISO=/caminho/vyos.iso"
  exit 1
fi

for cmd in virt-install virsh qemu-img; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "[ERRO] Comando não encontrado: $cmd"
    echo "       Instale: sudo apt install qemu-kvm libvirt-daemon-system virtinst"
    exit 1
  fi
done

mkdir -p "$DISK_DIR"

create_vm() {
  local name="$1"; shift
  local disk="${DISK_DIR}/${name}.qcow2"

  if virsh dominfo "$name" &>/dev/null; then
    echo "[OK]  VM já existe: $name"
    return
  fi

  echo "[NEW] Criando VM: $name"

  if [ ! -f "$disk" ]; then
    qemu-img create -f qcow2 "$disk" "$DISK_SIZE" >/dev/null
  fi

  virt-install \
    --name "$name" \
    --ram "$RAM_MB" \
    --vcpus "$VCPUS" \
    --disk "path=$disk,format=qcow2,bus=virtio" \
    --cdrom "$VYOS_ISO" \
    --osinfo detect=on,require=off \
    --graphics vnc,listen=127.0.0.1 \
    --noautoconsole \
    "$@"

  echo "       → Criada. Console: virt-manager ou 'sudo virsh console $name'"
  echo "       → VNC acessível apenas via localhost (segurança)."
  echo "         Para acesso remoto, use SSH tunnel: ssh -L 5900:127.0.0.1:5900 user@host"
}

echo "--- Criando VMs ---"
echo ""

# IMPORTANTE: A ordem dos --network define eth0, eth1, eth2...
# Deve corresponder ao mapeamento nos configs/*.vyos

create_vm core-dc1 \
  --network network=net-core-link,model=virtio \
  --network network=net-dc1-edgea,model=virtio \
  --network network=net-dc1-edgeb,model=virtio \
  --network network=net-dc1-edgec,model=virtio

create_vm core-dc2 \
  --network network=net-core-link,model=virtio \
  --network network=net-dc2-edgea,model=virtio \
  --network network=net-dc2-edgeb,model=virtio \
  --network network=net-dc2-edgec,model=virtio

create_vm edge-a \
  --network network=net-dc1-edgea,model=virtio \
  --network network=net-dc2-edgea,model=virtio \
  --network network=net-cliente-a,model=virtio

create_vm edge-b \
  --network network=net-dc1-edgeb,model=virtio \
  --network network=net-dc2-edgeb,model=virtio \
  --network network=net-cliente-b,model=virtio

create_vm edge-c \
  --network network=net-dc1-edgec,model=virtio \
  --network network=net-dc2-edgec,model=virtio \
  --network network=net-cliente-c,model=virtio

echo ""
echo "--- Mapeamento de Interfaces ---"
echo ""
echo "  core-dc1: eth0=core-link  eth1=dc1-edgea  eth2=dc1-edgeb  eth3=dc1-edgec"
echo "  core-dc2: eth0=core-link  eth1=dc2-edgea  eth2=dc2-edgeb  eth3=dc2-edgec"
echo "  edge-a:   eth0=dc1-edgea  eth1=dc2-edgea  eth2=cliente-a"
echo "  edge-b:   eth0=dc1-edgeb  eth1=dc2-edgeb  eth2=cliente-b"
echo "  edge-c:   eth0=dc1-edgec  eth1=dc2-edgec  eth2=cliente-c"
echo ""
echo "--- Próximos passos ---"
echo ""
echo "  1. Abra o virt-manager e conecte ao console de cada VM"
echo "  2. Login: vyos / vyos"
echo "  3. Execute: install image (siga o assistente)"
echo "  4. Após instalar: poweroff"
echo "  5. Remova o CDROM (Edit > VM Details > IDE CDROM > Disconnect)"
echo "  6. Inicie a VM e aplique o config correspondente"
echo ""
echo "[DONE] VMs criadas."
