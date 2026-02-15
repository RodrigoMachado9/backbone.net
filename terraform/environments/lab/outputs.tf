##
# backbone.net — Outputs do ambiente Lab
##

output "vyos_vms" {
  description = "VMs VyOS criadas"
  value = {
    core_dc1 = module.core_dc1.name
    core_dc2 = module.core_dc2.name
    edge_a   = module.edge_a.name
    edge_b   = module.edge_b.name
    edge_c   = module.edge_c.name
  }
}

output "networks" {
  description = "Redes virtuais criadas"
  value = {
    core_link = module.net_core_link.name
    dc1_edgea = module.net_dc1_edgea.name
    dc2_edgea = module.net_dc2_edgea.name
    dc1_edgeb = module.net_dc1_edgeb.name
    dc2_edgeb = module.net_dc2_edgeb.name
    dc1_edgec = module.net_dc1_edgec.name
    dc2_edgec = module.net_dc2_edgec.name
    cliente_a = module.net_cliente_a.name
    cliente_b = module.net_cliente_b.name
    cliente_c = module.net_cliente_c.name
  }
}

output "fortigate" {
  description = "FortiGate VM (se habilitado)"
  value       = var.enable_fase05 ? module.fg_edge[0].name : "não habilitado"
}
