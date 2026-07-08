select t2.nspname, t1.relname, t3.idx_cnt 
from pg_class t1, pg_namespace t2, 
(select indrelid,count(*) idx_cnt from pg_index group by 1 having count(*)>5) t3 
where t1.oid=t3.indrelid 
and t1.relnamespace=t2.oid 
order by t3.idx_cnt desc;
