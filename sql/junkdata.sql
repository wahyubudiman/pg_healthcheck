-- select schemaname,relname,n_live_tup,n_dead_tup 
-- from pg_stat_all_tables 
-- where n_live_tup>0 
-- and n_dead_tup/n_live_tup>0.2 
-- and schemaname not in ('pg_toast','pg_catalog');

select * from (
SELECT a.schemaname,a.relname,a.n_live_tup,a.n_dead_tup,c.relpages,a.n_dead_tup,a.last_analyze,
round(100*(CASE (a.n_live_tup+a.n_dead_tup) WHEN 0 THEN 0 
ELSE c.relpages*(a.n_dead_tup/(a.n_live_tup+a.n_dead_tup)::numeric) 
END 
)/(c.relpages),2) garbage_ratio
FROM pg_class as c join pg_stat_all_tables as a 
on (c.oid = a.relid) 
where c.relpages > 0
and a.schemaname not in ('pg_toast','pg_catalog','sys','information_schema')) d 
where d.garbage_ratio > 20
order by schemaname,relname;
