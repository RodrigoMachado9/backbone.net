# Plano de Endereçamento — backbone.net

## Resumo de faixas

| Faixa | Uso | Fase |
|-------|-----|------|
| 10.255.0.0/16 | Links backbone P2P (/30) | 01 |
| 10.0.0.0/24 | Loopbacks dos roteadores (/32) | 02 |
| 10.10.0.0/16 | LANs de clientes (/24) | 01 |
| 10.255.100.0/30 | ISP <-> core-dc1 | 05 |
| 10.255.101.0/30 | ISP <-> core-dc2 | 05 |
| 10.200.0.0/24 | Rede de gerência | 06 |

---

## Links Backbone P2P (Fase 01)

| Link | Rede | Ponta A (IP) | Ponta B (IP) |
|------|------|-------------|-------------|
| core-dc1 ↔ core-dc2 | 10.255.0.0/30 | core-dc1 eth0: .1 | core-dc2 eth0: .2 |
| core-dc1 ↔ edge-a | 10.255.1.0/30 | core-dc1 eth1: .1 | edge-a eth0: .2 |
| core-dc2 ↔ edge-a | 10.255.2.0/30 | core-dc2 eth1: .1 | edge-a eth1: .2 |
| core-dc1 ↔ edge-b | 10.255.3.0/30 | core-dc1 eth2: .1 | edge-b eth0: .2 |
| core-dc2 ↔ edge-b | 10.255.4.0/30 | core-dc2 eth2: .1 | edge-b eth1: .2 |
| core-dc1 ↔ edge-c | 10.255.5.0/30 | core-dc1 eth3: .1 | edge-c eth0: .2 |
| core-dc2 ↔ edge-c | 10.255.6.0/30 | core-dc2 eth3: .1 | edge-c eth1: .2 |

## Loopbacks (Fase 02)

| Roteador | Loopback | Função |
|----------|----------|--------|
| core-dc1 | 10.0.0.1/32 | Router-ID, BGP source |
| core-dc2 | 10.0.0.2/32 | Router-ID, BGP source |
| edge-a | 10.0.0.11/32 | Router-ID |
| edge-b | 10.0.0.12/32 | Router-ID |
| edge-c | 10.0.0.13/32 | Router-ID |
| isp-upstream | 10.0.0.100/32 | Router-ID (Fase 05) |

## LANs de Clientes (Fase 01)

| Filial | Rede | Gateway |
|--------|------|---------|
| Filial A | 10.10.1.0/24 | edge-a eth2: 10.10.1.1 |
| Filial B | 10.10.2.0/24 | edge-b eth2: 10.10.2.1 |
| Filial C | 10.10.3.0/24 | edge-c eth2: 10.10.3.1 |

## VRFs (Fase 04)

| VRF | RD | RT | Edges | Rede |
|-----|-----|-----|-------|------|
| CLIENTE-A | 65000:100 | 65000:100 | edge-a, edge-c | 10.10.1.0/24, 10.10.3.0/24 |
| CLIENTE-B | 65000:200 | 65000:200 | edge-b | 10.10.2.0/24 |

## ISP Peering (Fase 05)

| Link | Rede | Ponta A | Ponta B |
|------|------|---------|---------|
| ISP ↔ core-dc1 | 10.255.100.0/30 | ISP: .1 | core-dc1: .2 |
| ISP ↔ core-dc2 | 10.255.101.0/30 | ISP: .1 | core-dc2: .2 |
