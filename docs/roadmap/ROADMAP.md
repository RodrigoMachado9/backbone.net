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
| 08 | Integração AWS | Site-to-Site VPN, IPsec, BGP dinâmico | 2-3 semanas |

**Tempo total estimado: 12-17 semanas** (dedicando ~1h/dia)

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

---

## Fase 08 — Integração AWS (Site-to-Site VPN)

### Objetivo
Conectar o backbone virtual a uma VPC na AWS via Site-to-Site VPN com IPsec e BGP dinâmico.

### O que aprende
- IPsec (IKEv1/v2): fases de negociação, SAs, algoritmos de criptografia
- VTI (Virtual Tunnel Interface) no VyOS
- BGP sobre túnel VPN (dynamic routing com AWS)
- AWS VPN Gateway: arquitetura de dois túneis redundantes
- Propagação de rotas entre on-premises e VPC
- Transit Gateway (conceito)
- Custos e billing de VPN na AWS

### Pré-requisitos
- Fases 01-06 completas (especialmente BGP e firewall)
- Conta AWS (free tier + ~US$0.05/h por VPN connection)
- AWS CLI configurado no host Ubuntu

### Arquitetura

```
  [Backbone Lab - KVM]                    [AWS]
                                          
  edge-a ── core-dc1 ══╤═══ Túnel 1 ═══╤══ VPN GW ── VPC
                        │               │   (2 endpoints)
  edge-b ── core-dc2 ══╧═══ Túnel 2 ═══╧══           │
                                                  subnet
  edge-c                                         10.20.0.0/16
  
  ══ = túnel IPsec sobre internet
```

### Plano de endereçamento

| Recurso | CIDR | Nota |
|---------|------|------|
| VPC AWS | 10.20.0.0/16 | Não pode colidir com 10.10.x.0 nem 10.255.x.0 |
| Subnet pública | 10.20.1.0/24 | Para testes (EC2) |
| Subnet privada | 10.20.2.0/24 | Para workloads |
| Tunnel 1 inside | 169.254.21.0/30 | AWS atribui automaticamente |
| Tunnel 2 inside | 169.254.21.4/30 | AWS atribui automaticamente |

### Etapas de implementação

#### Etapa 1 — Preparar o lado AWS (CLI ou Console)

```bash
# Criar VPC
aws ec2 create-vpc --cidr-block 10.20.0.0/16 --tag-specifications \
  'ResourceType=vpc,Tags=[{Key=Name,Value=backbone-lab-vpc}]'

# Criar subnet
aws ec2 create-subnet --vpc-id <vpc-id> --cidr-block 10.20.1.0/24

# Criar Virtual Private Gateway (VGW)
aws ec2 create-vpn-gateway --type ipsec.1 --amazon-side-asn 64512

# Anexar VGW à VPC
aws ec2 attach-vpn-gateway --vpn-gateway-id <vgw-id> --vpc-id <vpc-id>

# Criar Customer Gateway (seu lab = "on-premises")
# O IP público é o IP do seu roteador de saída (ou IP público do host)
aws ec2 create-customer-gateway --type ipsec.1 \
  --public-ip <SEU_IP_PUBLICO> --bgp-asn 65000

# Criar VPN Connection (com BGP dinâmico)
aws ec2 create-vpn-connection --type ipsec.1 \
  --customer-gateway-id <cgw-id> --vpn-gateway-id <vgw-id> \
  --options '{"StaticRoutesOnly":false}'

# Baixar a configuração (formato genérico ou VyOS)
aws ec2 describe-vpn-connections --vpn-connection-id <vpn-id>
```

#### Etapa 2 — Configurar IPsec no VyOS (core-dc1)

```
# IKE (Fase 1)
set vpn ipsec ike-group AWS-IKE proposal 1 encryption aes256
set vpn ipsec ike-group AWS-IKE proposal 1 hash sha256
set vpn ipsec ike-group AWS-IKE proposal 1 dh-group 14
set vpn ipsec ike-group AWS-IKE dead-peer-detection action restart
set vpn ipsec ike-group AWS-IKE dead-peer-detection interval 15
set vpn ipsec ike-group AWS-IKE dead-peer-detection timeout 30

# ESP (Fase 2)
set vpn ipsec esp-group AWS-ESP proposal 1 encryption aes256
set vpn ipsec esp-group AWS-ESP proposal 1 hash sha256

# Interface de saída (ajustar conforme seu setup de NAT/IP público)
set vpn ipsec interface 'eth0'

# Túnel 1
set vpn ipsec site-to-site peer <AWS_ENDPOINT_1_IP> authentication mode pre-shared-secret
set vpn ipsec site-to-site peer <AWS_ENDPOINT_1_IP> authentication pre-shared-secret '<PSK_TUNEL_1>'
set vpn ipsec site-to-site peer <AWS_ENDPOINT_1_IP> ike-group AWS-IKE
set vpn ipsec site-to-site peer <AWS_ENDPOINT_1_IP> vti bind vti0
set vpn ipsec site-to-site peer <AWS_ENDPOINT_1_IP> vti esp-group AWS-ESP

# VTI 1
set interfaces vti vti0 address '169.254.21.2/30'
set interfaces vti vti0 description 'AWS VPN Tunnel 1'

# Túnel 2 (redundância)
set vpn ipsec site-to-site peer <AWS_ENDPOINT_2_IP> authentication mode pre-shared-secret
set vpn ipsec site-to-site peer <AWS_ENDPOINT_2_IP> authentication pre-shared-secret '<PSK_TUNEL_2>'
set vpn ipsec site-to-site peer <AWS_ENDPOINT_2_IP> ike-group AWS-IKE
set vpn ipsec site-to-site peer <AWS_ENDPOINT_2_IP> vti bind vti1
set vpn ipsec site-to-site peer <AWS_ENDPOINT_2_IP> vti esp-group AWS-ESP

# VTI 2
set interfaces vti vti1 address '169.254.21.6/30'
set interfaces vti vti1 description 'AWS VPN Tunnel 2'
```

