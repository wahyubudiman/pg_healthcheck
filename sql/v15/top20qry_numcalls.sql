select t1.datname, t2.query, t2.calls, round(t2.total_exec_time::numeric, 2) as total_exec_time, round((t2.total_exec_time/t2.calls)::numeric, 2) as time_per_call 
from pg_database t1, pg_stat_statements t2 
where t1.oid=t2.dbid 
order by t2.calls desc 
limit 20;
