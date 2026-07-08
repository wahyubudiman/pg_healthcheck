select name,setting,category,context
from pg_settings
where category ilike '%Replication%'
union all 
select name,setting,category,context 
from pg_settings 
where name in ('synchronous_commit','archive_command','archive_mode','archive_timeout');