#### Etapa 3 — BGP sobre os túneis

```
# Anunciar redes do lab para a AWS via BGP
set protocols bgp neighbor '169.254.21.1' remote-as '64512'
set protocols bgp neighbor '169.254.21.1' address-family ipv4-unicast soft-reconfiguration inbound
set protocols bgp neighbor '169.254.21.1' timers holdtime 30
set protocols bgp neighbor '169.254.21.1' timers keepalive 10

set protocols bgp neighbor '169.254.21.5' remote-as '64512'
set protocols bgp neighbor '169.254.21.5' address-family ipv4-unicast soft-reconfiguration inbound
set protocols bgp neighbor '169.254.21.5' timers holdtime 30
set protocols bgp neighbor '169.254.21.5' timers keepalive 10

# Anunciar prefixos do backbone para a AWS
set protocols bgp address-family ipv4-unicast network '10.10.1.0/24'
set protocols bgp address-family ipv4-unicast network '10.10.2.0/24'
set protocols bgp address-family ipv4-unicast network '10.10.3.0/24'
```

#### Etapa 4 — Habilitar propagação de rotas na AWS

```bash
# Habilitar route propagation na route table da VPC
aws ec2 enable-vgw-route-propagation \
  --gateway-id <vgw-id> --route-table-id <rtb-id>
```

### Verificação

```
# No VyOS
show vpn ipsec sa                    # Túneis IPsec ativos
show interfaces vti0                 # VTI up/up
show ip bgp summary                  # Sessões BGP com AWS (2 peers)
show ip bgp                          # Deve mostrar 10.20.0.0/16 vindo da AWS
ping 10.20.1.x                       # Ping em instância EC2 na VPC

# Na AWS
aws ec2 describe-vpn-connections     # Status dos túneis
```

### Testes avançados

1. **Failover de túnel**: Derrubar vti0 e verificar que tráfego migra para vti1
2. **Latência real**: Medir RTT do edge-a até EC2 na AWS (ping/traceroute)
3. **Throughput**: iperf3 entre lab e EC2 para medir banda do túnel
4. **Route propagation**: Adicionar nova rede no lab e verificar que aparece na route table da VPC

### Desafio extra — Transit Gateway

Se quiser ir além, substitua o VPN Gateway por um Transit Gateway.
Isso permite conectar múltiplas VPCs e múltiplas VPNs em um hub centralizado,
que é o padrão enterprise na AWS para redes complexas.

### Controle de custos

| Recurso | Custo aproximado |
|---------|-----------------|
| VPN Connection | ~US$0.05/hora (~US$36/mês se 24/7) |
| Data transfer out | US$0.09/GB |
| EC2 t3.micro (teste) | Free tier ou ~US$0.01/hora |

**Dica**: Suba a VPN, faça os testes em 2-4 horas, e destrua tudo. Custo total: ~US$0.20.

```bash
# Destruir tudo ao final
aws ec2 delete-vpn-connection --vpn-connection-id <vpn-id>
aws ec2 detach-vpn-gateway --vpn-gateway-id <vgw-id> --vpc-id <vpc-id>
aws ec2 delete-vpn-gateway --vpn-gateway-id <vgw-id>
aws ec2 delete-customer-gateway --customer-gateway-id <cgw-id>
aws ec2 delete-subnet --subnet-id <subnet-id>
aws ec2 delete-vpc --vpc-id <vpc-id>
```

### Critério de conclusão
- [ ] Dois túneis IPsec UP (show vpn ipsec sa)
- [ ] BGP established com AWS (2 peers, AS 64512)
- [ ] Rotas do lab visíveis na route table da VPC
- [ ] Rotas da VPC visíveis no VyOS (10.20.0.0/16)
- [ ] Ping do edge-a até EC2 na VPC
- [ ] Failover: derrubar túnel 1, tráfego migra para túnel 2
- [ ] Recursos AWS destruídos ao final (sem custo recorrente)

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
