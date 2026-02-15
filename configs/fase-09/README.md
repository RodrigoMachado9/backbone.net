# Fase 09 - Infrastructure as Code (Terraform + Ansible)
> Toda a infra e configuracao como codigo versionado

**Status:** Pendente

### Ferramentas
- **Terraform** (provider libvirt + AWS) — provisiona VMs e redes
- **Ansible** (vyos.vyos + fortinet.fortios) — configura roteadores e firewalls
- **Makefile** — orquestra deploy, config e testes

### Resultado esperado
```bash
make deploy-fase01   # Cria infra + configura + testa = tudo automatico
make destroy         # Limpa tudo
```

Codigo Terraform e Ansible serao criados nesta fase.
