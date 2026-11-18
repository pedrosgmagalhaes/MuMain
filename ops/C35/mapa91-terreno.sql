-- C35 — mapa 91: o servidor usa o terreno de Atlans (mapa 7) e o cliente desenha Tarkan (mapa 8).
--
-- Sintoma: o herói do jogador nunca é desenhado no mapa 91 (sem corpo, sem sombra), mas a câmera
-- o segue e o terreno/objetos/itens aparecem. Causa: o portão de spawn (C34, 188..204 x 62..72) é
-- 100% `Blocked` no terreno do servidor, então `RecoverFromBlockedSpawnAsync` devolve o jogador ao
-- gate de spawn ~20x por segundo, cada vez num ponto aleatório (GetRandomPoint). O cliente recria o
-- personagem a cada devolução, o que reinicia `Alpha` para 0 — o desenho só acontece com alfa > 0.01.
--
-- Com o terreno do mapa 8 (Tarkan) aplicado no mapa 91, o servidor passa a concordar com o cliente:
-- gate de spawn 187/187 andáveis e as cinco caixas de spawn do C34 169/187 (mesmos números que o
-- `checar_coordenadas.py` deu no cliente).
--
-- Alternativa (não recomendada): trocar o cliente para Atlans (Data/World8 -> World92) e refazer as
-- coordenadas do C34 contra o terreno de Atlans. Perde o tema duna/praia e invalida a passada visual
-- do QA.

BEGIN;

-- 1) Estado de hoje, para o log da aplicação.
SELECT d."Number", octet_length(d."TerrainData") AS bytes, md5(d."TerrainData") AS hash
FROM config."GameMapDefinition" d
WHERE d."Number" IN (8, 91)
ORDER BY 1;

-- 2) O conserto: o mapa 91 recebe o terreno do mapa 8 (Tarkan), que é o que o cliente desenha.
UPDATE config."GameMapDefinition" dest
SET "TerrainData" = src."TerrainData"
FROM config."GameMapDefinition" src
WHERE dest."Number" = 91
  AND src."Number" = 8;

-- 3) Conferência: o hash do mapa 91 tem de ficar igual ao do mapa 8 (ddd6adbb…).
SELECT d."Number", octet_length(d."TerrainData") AS bytes, md5(d."TerrainData") AS hash
FROM config."GameMapDefinition" d
WHERE d."Number" IN (8, 91)
ORDER BY 1;

-- Rollback: descomente e rode no lugar do COMMIT (blob do mapa 7 = Atlans, md5 ad966e4b…).
-- UPDATE config."GameMapDefinition" dest
-- SET "TerrainData" = src."TerrainData"
-- FROM config."GameMapDefinition" src
-- WHERE dest."Number" = 91 AND src."Number" = 7;

ROLLBACK; -- trocar por COMMIT depois de conferir as duas saídas
