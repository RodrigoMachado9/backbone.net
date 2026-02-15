#!/usr/bin/env bash
# backbone.net — Controle do lab (start/stop/snapshot/restore/status)
# Uso: bash scripts/lab-control.sh <comando> [args]
set -euo pipefail

VMS=(core-dc1 core-dc2 edge-a edge-b edge-c)

usage() {
  echo "Uso: $0 <comando> [args]"
  echo ""
  echo "Comandos:"
  echo "  status              Status de todas as VMs"
  echo "  start               Iniciar todas as VMs"
  echo "  stop                Parar todas as VMs (graceful)"
  echo "  force-stop          Forçar parada de todas as VMs"
  echo "  console <vm>        Abrir console de uma VM"
  echo "  snapshot <nome>     Criar snapshot de todas as VMs"
  echo "  restore <nome>      Restaurar snapshot de todas as VMs"
  echo "  list-snapshots      Listar snapshots disponíveis"
  echo "  destroy             Destruir todas as VMs (CUIDADO!)"
  echo ""
  echo "VMs: ${VMS[*]}"
  exit 1
}

CMD="${1:-}"
[ -z "$CMD" ] && usage

case "$CMD" in
  status)
    echo "--- Status das VMs ---"
    printf "%-15s %-12s %-8s\n" "VM" "Estado" "vCPUs"
    echo "------------------------------------"
    for vm in "${VMS[@]}"; do
      if virsh dominfo "$vm" &>/dev/null; then
        state=$(virsh domstate "$vm" 2>/dev/null)
        vcpus=$(virsh dominfo "$vm" 2>/dev/null | grep "CPU(s):" | awk '{print $2}')
        printf "%-15s %-12s %-8s\n" "$vm" "$state" "$vcpus"
      else
        printf "%-15s %-12s\n" "$vm" "não existe"
      fi
    done
    echo ""
    echo "--- Redes ---"
    virsh net-list --all 2>/dev/null | grep -E "net-|Nome" || echo "Nenhuma rede do lab encontrada"
    ;;

  start)
    echo "Iniciando VMs..."
    for vm in "${VMS[@]}"; do
      state=$(virsh domstate "$vm" 2>/dev/null || echo "undefined")
      if [ "$state" = "running" ]; then
        echo "  [OK]  $vm (já rodando)"
      elif [ "$state" = "shut off" ]; then
        virsh start "$vm" >/dev/null
        echo "  [UP]  $vm"
      else
        echo "  [??]  $vm (estado: $state)"
      fi
    done
    echo "[DONE]"
    ;;

  stop)
    echo "Parando VMs (graceful)..."
    for vm in "${VMS[@]}"; do
      state=$(virsh domstate "$vm" 2>/dev/null || echo "undefined")
      if [ "$state" = "running" ]; then
        virsh shutdown "$vm" >/dev/null
        echo "  [DOWN] $vm (shutdown enviado)"
      else
        echo "  [OK]   $vm (já parada)"
      fi
    done
    echo "[DONE] Aguarde ~30s para desligamento completo."
    ;;

  force-stop)
    echo "Forçando parada..."
    for vm in "${VMS[@]}"; do
      virsh destroy "$vm" 2>/dev/null && echo "  [KILL] $vm" || echo "  [OK]   $vm (já parada)"
    done
    ;;

  console)
    vm="${2:-}"
    [ -z "$vm" ] && echo "Uso: $0 console <vm>" && exit 1
    echo "Conectando ao console de $vm (Ctrl+] para sair)..."
    virsh console "$vm"
    ;;

  snapshot)
    snap_name="${2:-}"
    [ -z "$snap_name" ] && echo "Uso: $0 snapshot <nome>" && exit 1
    echo "Criando snapshot '$snap_name' em todas as VMs..."
    for vm in "${VMS[@]}"; do
      virsh snapshot-create-as "$vm" "$snap_name" --description "backbone.net: $snap_name" >/dev/null 2>&1 \
        && echo "  [OK] $vm" \
        || echo "  [!!] $vm (falhou — VM precisa estar parada ou usar qcow2)"
    done
    echo "[DONE]"
    ;;

  restore)
    snap_name="${2:-}"
    [ -z "$snap_name" ] && echo "Uso: $0 restore <nome>" && exit 1
    echo "Restaurando snapshot '$snap_name'..."
    for vm in "${VMS[@]}"; do
      virsh snapshot-revert "$vm" "$snap_name" 2>/dev/null \
        && echo "  [OK] $vm" \
        || echo "  [!!] $vm (snapshot não encontrado)"
    done
    echo "[DONE]"
    ;;

  list-snapshots)
    for vm in "${VMS[@]}"; do
      echo "--- $vm ---"
      virsh snapshot-list "$vm" 2>/dev/null || echo "  Nenhum snapshot"
      echo ""
    done
    ;;

  destroy)
    echo "⚠️  ATENÇÃO: Isso vai DESTRUIR todas as VMs e seus discos!"
    read -p "Tem certeza? Digite 'sim' para confirmar: " confirm
    if [ "$confirm" = "sim" ]; then
      for vm in "${VMS[@]}"; do
        virsh destroy "$vm" 2>/dev/null || true
        virsh undefine "$vm" --remove-all-storage 2>/dev/null \
          && echo "  [DEL] $vm" \
          || echo "  [??]  $vm"
      done
      echo "[DONE] VMs destruídas."
    else
      echo "Cancelado."
    fi
    ;;

  *)
    usage
    ;;
esac
