# Test Plan (v1)

## Teste 1 — Vizinhança OSPF
**Passo:** `show ip ospf neighbor` em edge e core.  
**Esperado:** neighbors em estado FULL.

## Teste 2 — Sessão iBGP
**Passo:** `show ip bgp summary` nos cores.  
**Esperado:** neighbor ESTABLISHED.

## Teste 3 — Roteamento end-to-end
**Passo:** ping e traceroute entre LANs de filiais.  
**Esperado:** conectividade e path coerente.

## Teste 4 — Failover
**Passo:** derrubar link de um core para uma filial.  
**Esperado:** tráfego segue via core alternativo com reconvergência.

## Teste 5 — WAN degradation
**Passo:** aplicar netem em uma bridge.  
**Esperado:** RTT aumenta e perdas aparecem conforme parametrização.
