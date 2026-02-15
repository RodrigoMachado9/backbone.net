# Test Plan (v1)

## Teste 1 — Vizinhança OSPF
**Passo:** `show ip ospf neighbor` em edge e core.  
**Esperado:** neighbors em estado FULL.  
**Automação:** `make test-ospf` (com assert programático)

## Teste 2 — Sessão iBGP
**Passo:** `show ip bgp summary` nos cores.  
**Esperado:** neighbor ESTABLISHED.  
**Automação:** `make test-bgp` (com assert programático)

## Teste 3 — Roteamento end-to-end
**Passo:** ping e traceroute entre LANs de filiais.  
**Esperado:** conectividade e path coerente.  
**Automação:** `make test-ping` (com assert programático)

## Teste 4 — Failover
**Passo:** derrubar link de um core para uma filial.  
**Esperado:** tráfego segue via core alternativo com reconvergência.  
**Automação:** `make test-failover` — executa automaticamente:
1. Valida conectividade pré-falha
2. Registra traceroute original
3. Desabilita eth0 (link inter-core) em core-dc1
4. Aguarda reconvergência OSPF (45s)
5. Valida que tráfego reconvergiu (ping + traceroute alternativo)
6. Restaura o link
7. Valida retorno ao estado original

## Teste 5 — WAN degradation
**Passo:** aplicar netem em uma bridge.  
**Esperado:** RTT aumenta e perdas aparecem conforme parametrização.

## Teste 6 — Validação completa
**Passo:** `make validate`  
**Esperado:** todos os asserts passam (OSPF Full, BGP Established, Ping OK, rotas completas).
