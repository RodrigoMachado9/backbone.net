# backbone.net — Makefile de Orquestração (Fase 09)
#
# Uso:
#   make infra           Cria VMs e redes no KVM (Terraform)
#   make config-fase01   Aplica configs da Fase 01 (Ansible)
#   make deploy-fase01   Infra + Config + Testes (end-to-end)
#   make test-ospf       Verifica OSPF em todos os roteadores
#   make destroy         Destrói toda a infraestrutura
#
# Pré-requisitos:
#   - terraform, ansible instalados
#   - ansible-galaxy collection install vyos.vyos fortinet.fortios

.PHONY: help infra config-fase01 deploy-fase01 test-ospf test-bgp destroy

VYOS_ISO ?= $(HOME)/lab-backbone/iso/vyos-rolling-latest.iso

help:
	@echo "backbone.net — Comandos disponíveis:"
	@echo ""
	@echo "  make infra           Provisionar VMs e redes (Terraform)"
	@echo "  make config-fase01   Configurar Fase 01 (Ansible)"
	@echo "  make deploy-fase01   Deploy completo Fase 01"
	@echo "  make test-ospf       Testar OSPF neighbors"
	@echo "  make test-bgp        Testar BGP sessions"
	@echo "  make destroy         Destruir tudo"

infra:
	@echo "TODO: Implementar na Fase 09"

config-fase01:
	@echo "TODO: Implementar na Fase 09"

deploy-fase01: infra config-fase01 test-ospf test-bgp
	@echo "✅ Fase 01 deployed!"

test-ospf:
	@echo "TODO: Implementar na Fase 09"

test-bgp:
	@echo "TODO: Implementar na Fase 09"

destroy:
	@echo "TODO: Implementar na Fase 09"
