select schemaname, relname, 
CASE heap_blks_hit+heap_blks_read WHEN 0 then 100 else round(heap_blks_hit*100/(heap_blks_hit+heap_blks_read), 2) end as table_hit_ratio
from pg_statio_all_tables
where schemaname not in ('pg_catalog','pg_toast','sys','information_schema')
order by table_hit_ratio desc;
