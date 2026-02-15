# Fase 01 — Fundação

## Objetivo
Subir a topologia básica com OSPF + iBGP e validar conectividade fim-a-fim.

## Configs nesta pasta
- `core-dc1.vyos` — Core datacenter 1 (OSPF + iBGP)
- `core-dc2.vyos` — Core datacenter 2 (OSPF + iBGP)
- `edge-a.vyos` — Edge filial A (OSPF)
- `edge-b.vyos` — Edge filial B (OSPF)
- `edge-c.vyos` — Edge filial C (OSPF)

## Como aplicar
```bash
# Em cada VM, entre no modo configure e cole o conteúdo do arquivo
$ configure
# (cole o conteúdo)
# commit
# save
# exit
```

## Checklist de validação
- [ ] `show interfaces` — todas up/up
- [ ] `show ip ospf neighbor` — vizinhos em Full
- [ ] `show ip bgp summary` — sessão Established
- [ ] Ping entre 10.10.1.1, 10.10.2.1, 10.10.3.1
- [ ] Traceroute mostra caminho pelo core

## Próxima fase
Fase 02: Adicionar loopbacks e migrar BGP para resiliência.
