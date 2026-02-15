# Runbook (Operations)

## Comandos via Makefile (recomendado)

```bash
make status            # Status de todas as VMs e redes
make validate          # Validação completa com asserts (OSPF, BGP, Ping, Rotas)
make test-ospf         # Verificar apenas OSPF
make test-bgp          # Verificar apenas BGP
make test-ping         # Testar conectividade fim-a-fim
make test-routes       # Mostrar tabelas de rota
make test-failover     # Teste de failover automatizado (link inter-core)
```

## Comandos essenciais (VyOS)
### OSPF
- `show ip ospf neighbor`
- `show ip ospf route`
- `show ip route ospf`

### BGP
- `show ip bgp summary`
- `show ip bgp`
- `show ip route bgp`

### Troubleshooting
- `ping <ip>` / `traceroute <ip>`
- `show interfaces`
- `show log`

## Procedimento: simular queda de link (manual)
1. Inicie ping contínuo a partir de uma filial.
2. No core, desabilite uma interface de uplink:
   - `configure`
   - `set interfaces ethernet ethX disable`
   - `commit`
3. Observe reconvergência (rotas e traceroute).
4. Restaure: `delete interfaces ethernet ethX disable` → `commit`

## Procedimento: simular queda de link (automatizado)
```bash
make test-failover
# Executa: pré-check → desabilita link → valida reconvergência → restaura → pós-check
```

## Procedimento: simulação WAN (host)
Use `scripts/simulate-wan.sh` para aplicar netem em uma bridge.
