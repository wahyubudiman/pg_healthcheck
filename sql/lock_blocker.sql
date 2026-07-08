SELECT COALESCE(D.datname, ''), L.locktype, L.mode, L.granted,
       COALESCE(L.pid, 0), COALESCE(L.relation, 0), '0' waitstart
  FROM pg_locks L LEFT OUTER JOIN pg_database D ON L.database = D.oid
;

select ' ' as text1;
select ' ' as text2;

SELECT DISTINCT blocked_locks.pid AS blocked_pid, blocking_locks.pid AS blocking_pid
 FROM  pg_catalog.pg_locks blocked_locks
  JOIN pg_catalog.pg_locks blocking_locks
        ON blocking_locks.locktype = blocked_locks.locktype
        AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
        AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
        AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
        AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
        AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
        AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
        AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
        AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
        AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
        AND blocking_locks.pid != blocked_locks.pid
WHERE NOT blocked_locks.GRANTED;

select ' ' as text1;
select ' ' as text2;

select pid, 
       usename, 
       pg_blocking_pids(pid) as blocked_by, 
       query as blocked_query
from pg_stat_activity
where cardinality(pg_blocking_pids(pid)) > 0;

