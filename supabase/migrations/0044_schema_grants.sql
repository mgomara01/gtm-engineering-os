-- Step 44: grant schema usage + table/sequence/function privileges to the
-- `authenticated` role across every custom schema. RLS policies alone are
-- not sufficient -- Postgres checks schema/table GRANTs before RLS is ever
-- evaluated, and none of the prior 43 migrations granted USAGE on any
-- custom schema (only two views got explicit `grant select ... to
-- authenticated`). This was invisible in the SQL Editor because that runs
-- as the Postgres superuser, which bypasses grants entirely.
do $$
declare
  s text;
begin
  foreach s in array array['platform','configuration','entities','ingestion','intelligence','scoring','gtm','implementation','agents','analytics','governance','integrations','execution','extensibility','commercial','developer','reliability','security','operations','compliance','activation','pilot','rollout','resilience']
  loop
    execute format('grant usage on schema %I to authenticated, service_role', s);
    execute format('grant select, insert, update, delete on all tables in schema %I to authenticated', s);
    execute format('grant select, insert, update, delete on all tables in schema %I to service_role', s);
    execute format('grant usage, select on all sequences in schema %I to authenticated, service_role', s);
    execute format('grant execute on all functions in schema %I to authenticated, service_role', s);
    execute format('alter default privileges in schema %I grant select, insert, update, delete on tables to authenticated', s);
    execute format('alter default privileges in schema %I grant usage, select on sequences to authenticated', s);
    execute format('alter default privileges in schema %I grant execute on functions to authenticated', s);
  end loop;
end $$;
