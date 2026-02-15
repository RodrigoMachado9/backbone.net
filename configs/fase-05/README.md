# Fase 05 - Peering Externo + FortiGate Edge
> eBGP + politicas + FortiGate VM como firewall de borda

**Status:** Pendente

### Novos componentes
- **FortiGate VM** (licenca trial permanente via FortiCloud)
- **ISP upstream** (VyOS, AS 64999)

### Topologia
```
          [ISP] (VyOS AS 64999)
           /          \
    [FG-EDGE]      [core-dc2]
    FortiGate         |
       |              |
    [core-dc1]--------+
```

### Limitacoes da licenca trial FortiGate
- Max 3 interfaces (WAN + CORE + MGMT)
- Max 3 firewall policies
- Max 3 rotas
- Criptografia: somente DES
