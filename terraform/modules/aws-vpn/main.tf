##
# backbone.net — Módulo Terraform: aws-vpn
# Cria VPC + VPN Gateway + Customer Gateway + VPN Connection
# Para a Fase 08: Site-to-Site VPN com o lab
##

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "vpc_cidr" {
  description = "CIDR da VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR da subnet pública (testes)"
  type        = string
  default     = "10.20.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR da subnet privada (workloads)"
  type        = string
  default     = "10.20.2.0/24"
}

variable "aws_region" {
  type    = string
  default = "sa-east-1"
}

variable "customer_gateway_ip" {
  description = "IP público do seu lab (FortiGate WAN ou IP do host)"
  type        = string
}

variable "customer_gateway_asn" {
  description = "ASN do backbone lab"
  type        = number
  default     = 65000
}

variable "amazon_side_asn" {
  description = "ASN do lado AWS"
  type        = number
  default     = 64512
}

variable "tags" {
  type = map(string)
  default = {
    Project     = "backbone-net"
    Environment = "lab"
    ManagedBy   = "terraform"
  }
}

# --- VPC ---
resource "aws_vpc" "lab" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.tags, { Name = "backbone-lab-vpc" })
}

# --- Subnets ---
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"
  tags                    = merge(var.tags, { Name = "backbone-lab-public" })
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.lab.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = "${var.aws_region}a"
  tags              = merge(var.tags, { Name = "backbone-lab-private" })
}

# --- Internet Gateway (para EC2 de teste na subnet pública) ---
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.lab.id
  tags   = merge(var.tags, { Name = "backbone-lab-igw" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.lab.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = merge(var.tags, { Name = "backbone-lab-public-rt" })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# --- VPN Gateway ---
resource "aws_vpn_gateway" "vgw" {
  vpc_id          = aws_vpc.lab.id
  amazon_side_asn = var.amazon_side_asn
  tags            = merge(var.tags, { Name = "backbone-lab-vgw" })
}

# --- Propagação de rotas do VPN Gateway ---
resource "aws_vpn_gateway_route_propagation" "lab" {
  vpn_gateway_id = aws_vpn_gateway.vgw.id
  route_table_id = aws_route_table.public.id
}

# --- Customer Gateway (seu lab = on-premises) ---
resource "aws_customer_gateway" "lab" {
  bgp_asn    = var.customer_gateway_asn
  ip_address = var.customer_gateway_ip
  type       = "ipsec.1"
  tags       = merge(var.tags, { Name = "backbone-lab-cgw" })
}

# --- VPN Connection (BGP dinâmico) ---
resource "aws_vpn_connection" "lab" {
  vpn_gateway_id      = aws_vpn_gateway.vgw.id
  customer_gateway_id = aws_customer_gateway.lab.id
  type                = "ipsec.1"
  static_routes_only  = false # BGP dinâmico
  tags                = merge(var.tags, { Name = "backbone-lab-vpn" })
}

# --- Outputs para configurar o lado lab ---
output "vpn_connection_id" {
  value = aws_vpn_connection.lab.id
}

output "tunnel1_address" {
  description = "IP público do endpoint AWS - Túnel 1"
  value       = aws_vpn_connection.lab.tunnel1_address
}

output "tunnel1_preshared_key" {
  description = "PSK do Túnel 1"
  value       = aws_vpn_connection.lab.tunnel1_preshared_key
  sensitive   = true
}

output "tunnel1_inside_cidr" {
  description = "CIDR inside do Túnel 1 (ex: 169.254.x.x/30)"
  value       = aws_vpn_connection.lab.tunnel1_inside_cidr
}

output "tunnel2_address" {
  description = "IP público do endpoint AWS - Túnel 2"
  value       = aws_vpn_connection.lab.tunnel2_address
}

output "tunnel2_preshared_key" {
  description = "PSK do Túnel 2"
  value       = aws_vpn_connection.lab.tunnel2_preshared_key
  sensitive   = true
}

output "tunnel2_inside_cidr" {
  description = "CIDR inside do Túnel 2 (ex: 169.254.x.x/30)"
  value       = aws_vpn_connection.lab.tunnel2_inside_cidr
}

output "vpc_id" {
  value = aws_vpc.lab.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}
