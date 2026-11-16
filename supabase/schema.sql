-- Garnet Girls Poetry Club: run this once in Supabase → SQL Editor → New query → Run.

-- 1. Poems
create table if not exists public.submissions (
  id           bigint generated always as identity primary key,
  prompt       smallint not null check (prompt between 1 and 8),
  poet         smallint not null check (poet between 0 and 4),   -- 0 Hattie, 1 Marina, 2 Avery, 3 Lauren, 4 Unknown
  title        text check (char_length(title) <= 120),
  body         text not null check (char_length(body) <= 110000),
  file_name    text,
  file_url     text,
  submitted_at timestamptz not null default now()
);

-- The server clock decides when a poem arrived, so nobody can fake an on-time submission.
create or replace function public.stamp_submission() returns trigger
language plpgsql as $$
begin
  new.submitted_at := now();
  return new;
end $$;

drop trigger if exists stamp_submission on public.submissions;
create trigger stamp_submission before insert on public.submissions
  for each row execute function public.stamp_submission();

-- Anyone with the site can read and add poems. Nobody can edit or delete them from the site.
alter table public.submissions enable row level security;
drop policy if exists "read poems" on public.submissions;
create policy "read poems" on public.submissions for select to anon, authenticated using (true);
drop policy if exists "add poems" on public.submissions;
create policy "add poems" on public.submissions for insert to anon, authenticated with check (true);

-- Live updates when someone submits.
alter publication supabase_realtime add table public.submissions;

-- 2. Uploaded files (PDF, Word, text), 15 MB max each
insert into storage.buckets (id, name, public, file_size_limit)
values ('poems', 'poems', true, 15728640)
on conflict (id) do nothing;

drop policy if exists "upload poem files" on storage.objects;
create policy "upload poem files" on storage.objects for insert to anon, authenticated
  with check (bucket_id = 'poems');
