# Runbook (Operations)

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

## Procedimento: simular queda de link
1. Inicie ping contínuo a partir de uma filial.
2. No core, desabilite uma interface de uplink:
   - `configure`
   - `set interfaces ethernet ethX disable`
   - `commit`
3. Observe reconvergência (rotas e traceroute).

## Procedimento: simulação WAN (host)
Use `scripts/simulate-wan.sh` para aplicar netem em uma bridge.
