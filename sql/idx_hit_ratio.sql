select schemaname, relname, indexrelname,
CASE WHEN idx_blks_read is NULL then 0 when idx_blks_hit+idx_blks_read=0 then 100 else round(idx_blks_hit*100/(idx_blks_hit+idx_blks_read + 0.0001), 2) end as index_hit_ratio
from pg_statio_all_indexes
where schemaname not in ('pg_catalog','pg_toast','sys','information_schema')
order by index_hit_ratio desc;

