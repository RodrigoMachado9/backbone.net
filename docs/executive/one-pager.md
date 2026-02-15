# Backbone 

## Problema
Como projetar e operar um backbone L3 resiliente para múltiplas filiais, com segmentação e failover, usando tecnologias reais.

## Solução (alto nível)
- Dual-core (core-dc1/core-dc2) com iBGP (AS 65000)
- Filiais (edge-a/b/c) com OSPF Area 0
- VRF para isolamento multi-tenant
- Simulação WAN via tc netem (latência/jitter/perda)

## Benefícios
- Resiliência e continuidade (links redundantes por filial)
- Base sólida para políticas (BGP) e evolução (MPLS/EVPN)
- Operação observável: vizinhança OSPF, estado BGP, rotas, path de failover

## Entregáveis
- Runbook operacional + plano de testes
- Diagramas e evidências (screenshots)
- Scripts para deploy em KVM (custo zero)

## Próximos passos (v2)
- MPLS LDP + VRF-lite avançado
- Policies BGP (local-pref/MED/communities)
- Integração com AWS VPN site-to-site
