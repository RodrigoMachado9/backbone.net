##
# backbone.net — Variáveis do ambiente Lab
##

variable "vyos_iso" {
  description = "Caminho absoluto da ISO VyOS"
  type        = string
}

variable "vyos_memory" {
  description = "RAM em MB para cada VM VyOS"
  type        = number
  default     = 512
}

variable "fortigate_image" {
  description = "Caminho absoluto da imagem QCOW2 do FortiGate-VM"
  type        = string
  default     = ""
}

variable "enable_fase05" {
  description = "Habilitar recursos da Fase 05+ (ISP, FortiGate, Management)"
  type        = bool
  default     = false
}
