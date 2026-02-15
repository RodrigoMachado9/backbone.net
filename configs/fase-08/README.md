# Fase 08 - Integração AWS (Site-to-Site VPN)
> IPsec + BGP dinâmico com AWS VPN Gateway

**Status:** Pendente

### Pré-requisitos
- Fases 01-06 completas
- Conta AWS com AWS CLI configurado
- IP público no host (ou NAT traversal)

### Arquitetura
```
[core-dc1] ══ Túnel IPsec 1 ══ [AWS VPN GW] ── [VPC 10.20.0.0/16]
[core-dc1] ══ Túnel IPsec 2 ══ [AWS VPN GW]
```

### Custo estimado
~US$0.20 para 4 horas de teste.

Configs serão gerados com base nos parâmetros da VPN Connection da AWS
(cada conexão gera endpoints e PSKs únicos).
