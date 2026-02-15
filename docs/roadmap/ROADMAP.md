# Backbone.net — Roadmap Completo de Aprendizado

> De zero a um mini-ISP funcional em 7 fases progressivas.
> Ambiente: **Ubuntu 24.04 LTS** + **KVM/virt-manager**

---

## Visão Geral das Fases

| Fase | Nome | O que aprende | Duração estimada |
|------|------|---------------|------------------|
| 01 | Fundação | OSPF, iBGP, topologia dual-core | 1-2 semanas |
| 02 | Resiliência | Loopbacks, BGP sobre loopback, failover | 1 semana |
| 03 | MPLS Core | LDP, label switching, LSP | 1-2 semanas |
| 04 | L3VPN | MP-BGP, VPNv4, VRF fim-a-fim | 2 semanas |
| 05 | Peering Externo | eBGP, políticas, communities, filtragem | 2 semanas |
| 06 | Segurança | Firewall, RPKI, control-plane protection | 1-2 semanas |
| 07 | Observabilidade | SNMP, NetFlow, Grafana, alertas | 1-2 semanas |

**Tempo total estimado: 10-14 semanas** (dedicando ~1h/dia)

---

## Fase 01 — Fundação

### Objetivo
Subir a topologia completa (5 roteadores VyOS no KVM) e validar conectividade OSPF + iBGP.

### O que aprende
- Configuração básica de roteadores VyOS
- OSPF em área única (Area 0)
- iBGP entre cores com redistribuição
- Criação de VMs e redes virtuais no KVM
- Troubleshooting básico de roteamento

### Topologia
```
       [core-dc1] ---- [core-dc2]
        /   |   \       /   |   \
   [edge-a] [edge-b] [edge-c]
```

### Entregáveis
- 5 VMs rodando VyOS
- 10 redes virtuais isoladas
- OSPF convergido, BGP established
- Ping fim-a-fim entre todas as redes de clientes

### Critério de conclusão
- [ ] Todas interfaces up/up
- [ ] OSPF neighbors em Full
- [ ] BGP session Established
- [ ] Ping 10.10.1.1 ↔ 10.10.2.1 ↔ 10.10.3.1
- [ ] Traceroute mostra caminho pelo core
- [ ] Snapshot salvo de todas as VMs

---

## Fase 02 — Resiliência

### Objetivo
Adicionar loopbacks, migrar BGP para usar loopbacks como source, e testar failover.

### O que aprende
- Interfaces loopback e sua importância em backbones
- BGP update-source com loopback (resiliência)
- Convergência OSPF em falha de link
- Teste de failover com desabilitação de interfaces

### Mudanças na topologia
- Loopback em cada roteador (10.0.0.X/32)
- BGP entre cores usa loopback como source
- OSPF anuncia os loopbacks

### Plano de endereçamento — Loopbacks
| Roteador | Loopback |
|----------|----------|
| core-dc1 | 10.0.0.1/32 |
| core-dc2 | 10.0.0.2/32 |
| edge-a   | 10.0.0.11/32 |
| edge-b   | 10.0.0.12/32 |
| edge-c   | 10.0.0.13/32 |

### Testes de failover
1. Ping contínuo entre edges
2. Desabilitar eth0 no core-dc1 (link inter-core)
3. Observar reconvergência OSPF (~30-40s com timers padrão)
4. Verificar que BGP se mantém (loopback alcançável por caminho alternativo)
5. Traceroute mostra novo caminho

### Critério de conclusão
- [ ] Loopbacks pingáveis de qualquer ponto
- [ ] BGP usando loopback como source
- [ ] Failover de link: tráfego reconverge automaticamente
- [ ] BGP session sobrevive a queda de link físico

---

## Fase 03 — MPLS Core

### Objetivo
Habilitar MPLS (LDP) no core para transporte baseado em labels.

### O que aprende
- Conceito de label switching vs IP routing
- LDP (Label Distribution Protocol)
- LFIB (Label Forwarding Information Base)
- PHP (Penultimate Hop Popping)
- Como MPLS é a base de serviços de operadora

