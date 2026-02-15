##
# backbone.net — Módulo Terraform: kvm-vyos
# Cria uma VM VyOS no KVM/libvirt
# A ordem dos network_interface define eth0, eth1, eth2...
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
  description = "Nome da VM (ex: core-dc1)"
  type        = string
}

variable "memory" {
  description = "RAM em MB"
  type        = number
  default     = 512
}

variable "vcpu" {
  description = "Número de vCPUs"
  type        = number
  default     = 1
}

variable "iso_path" {
  description = "Caminho absoluto da ISO VyOS"
  type        = string
}

variable "disk_size_bytes" {
  description = "Tamanho do disco em bytes (default 4GB)"
  type        = number
  default     = 4294967296
}

variable "pool" {
  description = "Storage pool do libvirt"
  type        = string
  default     = "default"
}

variable "networks" {
  description = "Lista ordenada de nomes de redes (define eth0, eth1, eth2...)"
  type        = list(string)
}

variable "autostart" {
  description = "Iniciar VM automaticamente com o host"
  type        = bool
  default     = false
}

# --- Disco ---
resource "libvirt_volume" "disk" {
  name   = "${var.name}.qcow2"
  pool   = var.pool
  format = "qcow2"
  size   = var.disk_size_bytes
}

# --- VM ---
resource "libvirt_domain" "vm" {
  name      = var.name
  memory    = var.memory
  vcpu      = var.vcpu
  autostart = var.autostart

  # Disco principal
  disk {
    volume_id = libvirt_volume.disk.id
  }

  # CDROM (ISO VyOS para instalação)
  disk {
    file = var.iso_path
  }

  # Interfaces de rede (ordem = eth0, eth1, eth2...)
  dynamic "network_interface" {
    for_each = var.networks
    content {
      network_name   = network_interface.value
      wait_for_lease = false
    }
  }

  # Console serial (para virsh console)
  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  # VNC (para virt-manager)
  graphics {
    type        = "vnc"
    listen_type = "address"
  }

  # Não destruir disco ao deletar VM (segurança)
  lifecycle {
    prevent_destroy = false
  }
}

# --- Outputs ---
output "name" {
  value = libvirt_domain.vm.name
}

output "id" {
  value = libvirt_domain.vm.id
}
