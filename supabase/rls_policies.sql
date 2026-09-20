-- Políticas de Row Level Security (RLS) para o Planeador
--
-- PORQUÊ ISTO IMPORTA: o index.html nunca filtra por utilizador nas leituras
-- (pede "tasks?select=*" e confia inteiramente no Postgres para devolver só
-- o que é teu ou partilhado contigo). Sem RLS ativo nestas tabelas, qualquer
-- pessoa com uma conta no Planeador consegue ler e escrever os dados de
-- qualquer outra pessoa, incluindo horários, checklists e ficheiros.
--
-- CONFIRMADO no projeto (20/09/2026, via Database → Functions):
--   share_task_by_email     insere em task_shares (task_id, owner_id, shared_with)
--   share_calendar_by_email insere em calendar_shares (owner_id, shared_with)
-- As secções 5-7 abaixo já usam estes nomes reais.
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

-- 5) Ativa RLS nas tabelas de partilha e permite às duas partes vê-las -----
alter table if exists public.task_shares enable row level security;
drop policy if exists "task_shares_visible_to_parties" on public.task_shares;
create policy "task_shares_visible_to_parties" on public.task_shares
  for select using (auth.uid() = owner_id or auth.uid() = shared_with);

alter table if exists public.calendar_shares enable row level security;
drop policy if exists "calendar_shares_visible_to_parties" on public.calendar_shares;
create policy "calendar_shares_visible_to_parties" on public.calendar_shares
  for select using (auth.uid() = owner_id or auth.uid() = shared_with);

-- 6) Quem recebeu a partilha (de um trabalho ou da agenda toda) passa a
--    ver esse trabalho -------------------------------------------------
drop policy if exists "tasks_shared_select" on public.tasks;
create policy "tasks_shared_select" on public.tasks
  for select using (
    exists (
      select 1 from public.task_shares ts
      where ts.task_id = tasks.id and ts.shared_with = auth.uid()
    )
    or exists (
      select 1 from public.calendar_shares cs
      where cs.owner_id = tasks.user_id and cs.shared_with = auth.uid()
    )
  );

-- 7) E também consegue abrir o anexo desse trabalho partilhado (antes só
--    o dono conseguia) --------------------------------------------------
drop policy if exists "ficheiros_shared_select" on storage.objects;
create policy "ficheiros_shared_select" on storage.objects
  for select using (
    bucket_id = 'ficheiros'
    and exists (
      select 1 from public.tasks t
      where t.attachment_path = storage.objects.name
        and (
          exists (select 1 from public.task_shares ts where ts.task_id = t.id and ts.shared_with = auth.uid())
          or exists (select 1 from public.calendar_shares cs where cs.owner_id = t.user_id and cs.shared_with = auth.uid())
        )
    )
  );
