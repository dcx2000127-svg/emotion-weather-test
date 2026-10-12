-- Run this once in the Supabase SQL Editor for your project.
create extension if not exists pgcrypto with schema extensions;

create table if not exists public.access_codes (
  code_hash text primary key,
  used_count integer not null default 0 check (used_count >= 0),
  max_uses integer not null default 3 check (max_uses > 0),
  created_at timestamptz not null default now()
);

alter table public.access_codes enable row level security;
revoke all on public.access_codes from anon, authenticated;

create or replace function public.check_test_code(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_remaining integer;
begin
  if p_code is null or length(trim(p_code)) < 8 or length(p_code) > 128 then
    return jsonb_build_object('allowed', false, 'remaining', 0);
  end if;

  select max_uses - used_count into v_remaining
  from public.access_codes
  where code_hash = encode(extensions.digest(trim(p_code), 'sha256'), 'hex');

  if v_remaining is null or v_remaining <= 0 then
    return jsonb_build_object('allowed', false, 'remaining', 0);
  end if;

  return jsonb_build_object('allowed', true, 'remaining', v_remaining);
end;
$$;

create or replace function public.consume_test_code(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_remaining integer;
begin
  if p_code is null or length(trim(p_code)) < 8 or length(p_code) > 128 then
    return jsonb_build_object('consumed', false, 'remaining', 0);
  end if;

  update public.access_codes
  set used_count = used_count + 1
  where code_hash = encode(extensions.digest(trim(p_code), 'sha256'), 'hex')
    and used_count < max_uses
  returning max_uses - used_count into v_remaining;

  if v_remaining is null then
    return jsonb_build_object('consumed', false, 'remaining', 0);
  end if;

  return jsonb_build_object('consumed', true, 'remaining', v_remaining);
end;
$$;

revoke all on function public.check_test_code(text) from public;
revoke all on function public.consume_test_code(text) from public;
grant execute on function public.check_test_code(text) to anon, authenticated;
grant execute on function public.consume_test_code(text) to anon, authenticated;

-- After running this schema, replace the placeholder with a unique password
-- (at least 8 characters) and run the INSERT once in the SQL Editor:
-- insert into public.access_codes (code_hash, max_uses)
-- values (encode(extensions.digest('REPLACE_WITH_A_UNIQUE_PASSWORD', 'sha256'), 'hex'), 3);
