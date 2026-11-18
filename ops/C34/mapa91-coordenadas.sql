-- C34 — mapa 91 (Cabo Polonio / Tarkan): gate de spawn e areas de spawn em chao firme.
--
-- POR QUE: as coordenadas do C31 caem fora da area com chao do Tarkan. O cliente nao desenha telha
-- com TW_NOGROUND (RenderTerrainTile), entao o mapa saia preto: personagem no vazio, clique sem alvo,
-- monstros invisiveis. Conferido celula por celula em Data/World9/EncTerrain9.att com a cifra do
-- proprio cliente: gate atual 0/16 celulas com chao, Arcanjo 0/25. As caixas abaixo tem 187/187 de
-- chao (100%) e 169/187 (90%) andaveis a pe, e o Arcanjo fica a 160 telhas do gate.
--
-- Validacao: Shared/MU/tools/checar_coordenadas.py Data/World9/EncTerrain9.att <caixas>  -> exit 0
--
-- Este arquivo e o REGISTRO da correcao. Ele nao e o seed definitivo: mapa 90/91, warp e gates nao
-- existem no inicializador C# do OpenMU (foram criados direto no banco), entao um deploy novo precisa
-- de C31 + C34 aplicados, ou de um IDataInitializationPlugIn (card proprio).
--
-- NAO aplicado: escrita em producao e restart dependem da aprovacao do Pedro.

\set ON_ERROR_STOP on

\echo '=== ANTES ==='
select 'gate' tipo, g."X1", g."Y1", g."X2", g."Y2", null::int qtd
  from config."ExitGate" g join config."GameMapDefinition" m on m."Id" = g."MapId"
 where m."Number" = 91 and g."IsSpawnGate"
union all
select 'spawn ' || m2."Number", s."X1", s."Y1", s."X2", s."Y2", s."Quantity"
  from config."MonsterSpawnArea" s
  join config."MonsterDefinition" m2 on m2."Id" = s."MonsterDefinitionId"
  join config."GameMapDefinition" g2 on g2."Id" = s."GameMapId"
 where g2."Number" = 91
 order by 1;

BEGIN;

-- Gate de spawn do mapa 91 (o /move 91 e o warp "Cabo Polonio" caem aqui)
UPDATE config."ExitGate"
   SET "X1" = 188, "Y1" = 62, "X2" = 204, "Y2" = 72
 WHERE "Id" = '00000911-0000-0000-0000-000000000091'
   AND ("X1", "Y1", "X2", "Y2") IS DISTINCT FROM (188, 62, 204, 72);

-- Areas de spawn (quantidades e modelos como estao; so muda a caixa)
UPDATE config."MonsterSpawnArea" SET "X1" = 186, "Y1" = 106, "X2" = 202, "Y2" = 116
 WHERE "Id" = '00000800-0000-0000-0000-000000000700'   -- Lagarto da Areia (18)
   AND ("X1", "Y1", "X2", "Y2") IS DISTINCT FROM (186, 106, 202, 116);
UPDATE config."MonsterSpawnArea" SET "X1" = 130, "Y1" =  50, "X2" = 146, "Y2" =  60
 WHERE "Id" = '00000800-0000-0000-0000-000000000701'   -- Guerreiro das Dunas (12)
   AND ("X1", "Y1", "X2", "Y2") IS DISTINCT FROM (130, 50, 146, 60);
UPDATE config."MonsterSpawnArea" SET "X1" = 117, "Y1" =  27, "X2" = 133, "Y2" =  37
 WHERE "Id" = '00000800-0000-0000-0000-000000000702'   -- Fada Carmesim (12)
   AND ("X1", "Y1", "X2", "Y2") IS DISTINCT FROM (117, 27, 133, 37);
UPDATE config."MonsterSpawnArea" SET "X1" =  90, "Y1" =  46, "X2" = 106, "Y2" =  56
 WHERE "Id" = '00000800-0000-0000-0000-000000000703'   -- Mago Serafico (8)
   AND ("X1", "Y1", "X2", "Y2") IS DISTINCT FROM (90, 46, 106, 56);
UPDATE config."MonsterSpawnArea" SET "X1" =  52, "Y1" = 145, "X2" =  68, "Y2" = 155
 WHERE "Id" = '00000800-0000-0000-0000-000000000704'   -- O Arcanjo Escarlate (1)
   AND ("X1", "Y1", "X2", "Y2") IS DISTINCT FROM (52, 145, 68, 155);

\echo '=== DEPOIS ==='
select 'gate' tipo, g."X1", g."Y1", g."X2", g."Y2", null::int qtd
  from config."ExitGate" g join config."GameMapDefinition" m on m."Id" = g."MapId"
 where m."Number" = 91 and g."IsSpawnGate"
union all
select 'spawn ' || m2."Number", s."X1", s."Y1", s."X2", s."Y2", s."Quantity"
  from config."MonsterSpawnArea" s
  join config."MonsterDefinition" m2 on m2."Id" = s."MonsterDefinitionId"
  join config."GameMapDefinition" g2 on g2."Id" = s."GameMapId"
 where g2."Number" = 91
 order by 1;

-- Nenhum jogador e tocado por este arquivo:
select (select count(*) from data."Account") contas, (select count(*) from data."Character") personagens;

-- COMMIT;   <- so na janela aprovada, com backup fresco e restart em seguida
ROLLBACK;

-- ROLLBACK (valores de hoje, para desfazer depois de um COMMIT)
-- UPDATE config."ExitGate" SET "X1" = 15, "Y1" = 11, "X2" = 18, "Y2" = 14
--  WHERE "Id" = '00000911-0000-0000-0000-000000000091';
-- UPDATE config."MonsterSpawnArea" SET "X1" =  8, "Y1" =  8, "X2" =  60, "Y2" = 40 WHERE "Id" = '00000800-0000-0000-0000-000000000700';
-- UPDATE config."MonsterSpawnArea" SET "X1" = 20, "Y1" = 10, "X2" =  80, "Y2" = 50 WHERE "Id" = '00000800-0000-0000-0000-000000000701';
-- UPDATE config."MonsterSpawnArea" SET "X1" = 30, "Y1" = 20, "X2" =  90, "Y2" = 60 WHERE "Id" = '00000800-0000-0000-0000-000000000702';
-- UPDATE config."MonsterSpawnArea" SET "X1" = 40, "Y1" = 30, "X2" = 100, "Y2" = 70 WHERE "Id" = '00000800-0000-0000-0000-000000000703';
-- UPDATE config."MonsterSpawnArea" SET "X1" = 60, "Y1" = 40, "X2" =  64, "Y2" = 44 WHERE "Id" = '00000800-0000-0000-0000-000000000704';
