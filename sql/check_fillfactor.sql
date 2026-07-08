SELECT pns.nspname as schemaname,pc.relkind,
pc.relname AS ObjectName, pc.relpages, pc.reltuples,
pc.reloptions AS ObjectOptions
FROM pg_class AS pc
INNER JOIN pg_namespace AS pns 
ON pns.oid = pc.relnamespace
WHERE pns.nspname not in ('sys','pg_catalog','pg_toast','information_schema','dbms_sql','dbms_utility','dbms_aqadm','dbms_aq','dbo','utl_file','utl_tcp','utl_smtp','utl_http')
and pc.reloptions is not null;

