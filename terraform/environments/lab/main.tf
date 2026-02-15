##
# backbone.net — Ambiente Lab (KVM local)
# Provisiona todas as redes e VMs do backbone
#
# Uso:
#   terraform init
#   terraform plan -var-file="terraform.tfvars"
#   terraform apply -var-file="terraform.tfvars"
##

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

# ============================================================
# REDES VIRTUAIS
# ============================================================

# Backbone (Fase 01)
module "net_core_link" {
  source = "../../modules/kvm-network"
  name   = "net-core-link"
}

module "net_dc1_edgea" {
  source = "../../modules/kvm-network"
  name   = "net-dc1-edgea"
}

module "net_dc2_edgea" {
  source = "../../modules/kvm-network"
  name   = "net-dc2-edgea"
}

module "net_dc1_edgeb" {
  source = "../../modules/kvm-network"
  name   = "net-dc1-edgeb"
}

module "net_dc2_edgeb" {
  source = "../../modules/kvm-network"
  name   = "net-dc2-edgeb"
}

module "net_dc1_edgec" {
  source = "../../modules/kvm-network"
  name   = "net-dc1-edgec"
}

module "net_dc2_edgec" {
  source = "../../modules/kvm-network"
  name   = "net-dc2-edgec"
}

# LANs de clientes
module "net_cliente_a" {
  source = "../../modules/kvm-network"
  name   = "net-cliente-a"
}

module "net_cliente_b" {
  source = "../../modules/kvm-network"
  name   = "net-cliente-b"
}

module "net_cliente_c" {
  source = "../../modules/kvm-network"
  name   = "net-cliente-c"
}

# FortiGate + ISP (Fase 05+)
module "net_isp_fg" {
  source = "../../modules/kvm-network"
  name   = "net-isp-fg"
  count  = var.enable_fase05 ? 1 : 0
}

module "net_isp_dc2" {
  source = "../../modules/kvm-network"
  name   = "net-isp-dc2"
  count  = var.enable_fase05 ? 1 : 0
}

module "net_fg_dc1" {
  source = "../../modules/kvm-network"
  name   = "net-fg-dc1"
  count  = var.enable_fase05 ? 1 : 0
}

module "net_mgmt" {
  source = "../../modules/kvm-network"
  name   = "net-mgmt"
  count  = var.enable_fase05 ? 1 : 0
}

# ============================================================
# VMs VyOS
# ============================================================

module "core_dc1" {
  source   = "../../modules/kvm-vyos"
  name     = "core-dc1"
  iso_path = var.vyos_iso
  memory   = var.vyos_memory
  networks = [
    module.net_core_link.name,
    module.net_dc1_edgea.name,
    module.net_dc1_edgeb.name,
    module.net_dc1_edgec.name,
  ]
}

module "core_dc2" {
  source   = "../../modules/kvm-vyos"
  name     = "core-dc2"
  iso_path = var.vyos_iso
  memory   = var.vyos_memory
  networks = [
    module.net_core_link.name,
    module.net_dc2_edgea.name,
    module.net_dc2_edgeb.name,
    module.net_dc2_edgec.name,
  ]
}

module "edge_a" {
  source   = "../../modules/kvm-vyos"
  name     = "edge-a"
  iso_path = var.vyos_iso
  memory   = var.vyos_memory
  networks = [
    module.net_dc1_edgea.name,
    module.net_dc2_edgea.name,
    module.net_cliente_a.name,
  ]
}

module "edge_b" {
  source   = "../../modules/kvm-vyos"
  name     = "edge-b"
  iso_path = var.vyos_iso
  memory   = var.vyos_memory
  networks = [
    module.net_dc1_edgeb.name,
    module.net_dc2_edgeb.name,
    module.net_cliente_b.name,
  ]
}

module "edge_c" {
  source   = "../../modules/kvm-vyos"
  name     = "edge-c"
  iso_path = var.vyos_iso
  memory   = var.vyos_memory
  networks = [
    module.net_dc1_edgec.name,
    module.net_dc2_edgec.name,
    module.net_cliente_c.name,
  ]
}

# ISP Upstream (Fase 05+)
module "isp_upstream" {
  source   = "../../modules/kvm-vyos"
  name     = "isp-upstream"
  iso_path = var.vyos_iso
  memory   = var.vyos_memory
  count    = var.enable_fase05 ? 1 : 0
  networks = [
    module.net_isp_fg[0].name,
    module.net_isp_dc2[0].name,
  ]
}

# ============================================================
# FortiGate VM (Fase 05+)
# ============================================================

module "fg_edge" {
  source          = "../../modules/kvm-fortigate"
  name            = "fg-edge"
  base_image_path = var.fortigate_image
  count           = var.enable_fase05 ? 1 : 0
  networks = [
    module.net_isp_fg[0].name,   # port1 = WAN (ISP)
    module.net_fg_dc1[0].name,   # port2 = CORE (core-dc1)
    module.net_mgmt[0].name,     # port3 = MGMT
  ]
}
