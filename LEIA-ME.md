# Planeador — como publicar e instalar como app real

Estes ficheiros formam uma **PWA** (Progressive Web App): uma app web que, depois de publicada online, se instala no telemóvel como qualquer outra app — ícone no ecrã principal, ecrã inteiro (sem barra do browser), e funciona mesmo sem internet depois da primeira abertura.

## Passo 0 — Antes de publicares: segurança no Supabase (não saltes isto)

Esta app tem contas, partilha de trabalhos e agenda entre utilizadores, e
ficheiros anexados — mas o `index.html` nunca filtra os dados por
utilizador nos pedidos, confia inteiramente no **Row Level Security (RLS)**
do Postgres para decidir quem vê o quê. Se nunca configuraste RLS nas
tabelas do Supabase, qualquer pessoa com conta consegue ler e escrever os
dados de qualquer outra pessoa assim que a app estiver pública.

1. Abre `supabase/rls_policies.sql` neste repositório.
2. Confirma no Table Editor do teu projeto Supabase que os nomes de tabela
   e coluna correspondem ao que está no ficheiro (foi escrito a partir do
   código, não da tua base de dados real).
3. Corre o script no SQL Editor do Supabase.
4. Testa com duas contas diferentes: cria um trabalho numa, partilha com a
   outra, confirma que a segunda só vê o que lhe foi partilhado (e não
   tudo).

A secção de partilha do script vem comentada de propósito — precisa que
confirmes como `share_task_by_email` / `share_calendar_by_email` guardam
essa relação antes de a ativares.

## Passo 1 — Publicar os ficheiros online (grátis, ~5 min)

A forma mais simples é o **GitHub Pages**:

1. Se estiveste a desenvolver numa branch diferente de `main` (ex: uma
   branch do Claude Code), faz merge dela para `main` primeiro.
2. No repositório no GitHub, vai a **Settings → Pages**.
3. Em "Build and deployment" → "Source", escolhe **Deploy from a branch**.
4. Em "Branch", escolhe `main` e a pasta `/ (root)`, e guarda.
5. Ao fim de 1-2 minutos, o GitHub dá-te um link tipo:
   `https://oteunome.github.io/planeador-de-trabalhos-e-testes/`

O ficheiro `.nojekyll` já está incluído no repositório — sem ele, o GitHub
Pages tenta processar os ficheiros como um site Jekyll e pode ignorar ou
alterar coisas que não devia.

Alternativa igualmente simples: arrastar a pasta para **netlify.com/drop** — dá-te um link instantâneo, sem precisares de conta.

## Passo 2 — Instalar no telemóvel

Abre o link publicado no telemóvel:

**Android (Chrome):** toca no menu (⋮) → "Adicionar ao ecrã principal" / "Instalar app"

**iPhone (Safari):** toca no botão de partilhar (□↑) → "Adicionar ao ecrã principal"

Fica com ícone próprio, abre em ecrã inteiro, e os dados ficam guardados no telemóvel mesmo offline.

## Notas

- Os dados sincronizam com o Supabase quando há ligação; sem ligação, a app continua a funcionar com a última cópia guardada no telemóvel.
- **Google Agenda (ligação automática):** o botão "Conectar Google Agenda" só aparece depois de substituíres `GOOGLE_CLIENT_ID` (no `index.html`) por um Client ID real, criado no Google Cloud Console. Até lá fica escondido de propósito, para não mostrar um botão que falha sempre. O botão "Adicionar ao Google Agenda" em cada item continua a funcionar sem isto, porque usa um link simples sem autenticação.
- Para mudar cores, textos ou comportamento, edita `index.html` (tudo está num único ficheiro: HTML, CSS e JavaScript).
