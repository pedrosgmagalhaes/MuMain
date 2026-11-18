-- C39-fix — tira as 36 linhas de HP do bloco de atributos GLOBAIS.
--
-- Causa do "quantum fixo de 215" medido depois do C39:
--   `ItemAwareAttributeSystem` monta os atributos de todo personagem com
--       character.CharacterClass.BaseAttributeValues.Concat(gameConfiguration.GlobalBaseAttributeValues)
--   (src/GameLogic/Attributes/ItemAwareAttributeSystem.cs:24).
--   O INSERT do C39 preencheu `GameConfigurationId` (copiava o da classe) nas 36 linhas; as outras
--   recuperações (Mana, Ability, Shield) têm esse campo NULL. Resultado: as 36 linhas entram duas vezes
--   no caminho — como valor da classe e como valor global — e todo personagem soma as 18 classes:
--       multiplicador 0,194 (0,012×5 + 0,011×4 + 0,010×9) e absoluto 23
--   por tick (factor = 3 s / 7 s = 0,4286): (2311 × 0,194 + 23) × 0,4286 = 202, mais 12,7 da própria
--   classe ≈ 215 — o número medido, constante e independente do que falta.
--
-- Conserto: `GameConfigurationId = NULL` nas 36 linhas de HP (é o que o inicializador faz: só a classe).
-- Depois disso o personagem volta a receber só a linha da sua classe: (2311 × 0,012 + 2) × 0,4286 = 12,7
-- por tick = 4,24 HP/s parado no nível 145 — a taxa aprovada.

BEGIN;

-- 1) Antes: 36 linhas com GameConfigurationId preenchido.
SELECT a."Designation", count(*) AS linhas,
       count(*) FILTER (WHERE c."GameConfigurationId" IS NOT NULL) AS com_config
FROM config."ConstValueAttribute" c
JOIN config."AttributeDefinition" a ON a."Id" = c."DefinitionId"
WHERE a."Designation" IN ('Health Recovery Multiplier', 'Health Recovery Absolute Increase')
GROUP BY 1
ORDER BY 1;

-- 2) O conserto.
UPDATE config."ConstValueAttribute" c
SET "GameConfigurationId" = NULL
FROM config."AttributeDefinition" a
WHERE a."Id" = c."DefinitionId"
  AND a."Designation" IN ('Health Recovery Multiplier', 'Health Recovery Absolute Increase');

-- 3) Depois: 0 linhas com_config (e as 36 continuam, agora só por classe).
SELECT a."Designation", count(*) AS linhas,
       count(*) FILTER (WHERE c."GameConfigurationId" IS NOT NULL) AS com_config
FROM config."ConstValueAttribute" c
JOIN config."AttributeDefinition" a ON a."Id" = c."DefinitionId"
WHERE a."Designation" IN ('Health Recovery Multiplier', 'Health Recovery Absolute Increase')
GROUP BY 1
ORDER BY 1;

-- Rollback: repõe o GameConfigurationId da classe em cada linha.
-- UPDATE config."ConstValueAttribute" c
-- SET "GameConfigurationId" = cc."GameConfigurationId"
-- FROM config."AttributeDefinition" a, config."CharacterClass" cc
-- WHERE a."Id" = c."DefinitionId"
--   AND cc."Id" = c."CharacterClassId"
--   AND a."Designation" IN ('Health Recovery Multiplier', 'Health Recovery Absolute Increase');

ROLLBACK; -- trocar por COMMIT quando o Pedro/Ops aprovarem
