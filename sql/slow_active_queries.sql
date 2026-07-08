SELECT pid, now() - query_start as "runtime", usename, datname, (wait_event IS NOT NULL) AS waiting, state, query
  FROM  pg_stat_activity
  WHERE now() - query_start > '2 minutes'::interval and state = 'active'
 ORDER BY runtime DESC;