### Pré-requisito
- Fase 02 completa (loopbacks funcionando)
- VyOS 1.4+ (suporte a MPLS via FRR)

### Mudanças
- Habilitar MPLS em todas as interfaces de backbone (não nas LANs)
- Habilitar LDP com router-id = loopback
- Verificar tabela de labels

### Comandos-chave
```
# Habilitar MPLS na interface
set protocols mpls interface ethX

# Habilitar LDP
set protocols mpls ldp router-id 10.0.0.X
set protocols mpls ldp discovery transport-ipv4-address 10.0.0.X
set protocols mpls ldp interface ethX
```

### Verificação
```
show mpls ldp neighbor
show mpls ldp binding
show mpls table
```

### Critério de conclusão
- [ ] LDP neighbors formados entre todos os roteadores adjacentes
- [ ] Labels alocados para todos os loopbacks
- [ ] Tráfego entre cores usa labels (verificável com show mpls table)
- [ ] Ping fim-a-fim continua funcionando

---

## Fase 04 — L3VPN (VPN sobre MPLS)

### Objetivo
Implementar VPNs L3 (VRF fim-a-fim) usando MP-BGP + MPLS.

### O que aprende
- VRF (Virtual Routing and Forwarding) completo
- MP-BGP com address-family VPNv4
- Route Distinguisher (RD) e Route Target (RT)
- Como operadoras isolam tráfego de clientes diferentes
- Import/Export de rotas entre VRFs

### Conceito
```
[Cliente-A em edge-a] ←VRF→ [MPLS Core] ←VRF→ [Cliente-A em edge-c]
```
O Cliente-A na filial A e na filial C se comunicam através do backbone
MPLS como se estivessem na mesma rede, isolados dos outros clientes.

### Plano de VRFs
| VRF | RD | RT Import | RT Export | Edges |
|-----|-----|-----------|-----------|-------|
| CLIENTE-A | 65000:100 | 65000:100 | 65000:100 | edge-a, edge-c |
| CLIENTE-B | 65000:200 | 65000:200 | 65000:200 | edge-b |

### Mudanças
- Configurar VRFs com RD e RT nos edges
- Habilitar MP-BGP VPNv4 entre cores (Route Reflectors)
- PE-CE: redistribuição de rotas da LAN na VRF

### Critério de conclusão
- [ ] VRFs configuradas nos edges
- [ ] MP-BGP VPNv4 trocando prefixos
- [ ] Cliente-A em edge-a pinga Cliente-A em edge-c (via VRF)
- [ ] Tráfego VRF é isolado (Cliente-B não alcança Cliente-A)

---

## Fase 05 — Peering Externo (eBGP)

### Objetivo
Adicionar um roteador "ISP externo" e implementar eBGP com políticas.

### O que aprende
- eBGP peering e multihop
- Políticas BGP: local-preference, MED, AS-path prepend
- Communities BGP (standard e extended)
- Filtragem de prefixos (prefix-lists, route-maps)
- Conceito de full table vs default route
- Simulação de upstream provider

### Nova topologia
```
       [ISP-upstream]
        /          \
   [core-dc1] -- [core-dc2]
    /   |   \     /   |   \
  [ea] [eb] [ec]
```

### Novo roteador
| Roteador | AS | Loopback | Links |
|----------|-----|----------|-------|
| isp-upstream | 64999 | 10.0.0.100/32 | core-dc1 (10.255.100.0/30), core-dc2 (10.255.101.0/30) |

### Políticas a implementar
1. **Default route do ISP**: ISP anuncia 0.0.0.0/0 para ambos os cores
2. **Local-preference**: core-dc1 prefere o link direto (local-pref 200), core-dc2 como backup (local-pref 100)
3. **Communities**: Marcar rotas internas com community 65000:1000
4. **Filtragem**: Rejeitar bogons e prefixos inválidos do ISP
5. **Prepend**: Anunciar para o ISP com AS-path prepend no link backup

### Critério de conclusão
- [ ] eBGP established com ISP
- [ ] Default route propagada internamente
- [ ] Local-pref funcionando (tráfego sai pelo core-dc1)
- [ ] Failover: se link do core-dc1 cair, tráfego sai pelo core-dc2
- [ ] Filtragem de bogons ativa
- [ ] Communities visíveis com show ip bgp communities

