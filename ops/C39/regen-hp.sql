-- C39 — regeneração de HP: os dois atributos não têm valor em nenhuma das 18 classes.
--
-- Diagnóstico (somente leitura, banco de produção, 2026-11-18):
--   config."ConstValueAttribute" tem os valores de Mana (0.037), Ability (mult 0.03/0.05 + absoluto 2)
--   e Shield (100 e 1/75000), mas NÃO tem linha para "Health Recovery Multiplier" nem para
--   "Health Recovery Absolute Increase" — em classe nenhuma. O único valor de HP que existe é a
--   relação de descanso ("Health Recovery Multiplier" += 0.03 quando o personagem está sentado/parado),
--   e sem base ela soma a partir de 0.
--   Fórmula do servidor (Stats.cs, Regeneration): por ciclo, CurrentHealth += MaximumHealth * mult + absoluto;
--   Health usa Interval 7 s (parado) e 5 s (descansando); o GameConfiguration.RecoveryInterval compensa o tempo.
--
-- Proposta (NÃO aplicada — depende da aprovação do Pedro):
--   melee e RF: mult 0.012, absoluto 2      → nv 145 (2311 HP): 4,2 HP/s parado, 19,8 HP/s descansando
--   demais:     mult 0.010, absoluto 1      → nv 145 (2311 HP): 3,4 HP/s parado, 18,7 HP/s descansando
--   MG/DL:      mult 0.011, absoluto 1      → nv 145 (2311 HP): 3,8 HP/s parado, 19,2 HP/s descansando
--   nv 1 (108 HP): 0,30–0,47 HP/s parado / 1,06–1,31 HP/s descansando (tabela completa no .md)
--
-- Idempotente: só insere onde a classe ainda não tem a linha. Valores por classe na tabela abaixo.

BEGIN;

WITH plan(class_name, mult, absolute_increase) AS (
    VALUES
        ('Dark Knight', 0.012, 2),
        ('Blade Knight', 0.012, 2),
        ('Blade Master', 0.012, 2),
        ('Dark Wizard', 0.010, 1),
        ('Soul Master', 0.010, 1),
        ('Grand Master', 0.010, 1),
        ('Fairy Elf', 0.010, 1),
        ('Fist Master', 0.012, 2),
        ('Muse Elf', 0.010, 1),
        ('High Elf', 0.010, 1),
        ('Magic Gladiator', 0.011, 1),
        ('Dark Lord', 0.011, 1),
        ('Summoner', 0.010, 1),
        ('Bloody Summoner', 0.010, 1),
        ('Dimension Master', 0.010, 1),
        ('Rage Fighter', 0.012, 2),
        ('Duel Master', 0.011, 1),
        ('Lord Emperor', 0.011, 1)
),
adds(designation, value_from_plan) AS (
    VALUES
        ('Health Recovery Multiplier', 'mult'),
        ('Health Recovery Absolute Increase', 'absolute_increase')
)
INSERT INTO config."ConstValueAttribute" ("Id", "DefinitionId", "CharacterClassId", "Value", "GameConfigurationId", "AggregateType")
SELECT gen_random_uuid(),
       a."Id",
       cc."Id",
       CASE WHEN adds.designation = 'Health Recovery Multiplier' THEN plan.mult ELSE plan.absolute_increase END,
       cc."GameConfigurationId",
       0 -- AggregateType.AddRaw
FROM plan
JOIN config."CharacterClass" cc
  ON split_part(cc."Name", '||', 1) = plan.class_name
JOIN adds ON TRUE
JOIN config."AttributeDefinition" a ON a."Designation" = adds.designation
WHERE NOT EXISTS (
    SELECT 1
    FROM config."ConstValueAttribute" existing
    WHERE existing."CharacterClassId" = cc."Id"
      AND existing."DefinitionId" = a."Id"
);

-- Conferência: 36 linhas (18 classes x 2 atributos), nenhuma classe repetida.
SELECT a."Designation", count(*) AS classes, min(c."Value") AS menor, max(c."Value") AS maior
FROM config."ConstValueAttribute" c
JOIN config."AttributeDefinition" a ON a."Id" = c."DefinitionId"
WHERE a."Designation" IN ('Health Recovery Multiplier', 'Health Recovery Absolute Increase')
GROUP BY 1
ORDER BY 1;

-- Rollback (desfaz só o que este script insere nos dois atributos de HP).
-- DELETE FROM config."ConstValueAttribute" c
-- USING config."AttributeDefinition" a
-- WHERE a."Id" = c."DefinitionId"
--   AND a."Designation" IN ('Health Recovery Multiplier', 'Health Recovery Absolute Increase');

ROLLBACK; -- trocar por COMMIT só depois da aprovação do Pedro
