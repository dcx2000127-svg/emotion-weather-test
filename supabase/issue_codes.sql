-- Run once in Supabase SQL Editor as project owner/postgres.
-- Then issue codes by running: select * from public.issue_test_codes(10);
-- Each generated code is returned once and stored only as a SHA-256 hash.
create or replace function public.issue_test_codes(p_count integer default 1)
returns table(access_code text)
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  i integer;
  v_code text;
  v_inserted integer;
begin
  if p_count is null or p_count < 1 or p_count > 200 then
    raise exception 'p_count must be between 1 and 200';
  end if;

  for i in 1..p_count loop
    loop
      v_code := 'EW-' || upper(substr(encode(extensions.gen_random_bytes(16), 'hex'), 1, 20));
      insert into public.access_codes (code_hash, max_uses)
      values (encode(extensions.digest(v_code, 'sha256'), 'hex'), 3)
      on conflict (code_hash) do nothing;
      get diagnostics v_inserted = row_count;
      exit when v_inserted = 1;
    end loop;
    access_code := v_code;
    return next;
  end loop;
end;
$$;

revoke all on function public.issue_test_codes(integer) from public;
revoke all on function public.issue_test_codes(integer) from anon, authenticated;
grant execute on function public.issue_test_codes(integer) to postgres;
