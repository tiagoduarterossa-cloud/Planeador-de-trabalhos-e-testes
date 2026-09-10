# Planeador — como publicar e instalar como app real

Estes ficheiros formam uma **PWA** (Progressive Web App): uma app web que, depois de publicada online, se instala no telemóvel como qualquer outra app — ícone no ecrã principal, ecrã inteiro (sem barra do browser), e funciona mesmo sem internet depois da primeira abertura.

## Passo 1 — Publicar os ficheiros online (grátis, ~5 min)

A forma mais simples é o **GitHub Pages**:

1. Cria uma conta em github.com (se ainda não tiveres)
2. Cria um novo repositório (ex: `planeador`), público
3. Faz upload destes 5 ficheiros para esse repositório:
   `index.html`, `manifest.json`, `sw.js`, `icon-192.png`, `icon-512.png`
4. Vai a **Settings → Pages**, em "Branch" escolhe `main` e guarda
5. Ao fim de 1-2 minutos, o GitHub dá-te um link tipo:
   `https://oteunome.github.io/planeador/`

Alternativa igualmente simples: arrastar a pasta para **netlify.com/drop** — dá-te um link instantâneo, sem precisares de conta.

## Passo 2 — Instalar no telemóvel

Abre o link publicado no telemóvel:

**Android (Chrome):** toca no menu (⋮) → "Adicionar ao ecrã principal" / "Instalar app"

**iPhone (Safari):** toca no botão de partilhar (□↑) → "Adicionar ao ecrã principal"

Fica com ícone próprio, abre em ecrã inteiro, e os dados ficam guardados no telemóvel mesmo offline.

## Notas

- Os dados (trabalhos e testes) ficam guardados **só nesse telemóvel/browser** — não há sincronização entre dispositivos nesta versão.
- Para mudar cores, textos ou comportamento, edita `index.html` (tudo está num único ficheiro: HTML, CSS e JavaScript).
