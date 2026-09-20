-- Políticas de Row Level Security (RLS) para o Planeador
--
-- PORQUÊ ISTO IMPORTA: o index.html nunca filtra por utilizador nas leituras
-- (pede "tasks?select=*" e confia inteiramente no Postgres para devolver só
-- o que é teu ou partilhado contigo). Sem RLS ativo nestas tabelas, qualquer
-- pessoa com uma conta no Planeador consegue ler e escrever os dados de
-- qualquer outra pessoa, incluindo horários, checklists e ficheiros.
--
-- IMPORTANTE — LÊ ANTES DE CORRER:
-- Estas políticas foram escritas a partir do que o index.html pede à API
-- (colunas e nomes de tabela como aparecem no código), não foram lidas
-- diretamente da tua base de dados. Antes de correr isto:
--   1. Abre o Table Editor no dashboard do Supabase e confirma que as
--      tabelas "tasks", "class_schedule", "checklist_items" e
--      "push_subscriptions" existem com estes nomes de coluna.
--   2. A secção 3 (partilha) fica comentada de propósito — precisa que
--      confirmes como as funções share_task_by_email e
--      share_calendar_by_email guardam "quem partilhou com quem" antes de
--      a ativar. Sem isso, corro o risco de escrever uma policy que
--      bloqueia a partilha em vez de a proteger.
--
-- Corre isto no SQL Editor do Supabase:
-- https://supabase.com/dashboard/project/_/sql/new

-- 1) Ativa RLS -----------------------------------------------------------
alter table if exists public.tasks enable row level security;
alter table if exists public.class_schedule enable row level security;
alter table if exists public.checklist_items enable row level security;
alter table if exists public.push_subscriptions enable row level security;

-- 2) Cada pessoa só vê e edita o que é dela -------------------------------

drop policy if exists "tasks_owner_select" on public.tasks;
create policy "tasks_owner_select" on public.tasks
  for select using (auth.uid() = user_id);

drop policy if exists "tasks_owner_write" on public.tasks;
create policy "tasks_owner_write" on public.tasks
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "schedule_owner" on public.class_schedule;
create policy "schedule_owner" on public.class_schedule
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "checklist_owner" on public.checklist_items;
create policy "checklist_owner" on public.checklist_items
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "push_subscriptions_owner" on public.push_subscriptions;
create policy "push_subscriptions_owner" on public.push_subscriptions
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- 3) Partilha (por confirmar antes de ativar) -----------------------------
-- Depois de confirmares a tabela real onde share_task_by_email /
-- share_calendar_by_email guardam a relação de partilha, adapta e
-- descomenta algo como isto (nomes de exemplo: task_shares, calendar_shares):
--
-- drop policy if exists "tasks_shared_select" on public.tasks;
-- create policy "tasks_shared_select" on public.tasks
--   for select using (
--     exists (
--       select 1 from public.task_shares ts
--       where ts.task_id = tasks.id and ts.shared_with_user_id = auth.uid()
--     )
--     or exists (
--       select 1 from public.calendar_shares cs
--       where cs.owner_user_id = tasks.user_id and cs.shared_with_user_id = auth.uid()
--     )
--   );
--
-- Nota: a policy "tasks_owner_select" acima e esta são aditivas (RLS junta
-- todas as policies de SELECT com OR), por isso não é preciso escolher
-- uma ou outra.

-- 4) Storage — bucket "ficheiros" ------------------------------------------
-- Cada ficheiro vive em "<user_id>/nome.ext", por isso a policy confirma
-- dono pelo primeiro segmento do caminho.
drop policy if exists "ficheiros_owner_select" on storage.objects;
create policy "ficheiros_owner_select" on storage.objects
  for select using (bucket_id = 'ficheiros' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "ficheiros_owner_insert" on storage.objects;
create policy "ficheiros_owner_insert" on storage.objects
  for insert with check (bucket_id = 'ficheiros' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "ficheiros_owner_delete" on storage.objects;
create policy "ficheiros_owner_delete" on storage.objects
  for delete using (bucket_id = 'ficheiros' and (storage.foldername(name))[1] = auth.uid()::text);

-- LIMITAÇÃO CONHECIDA: com só isto, quem recebe um trabalho partilhado
-- (via share_task_by_email) não vai conseguir abrir o anexo desse trabalho
-- — o storage só deixa o dono da pasta aceder. Resolver isto também depende
-- de confirmares a tabela de partilha da secção 3; depois de a teres,
-- a policy de storage tem de juntar essa tabela em vez de comparar só a pasta.
