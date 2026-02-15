# Backbone.net — Lab de Backbone L3

<p align="center">
  <img alt="OS" src="https://img.shields.io/badge/OS-Ubuntu_24.04-E95420?logo=ubuntu&logoColor=white">
  <img alt="Hypervisor" src="https://img.shields.io/badge/Hypervisor-KVM%2Fvirt--manager-blue">
  <img alt="RouterOS" src="https://img.shields.io/badge/RouterOS-VyOS_1.4+-orange">
  <img alt="Routing" src="https://img.shields.io/badge/Routing-OSPF%20%2B%20iBGP%20(AS%2065000)-green">
  <img alt="Fase" src="https://img.shields.io/badge/Fase_atual-01-red">
  <img alt="Custo" src="https://img.shields.io/badge/Custo-R%24%200-success">
</p>

> Lab progressivo para aprender arquitetura de backbone — de OSPF básico até MPLS L3VPN,
> peering eBGP, segurança e observabilidade. 100% virtualizado no KVM.

---

## Roadmap (7 fases)

| Fase | Nome | Tecnologias | Status |
|------|------|-------------|--------|
| 01 | Fundação | OSPF, iBGP, KVM | 🔄 Em andamento |
| 02 | Resiliência | Loopbacks, failover | ⏳ Pendente |
| 03 | MPLS Core | LDP, label switching | ⏳ Pendente |
| 04 | L3VPN | MP-BGP, VPNv4, VRF | ⏳ Pendente |
| 05 | Peering Externo | eBGP, políticas, communities | ⏳ Pendente |
| 06 | Segurança | Firewall, CoPP, uRPF | ⏳ Pendente |
| 07 | Observabilidade | SNMP, Grafana, NetFlow | ⏳ Pendente |

**Roadmap completo:** [`docs/roadmap/ROADMAP.md`](docs/roadmap/ROADMAP.md)

---

## Topologia (Fase 01)

```
         [core-dc1] -------- [core-dc2]
          /   |   \           /   |   \
     [edge-a] [edge-b] [edge-c]
      LAN-A    LAN-B    LAN-C
```

- **Core**: `core-dc1` e `core-dc2` — iBGP AS 65000
- **Edges**: `edge-a`, `edge-b`, `edge-c` — OSPF Area 0
- **Redundância**: cada edge conecta aos dois cores

### Endereçamento

| Tipo | Faixa |
|------|-------|
| Links backbone P2P | 10.255.0.0/16 (sub-redes /30) |
| Loopbacks (fase 02) | 10.0.0.0/24 |
| LANs clientes | 10.10.1.0/24, 10.10.2.0/24, 10.10.3.0/24 |

Detalhe: [`docs/architecture/addressing-plan.md`](docs/architecture/addressing-plan.md)

---

## Pré-requisitos

- Ubuntu 24.04 LTS
- KVM + virt-manager (`sudo apt install qemu-kvm libvirt-daemon-system virt-manager`)
- VyOS ISO (rolling ou 1.4 LTS)
- ~4GB RAM livre (512MB por VM × 5)
- Virtualização habilitada na BIOS (VT-x / AMD-V)

---

## Quickstart

```bash
# 1. Verificar KVM
kvm-ok

# 2. Criar redes virtuais
sudo bash scripts/create-networks.sh

# 3. Criar VMs
bash scripts/deploy-vms.sh

# 4. Instalar VyOS em cada VM (via console)
sudo virsh console core-dc1
# login: vyos / vyos → install image → poweroff → remover CDROM → start

# 5. Aplicar configs da fase atual
# Copie o conteúdo de configs/fase-01/*.vyos no modo configure de cada VM
```

---

## Estrutura do Projeto

```
backbone.net/
├── configs/
│   ├── fase-01/          # Configs OSPF + iBGP básico
│   ├── fase-02/          # + Loopbacks + BGP resiliente
│   ├── fase-03/          # + MPLS LDP
│   ├── fase-04/          # + L3VPN (VRF + MP-BGP)
│   ├── fase-05/          # + eBGP + ISP upstream
│   ├── fase-06/          # + Firewall + Segurança
│   └── fase-07/          # + SNMP + Monitoramento
├── scripts/
│   ├── create-networks.sh  # Cria redes virtuais no KVM
│   ├── deploy-vms.sh       # Cria as VMs com virt-install
│   ├── lab-control.sh      # Start/stop/snapshot do lab
│   └── simulate-wan.sh     # Simula latência/jitter com tc netem
├── docs/
│   ├── roadmap/ROADMAP.md
│   ├── architecture/
│   ├── operations/
│   └── executive/
└── diagrams/
```

---

## Documentação

| Doc | Descrição |
|-----|-----------|
| [Roadmap](docs/roadmap/ROADMAP.md) | Plano completo das 7 fases |
| [Arquitetura](docs/architecture/architecture.md) | Decisões de design |
| [Endereçamento](docs/architecture/addressing-plan.md) | Plano IP completo |
| [Runbook](docs/operations/runbook.md) | Comandos operacionais |
| [Plano de testes](docs/operations/test-plan.md) | Validações por fase |

---

## Comandos úteis do lab

```bash
# Status do lab
bash scripts/lab-control.sh status

# Iniciar todas as VMs
bash scripts/lab-control.sh start

# Parar todas as VMs
bash scripts/lab-control.sh stop

# Criar snapshot (antes de mudanças)
bash scripts/lab-control.sh snapshot "fase-01-ok"

# Restaurar snapshot
bash scripts/lab-control.sh restore "fase-01-ok"

# Simular WAN (latência 50ms, jitter 10ms, 0.5% perda)
sudo bash scripts/simulate-wan.sh br-dc1-ea 50ms 10ms 0.5%
```

---

## Autor

**Rodrigo Machado**
Cloud & Infrastructure Engineer
Foco: Cloud Networking · Backbone Architecture · Hybrid Infrastructure

## License

MIT — veja `LICENSE`
