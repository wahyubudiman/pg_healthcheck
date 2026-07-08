select n.nspname as schema, c.relowner, c.relname, c.reloptions, c.relpersistence, c.relkind
from pg_class c join pg_namespace n on n.oid = c.relnamespace
where c.reloptions is not null;