-- Garnet Girls Poetry Club: let poets edit their own poems until the deadline.
-- Run once in Supabase → SQL Editor → New query → Run (after schema.sql).
--
-- How it works: submitting through submit_poem() hands back a secret edit key, which the
-- poet's browser keeps. edit_poem() only changes a poem when given its key, and only
-- until that prompt's deadline. The keys live in a table the site can't read.

alter table public.submissions add column if not exists edited_at timestamptz;

create table if not exists public.submission_keys (
  submission_id bigint primary key references public.submissions(id) on delete cascade,
  edit_key      uuid not null default gen_random_uuid()
);
alter table public.submission_keys enable row level security;   -- no policies: the site can't read keys

-- Deadline for a prompt: 11:59 PM Pacific on Nov 17, 19, 21, 23, 25, 27, 29 and Dec 1.
create or replace function public.prompt_due(p smallint) returns timestamptz
language sql immutable as $$
  select ((date '2026-11-15' + 2 * p) + time '23:59:59.999') at time zone 'America/Los_Angeles'
$$;

create or replace function public.submit_poem(p_prompt smallint, p_poet smallint, p_title text, p_body text,
                                              p_file_name text default null, p_file_url text default null)
returns json language plpgsql security definer set search_path = public as $$
declare r public.submissions; k uuid;
begin
  insert into public.submissions (prompt, poet, title, body, file_name, file_url)
  values (p_prompt, p_poet, p_title, p_body, p_file_name, p_file_url) returning * into r;
  insert into public.submission_keys (submission_id) values (r.id) returning edit_key into k;
  return json_build_object('row', row_to_json(r), 'edit_key', k);
end $$;

create or replace function public.edit_poem(p_id bigint, p_key uuid, p_title text, p_body text)
returns public.submissions language plpgsql security definer set search_path = public as $$
declare r public.submissions;
begin
  if not exists (select 1 from public.submission_keys where submission_id = p_id and edit_key = p_key) then
    raise exception 'You can only edit poems you submitted from this browser.';
  end if;
  select * into r from public.submissions where id = p_id;
  if now() > public.prompt_due(r.prompt) then
    raise exception 'The deadline for this prompt has passed, so this poem is locked.';
  end if;
  update public.submissions set title = p_title, body = p_body, edited_at = now()
  where id = p_id returning * into r;
  return r;
end $$;

revoke all on function public.submit_poem(smallint, smallint, text, text, text, text) from public;
revoke all on function public.edit_poem(bigint, uuid, text, text) from public;
grant execute on function public.submit_poem(smallint, smallint, text, text, text, text) to anon, authenticated;
grant execute on function public.edit_poem(bigint, uuid, text, text) to anon, authenticated;
