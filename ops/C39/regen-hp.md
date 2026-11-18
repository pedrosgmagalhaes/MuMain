# C39 — regeneração de HP (proposta, nada aplicado)

Dev MU · 2026-11-18 · leitura em `config.*` de produção, sem escrita.

## O que falta no banco

`config."ConstValueAttribute"` tem, para as 18 classes:

| atributo | linhas | valores |
|---|---|---|
| Mana Recovery Multiplier | 18 | 0.037 |
| Ability Recovery Absolute Increase | 18 | 2 |
| Ability Recovery Multiplier | 18 | 0.03 (0.05 no Dark Knight) |
| Shield Recovery Multiplier | 36 | 100 e 1/75000 |

e **nenhuma** para `Health Recovery Multiplier` e `Health Recovery Absolute Increase`. A única coisa que
mexe em HP é a relação de descanso (`Health Recovery Multiplier += 0.03` com `IsResting`), que sem base
soma a partir de zero. Por isso não há regeneração em mapa nenhum, com ou sem safezone.

Não são linhas de `config."StatAttributeDefinition"` (essa tabela só tem as bases, Level e os Currents):
os valores de recuperação vivem em `config."ConstValueAttribute"`, ligados por `DefinitionId` +
`CharacterClassId`. É lá que o SQL do C39 escreve.

**Mana, Ability e Shield já estão completos** — não precisam de nada nesta janela.

## Fórmula (do próprio servidor)

`Stats.cs` → `HealthRegeneration`: ciclo de **7 s parado** e **5 s descansando**
(`GameConfiguration.RecoveryInterval` compensa o tempo decorrido). Por ciclo:
`CurrentHealth += MaximumHealth × mult + absoluto`, até o máximo.

## Proposta por classe

`mult` e `absoluto` são o que entra no banco. As colunas de efeito são calculadas pela fórmula acima.

| classe | mult | absoluto | nv 145 (2311 HP) parado | descansando | nv 1 (108 HP) parado | descansando |
|---|---|---|---|---|---|---|
| Dark Knight | 0.012 | 2 | 4,2 HP/s | 19,8 HP/s | 0,47 HP/s | 1,31 HP/s |
| Blade Knight | 0.012 | 2 | 4,2 | 19,8 | 0,47 | 1,31 |
| Blade Master | 0.012 | 2 | 4,2 | 19,8 | 0,47 | 1,31 |
| Rage Fighter | 0.012 | 2 | 4,2 | 19,8 | 0,47 | 1,31 |
| Fist Master | 0.012 | 2 | 4,2 | 19,8 | 0,47 | 1,31 |
| Magic Gladiator | 0.011 | 1 | 3,8 | 19,2 | 0,31 | 1,09 |
| Duel Master | 0.011 | 1 | 3,8 | 19,2 | 0,31 | 1,09 |
| Dark Lord | 0.011 | 1 | 3,8 | 19,2 | 0,31 | 1,09 |
| Lord Emperor | 0.011 | 1 | 3,8 | 19,2 | 0,31 | 1,09 |
| Dark Wizard | 0.010 | 1 | 3,4 | 18,7 | 0,30 | 1,06 |
| Soul Master | 0.010 | 1 | 3,4 | 18,7 | 0,30 | 1,06 |
| Grand Master | 0.010 | 1 | 3,4 | 18,7 | 0,30 | 1,06 |
| Fairy Elf | 0.010 | 1 | 3,4 | 18,7 | 0,30 | 1,06 |
| Muse Elf | 0.010 | 1 | 3,4 | 18,7 | 0,30 | 1,06 |
| High Elf | 0.010 | 1 | 3,4 | 18,7 | 0,30 | 1,06 |
| Summoner | 0.010 | 1 | 3,4 | 18,7 | 0,30 | 1,06 |
| Bloody Summoner | 0.010 | 1 | 3,4 | 18,7 | 0,30 | 1,06 |
| Dimension Master | 0.010 | 1 | 3,4 | 18,7 | 0,30 | 1,06 |

Tempos de 0 ao máximo: nv 145 parado **9–11 min**, descansando **~2 min**; nv 1 parado **4–6 min**,
descansando **1,5–2 min**.

## De onde vem cada número

- **Estrutura** (mult sobre o máximo + absoluto, ciclos de 7 s e 5 s, bônus de descanso de 0.03):
  `Stats.cs` (`HealthRegeneration`, `Regeneration`) — é o que o servidor executa.
- **Ordem de grandeza**: a mesma régua dos outros atributos que já estão no banco — mana 0.037 dá 3,7% do
  máximo por ciclo; 1% para HP é a mesma classe de valor, sem curar mais rápido que mana.
- **Diferença por classe**: espelha o padrão que o próprio inicializador já usa para
  `Ability Recovery Multiplier` (melee 0.05, resto 0.03) — daí 0.012/absoluto 2 para a linha de melee e RF,
  0.011 para MG/DL e 0.010 para as demais. Não é valor clássico documentado: é proposta, e está marcada
  assim de propósito.

## Como aplicar (quando o Pedro aprovar)

`ops/C39/regen-hp.sql`: `BEGIN`, um `INSERT ... WHERE NOT EXISTS` (idempotente: 36 linhas), `SELECT` de
conferência, rollback pronto e `COMMIT` comentado. Aplicar e reiniciar o `openmu-startup` — a configuração
só é lida na subida.

## Correção 2 (o quantum de 215 medido depois da janela)

`ItemAwareAttributeSystem.cs:24` monta os atributos com
`character.CharacterClass.BaseAttributeValues.Concat(gameConfiguration.GlobalBaseAttributeValues)`.
O INSERT do C39 preencheu `GameConfigurationId` (copiado da classe) nas 36 linhas; Mana, Ability e Shield
têm esse campo **NULL**. Com isso as 36 linhas entram também como valores **globais**, e todo personagem
soma as 18 classes: multiplicador 0,194 e absoluto 23 → `(2311 × 0,194 + 23) × 0,4286 = 202` por tick,
mais 12,7 da própria classe = **215** — o quantum medido, constante e independente do que falta.

Conserto em config: `GameConfigurationId = NULL` nas 36 linhas (`regen-hp-fix.sql`). Depois disso:
`(2311 × 0,012 + 2) × 0,4286 = 12,7` por tick = **4,24 HP/s** parado no nível 145, a taxa aprovada.
