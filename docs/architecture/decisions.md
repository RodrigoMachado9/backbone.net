# Architectural Decisions (ADR-lite)

## ADR-001 — OSPF como IGP
**Decisão:** usar OSPF area 0.  
**Motivo:** convergência rápida, padrão enterprise, troubleshooting maduro.  
**Trade-offs:** tuning de timers e design de áreas pode ser necessário em topologias maiores.

## ADR-002 — iBGP no core (AS 65000)
**Decisão:** iBGP entre cores.  
**Motivo:** base para políticas (local-pref/MED) e evolução para cenários ISP.  
**Trade-offs:** exige atenção a escala (RR/communities) em versões futuras.

## ADR-003 — Links p2p em /30
**Decisão:** sub-redes /30 para links ponto-a-ponto.  
**Motivo:** padronização e economia de IP.  
**Trade-offs:** em ambientes IPv6, o desenho muda (p2p /127, etc.).

## ADR-004 — VRF-lite (v1)
**Decisão:** VRF por exemplo de tenant/cliente.  
**Motivo:** demonstra isolamento e multi-tenant.  
**Trade-offs:** roteamento por VRF depende da versão do VyOS e do desenho operacional.
