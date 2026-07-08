select t1.datname, t2.query, t2.calls, t2.total_time, t2.total_time/t2.calls cpu_time_per_call 
from pg_database t1, pg_stat_statements t2 
where t1.oid=t2.dbid 
order by t2.calls desc 
limit 20;

select '' as text1;
select '' as text1;

select t1.datname, t2.query, t2.calls, t2.total_time, t2.total_exec_time 
from pg_database t1, pg_stat_statements t2 
ORDER BY t2.total_exec_time DESC
limit 20;
