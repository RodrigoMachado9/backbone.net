##
# backbone.net — Módulo Terraform: kvm-fortigate
# Cria uma VM FortiGate no KVM/libvirt
# Requer: imagem FortiGate-VM64-KVM (QCOW2)
# Nota: FortiGate usa QCOW2 direto, não ISO
##

terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7"
    }
  }
}

variable "name" {
  description = "Nome da VM (ex: fg-edge)"
  type        = string
  default     = "fg-edge"
}

variable "memory" {
  description = "RAM em MB (mínimo 2048 para FortiGate)"
  type        = number
  default     = 2048
}

variable "vcpu" {
  description = "Número de vCPUs (max 1 na licença trial)"
  type        = number
  default     = 1
}

variable "base_image_path" {
  description = "Caminho da imagem QCOW2 base do FortiGate-VM"
  type        = string
}

variable "pool" {
  description = "Storage pool do libvirt"
  type        = string
  default     = "default"
}

variable "networks" {
  description = "Lista ordenada de nomes de redes (define port1, port2, port3). Max 3 na trial."
  type        = list(string)
  validation {
    condition     = length(var.networks) <= 3
    error_message = "Licença trial do FortiGate permite no máximo 3 interfaces."
  }
}

variable "autostart" {
  type    = bool
  default = false
}

# --- Disco (clone da imagem base) ---
resource "libvirt_volume" "boot_disk" {
  name             = "${var.name}-boot.qcow2"
  pool             = var.pool
  format           = "qcow2"
  base_volume_name = basename(var.base_image_path)
}

# --- Log disk (FortiGate precisa para logging) ---
resource "libvirt_volume" "log_disk" {
  name   = "${var.name}-log.qcow2"
  pool   = var.pool
  format = "qcow2"
  size   = 2147483648 # 2GB
}

# --- VM ---
resource "libvirt_domain" "vm" {
  name      = var.name
  memory    = var.memory
  vcpu      = var.vcpu
  autostart = var.autostart

  disk {
    volume_id = libvirt_volume.boot_disk.id
  }

  disk {
    volume_id = libvirt_volume.log_disk.id
  }

  # Interfaces (port1, port2, port3)
  dynamic "network_interface" {
    for_each = var.networks
    content {
      network_name   = network_interface.value
      wait_for_lease = false
    }
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
  }
}

output "name" {
  value = libvirt_domain.vm.name
}

output "id" {
  value = libvirt_domain.vm.id
}
