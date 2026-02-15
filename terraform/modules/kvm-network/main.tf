##
# backbone.net — Módulo Terraform: kvm-network
# Cria uma rede virtual isolada no KVM/libvirt (sem DHCP, sem NAT)
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
  description = "Nome da rede virtual (ex: net-core-link)"
  type        = string
}

variable "bridge_name" {
  description = "Nome da bridge Linux (max 15 chars). Se vazio, deriva do name."
  type        = string
  default     = ""
}

resource "libvirt_network" "this" {
  name      = var.name
  mode      = "none" # Isolada: sem NAT, sem DHCP — roteadores gerenciam tudo
  autostart = true

  # Bridge name (truncado a 15 chars — limite do kernel Linux)
  bridge = var.bridge_name != "" ? var.bridge_name : substr("br-${replace(var.name, "net-", "")}", 0, 15)
}

output "name" {
  value = libvirt_network.this.name
}

output "id" {
  value = libvirt_network.this.id
}

output "bridge" {
  value = libvirt_network.this.bridge
}
