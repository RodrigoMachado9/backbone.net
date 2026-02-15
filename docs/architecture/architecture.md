# Architecture

## Components
- **Core**: core-dc1, core-dc2 (iBGP AS 65000)
- **Edge**: edge-a, edge-b, edge-c (OSPF Area 0)

## Routing Strategy
- IGP: OSPF (área 0)
- Core routing: iBGP entre cores (AS único) — base para políticas futuras
- Redistribuição (didática): OSPF → BGP nos cores

## Failover
- Cada filial tem 2 uplinks (um para cada core).
- Em falha de link/core, OSPF reconverge e mantém conectividade.

## VRF (v1)
- VRF-lite por filial (exemplo) para segmentação e isolamento.