---

## Fase 06 — Segurança

### Objetivo
Proteger o plano de controle e implementar boas práticas de segurança.

### O que aprende
- Zone-based firewall no VyOS
- Control-plane protection (CoPP)
- RPKI (Resource Public Key Infrastructure) — conceito
- Filtros anti-spoofing (uRPF)
- SSH hardening
- Logging centralizado

### Implementações
1. **Firewall por zona**: WAN, CORE, LAN, LOCAL com políticas default-deny
2. **CoPP**: Rate-limit ICMP, permitir apenas BGP/OSPF/LDP nas portas corretas
3. **uRPF**: Strict mode nas interfaces de cliente
4. **SSH hardening**: Chaves RSA, desabilitar password auth
5. **ACL de gerência**: Permitir SSH apenas de uma rede de management

### Critério de conclusão
- [ ] Firewall ativo em todos os edges
- [ ] Tráfego de clientes filtrado (uRPF)
- [ ] SSH somente por chave
- [ ] OSPF/BGP continuam funcionando com firewall ativo
- [ ] Logs centralizados no host via syslog

---

## Fase 07 — Observabilidade

### Objetivo
Implementar monitoramento completo do backbone.

### O que aprende
- SNMP v2c/v3 para coleta de métricas
- NetFlow/sFlow para análise de tráfego
- Dashboards com Grafana
- Alertas básicos
- Conceito de NOC (Network Operations Center)

### Stack de monitoramento (containers no host)
```
[VyOS routers] --SNMP/sFlow--> [Prometheus + snmp_exporter]
                                        |
                                   [Grafana]
                                        |
                                  [Dashboards]
```

### Componentes
| Componente | Função | Como rodar |
|-----------|--------|-----------|
| Prometheus | Coleta de métricas | Container Docker |
| snmp_exporter | Traduz SNMP → Prometheus | Container Docker |
| Grafana | Dashboards e alertas | Container Docker |
| pmacct/ntopng | Análise NetFlow/sFlow | Container Docker |

### Dashboards a criar
1. **Visão geral**: Status de todas as interfaces (up/down)
2. **Throughput**: Banda utilizada por interface
3. **BGP**: Status das sessões, prefixos recebidos/anunciados
4. **OSPF**: Adjacências, custo de rotas
5. **Alertas**: Interface down, BGP session lost, CPU alta

### Critério de conclusão
- [ ] SNMP coletando métricas de todos os roteadores
- [ ] Grafana acessível com dashboards funcionais
- [ ] Alerta dispara quando interface cai
- [ ] NetFlow mostrando top talkers

---

## Tópicos Complementares (Estudo Teórico)

Estes tópicos não são facilmente simuláveis no lab mas são essenciais
para entender o ecossistema completo:

### Camada Física
- Fibra óptica (monomodo, multimodo)
- DWDM (Dense Wavelength Division Multiplexing)
- Transponders e amplificadores EDFA
- Patch panels e DIO (Distribuidor Interno Óptico)

### IXP (Internet Exchange Point)
- Como funciona o IX.br (PTT)
- Peering multilateral vs bilateral
- Route servers
- Looking glass

### DNS e CDN
- DNS autoritativo e recursivo
- Anycast
- CDN (Content Delivery Network) e cache

### Regulatório
- ANATEL e licenciamento
- ASN e blocos IP (LACNIC/NIC.br)
- IRR (Internet Routing Registry)

---

## Recursos Recomendados

### Livros
- *Internet Routing Architectures* — Sam Halabi
- *MPLS in the SDN Era* — Antonio Sanchez-Monge
- *BGP Design and Implementation* — Randy Zhang

### Online
- VyOS Documentation: docs.vyos.io
- FRRouting Docs: docs.frrouting.org
- RIPE NCC Training: academy.ripe.net (gratuito)
- BGP.tools: bgp.tools (visualização de rotas)

### Labs de referência
- GNS3 Academy
- Network Lessons (networklessons.com)
- Jeff Doyle's Routing TCP/IP
