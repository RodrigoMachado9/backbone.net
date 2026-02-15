##
# backbone.net — Ambiente AWS (Fase 08)
# Cria VPC + VPN para conectar com o lab
#
# Uso:
#   terraform init
#   terraform apply -var="customer_gateway_ip=SEU_IP_PUBLICO"
#
# ATENÇÃO: Custo ~US$0.05/hora enquanto a VPN estiver ativa.
# Destrua ao terminar: terraform destroy
##

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type    = string
  default = "sa-east-1"
}

variable "customer_gateway_ip" {
  description = "IP público do seu lab (FortiGate ou host)"
  type        = string
}

module "vpn" {
  source              = "../../modules/aws-vpn"
  aws_region          = var.aws_region
  customer_gateway_ip = var.customer_gateway_ip
}

# --- Outputs para configurar o FortiGate ---
output "tunnel1_endpoint" {
  value = module.vpn.tunnel1_address
}

output "tunnel1_psk" {
  value     = module.vpn.tunnel1_preshared_key
  sensitive = true
}

output "tunnel1_inside_cidr" {
  value = module.vpn.tunnel1_inside_cidr
}

output "tunnel2_endpoint" {
  value = module.vpn.tunnel2_address
}

output "tunnel2_psk" {
  value     = module.vpn.tunnel2_preshared_key
  sensitive = true
}

output "tunnel2_inside_cidr" {
  value = module.vpn.tunnel2_inside_cidr
}

output "instructions" {
  value = <<-EOT

    =============================================
    VPN criada! Configure o FortiGate com:
    
    Tunnel 1: ${module.vpn.tunnel1_address}
    Tunnel 2: ${module.vpn.tunnel2_address}
    
    Para ver as PSKs:
      terraform output -raw tunnel1_psk
      terraform output -raw tunnel2_psk
    
    Para destruir (parar custos):
      terraform destroy
    =============================================
  EOT
}
