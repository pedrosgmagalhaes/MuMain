# Tema `taverna`

Identidade do servidor (madeira, latão, pergaminho) por cima do tema `modern`, sem recompilar
nada. `Base=modern` no `theme.ini`: herda o `base.rcss` e todo o vocabulário estrutural do modern
(`.modern-frame`, `.btn`, `.text-field`, `.checkbox-box`, `.modern-content-well`); este tema só
traz `tokens.ini` (paleta + tipografia) e os dois arquivos da janela de login.

Como cada janela que este tema não forka continua lendo o `.rcss` do modern, e o modern referencia
`token()` em vez de hex literal para superfície/texto/borda, o HUD, inventário, baús, NPCs etc. já
saem na paleta da taverna sem uma linha extra. Botões (`.btn`/`.btn-ok`) são a exceção conhecida:
o `base.rcss` do modern os pinta com hex literal, então continuam de ferro/carmim até alguém
forkar `base.rcss` — ver `plano-3-camadas.md`.

## Arquivos

| Arquivo | Papel |
| --- | --- |
| `theme.ini` | `Base=modern`, `[Fonts]` (Georgia do sistema, Windows e macOS), `[Meta] DisplayName` |
| `tokens.ini` | paleta e tipografia; sobrescreve só as chaves que mudam de sentido |
| `login.rml` | fork do login: letreiro de texto + mesmos ids/callbacks/modelo do `login.rml` compartilhado |
| `login.rcss` | substitui o `login.rcss` do modern **por inteiro** (regras não se somam entre temas) |

## Tokens

Os nomes são os mesmos do `modern` de propósito (herança por chave): `surface-*`, `metal-*`,
`text-*`, `accent-*`, `semantic-*`, `border-*`, `radius-*`, `font-*`, `server-*`.
`resource-hp/-mp/-sd/-ag` ficam como estão: são a cor de um atributo do jogo, não estética.

Tokens que só este tema usa:

- `font-wordmark` — família do letreiro (Georgia, com queda para Liberation Sans se faltar)
- `tavern-oak-light`, `tavern-oak-grain` — veio da madeira
- `tavern-brass-hair` — fio de latão fino
- `tavern-lantern-glow` — halo quente em volta do painel
- `tavern-carved-shadow`, `tavern-parchment-ink` — sombra entalhada / tinta

## Limites do motor (valem para qualquer fork daqui)

- `rgba()` com alfa **0-255**, não 0.0-1.0.
- Sem `::before`/`::after`, sem `content:`; `border-radius` não aceita `%`.
- `box-shadow` (inset/outset, múltiplo), `transform: rotate()` e `linear-gradient` funcionam.
- Imagem só em `.OZT`/`.OZJ` (o motor troca a extensão); arquivo ausente falha **em silêncio**.
  Por isso o letreiro é texto: trocar o nome não exige arte nenhuma.

## Trocar depois

- Nome no letreiro: a linha `Taverneiro do MU` em `login.rml`.
- Cores: `tokens.ini` (nenhum código).
- Logo grande da cena de login (`Data/Logo/MU-logo.tga`, desenhado por `login_scene.rml`): exige
  `.OZT` novo, ou forkar `login_scene.rml` para desenhar um letreiro no lugar da imagem.
- Fonte: qualquer arquivo em `[Fonts]` do `theme.ini`; o `tokens.ini` aponta a família.
