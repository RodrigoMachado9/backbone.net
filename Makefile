# backbone.net — Makefile
#
# Orquestra Terraform (infra) + Ansible (config) + testes
#
# Pré-requisitos:
#   sudo apt install terraform ansible
#   ansible-galaxy collection install vyos.vyos fortinet.fortios
#
# Início rápido:
#   cp terraform/environments/lab/terraform.tfvars.example terraform/environments/lab/terraform.tfvars
#   # edite com seus caminhos
#   make deploy-fase01

.PHONY: help infra infra-plan infra-destroy \
        config-fase01 config-fase02 config-fase05 config-all \
        test-ospf test-bgp test-ping test-routes validate \
        deploy-fase01 deploy-fase02 \
        status destroy clean

TF_DIR        := terraform/environments/lab
TF_AWS_DIR    := terraform/environments/aws
ANSIBLE_DIR   := ansible

# ==============================================================
# HELP
# ==============================================================
help:
	@echo ""
	@echo "  backbone.net — Comandos"
	@echo "  ======================="
	@echo ""
	@echo "  Infraestrutura (Terraform):"
	@echo "    make infra             Criar VMs e redes no KVM"
	@echo "    make infra-plan        Ver o que será criado"
	@echo "    make infra-destroy     Destruir VMs e redes"
	@echo ""
	@echo "  Configuração (Ansible):"
	@echo "    make config-fase01     Aplicar Fase 01 (OSPF + iBGP)"
	@echo "    make config-fase02     Aplicar Fase 02 (Loopbacks)"
	@echo "    make config-fase05     Aplicar Fase 05 (FortiGate + ISP)"
	@echo "    make config-all        Aplicar todas as configs"
	@echo ""
	@echo "  Testes:"
	@echo "    make validate          Rodar todos os testes"
	@echo "    make test-ospf         Verificar OSPF"
	@echo "    make test-bgp          Verificar BGP"
	@echo "    make test-ping         Testar conectividade"
	@echo "    make test-routes       Mostrar tabelas de rota"
	@echo ""
	@echo "  Deploy completo:"
	@echo "    make deploy-fase01     Infra + Config + Teste (Fase 01)"
	@echo "    make deploy-fase02     Infra + Config + Teste (Fase 02)"
	@echo ""
	@echo "  AWS (Fase 08):"
	@echo "    make aws-infra IP=x.x.x.x    Criar VPC + VPN na AWS"
	@echo "    make aws-destroy              Destruir recursos AWS"
	@echo ""
	@echo "  Lifecycle:"
	@echo "    make status            Status das VMs"
	@echo "    make destroy           Destruir tudo (KVM)"
	@echo "    make clean             Destruir + limpar state"
	@echo ""

# ==============================================================
# TERRAFORM — Infraestrutura
# ==============================================================
infra:
	@echo "🔧 Criando infraestrutura..."
	cd $(TF_DIR) && terraform init -input=false && \
	terraform apply -auto-approve
	@echo "✅ Infraestrutura criada."

infra-plan:
	cd $(TF_DIR) && terraform init -input=false && \
	terraform plan

infra-destroy:
	cd $(TF_DIR) && terraform destroy -auto-approve

# ==============================================================
# ANSIBLE — Configuração
# ==============================================================
config-fase01:
	@echo "⚙️  Aplicando Fase 01..."
	cd $(ANSIBLE_DIR) && ansible-playbook playbooks/fase-01.yml
	@echo "✅ Fase 01 configurada."

config-fase02:
	@echo "⚙️  Aplicando Fase 02..."
	cd $(ANSIBLE_DIR) && ansible-playbook playbooks/fase-02.yml
	@echo "✅ Fase 02 configurada."

config-fase05:
	@echo "⚙️  Aplicando Fase 05 (FortiGate + ISP)..."
	cd $(ANSIBLE_DIR) && ansible-playbook playbooks/fase-05.yml
	@echo "✅ Fase 05 configurada."

config-all:
	@echo "⚙️  Aplicando todas as configurações..."
	cd $(ANSIBLE_DIR) && ansible-playbook playbooks/site.yml
	@echo "✅ Todas as fases configuradas."

# ==============================================================
# TESTES
# ==============================================================
validate:
	cd $(ANSIBLE_DIR) && ansible-playbook playbooks/validate.yml --tags all

test-ospf:
	cd $(ANSIBLE_DIR) && ansible-playbook playbooks/validate.yml --tags ospf

test-bgp:
	cd $(ANSIBLE_DIR) && ansible-playbook playbooks/validate.yml --tags bgp

test-ping:
	cd $(ANSIBLE_DIR) && ansible-playbook playbooks/validate.yml --tags ping

test-routes:
	cd $(ANSIBLE_DIR) && ansible-playbook playbooks/validate.yml --tags routes

# ==============================================================
# DEPLOY COMPLETO (Infra + Config + Teste)
# ==============================================================
deploy-fase01: infra config-fase01
	@echo "🧪 Validando..."
	@$(MAKE) validate
	@echo ""
	@echo "🎉 Fase 01 deployed and validated!"

deploy-fase02: infra config-fase02
	@echo "🧪 Validando..."
	@$(MAKE) validate
	@echo ""
	@echo "🎉 Fase 02 deployed and validated!"

# ==============================================================
# AWS (Fase 08)
# ==============================================================
aws-infra:
ifndef IP
	$(error Uso: make aws-infra IP=seu.ip.publico)
endif
	cd $(TF_AWS_DIR) && terraform init -input=false && \
	terraform apply -var="customer_gateway_ip=$(IP)" -auto-approve
	@echo ""
	@echo "✅ VPN AWS criada."
	cd $(TF_AWS_DIR) && terraform output

aws-destroy:
	cd $(TF_AWS_DIR) && terraform destroy -auto-approve
	@echo "✅ Recursos AWS destruídos."

# ==============================================================
# LIFECYCLE
# ==============================================================
status:
	@bash scripts/lab-control.sh status

destroy: infra-destroy
	@echo "✅ Lab destruído."

clean: destroy
	rm -rf $(TF_DIR)/.terraform $(TF_DIR)/terraform.tfstate*
	rm -rf $(TF_AWS_DIR)/.terraform $(TF_AWS_DIR)/terraform.tfstate*
	@echo "✅ State limpo."
