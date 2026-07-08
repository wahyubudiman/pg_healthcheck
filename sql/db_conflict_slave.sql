-- The pg_stat_database_conflicts view will contain one row per database, 
-- showing database-wide statistics about query cancels occurring due to conflicts with recovery on standby servers. 
-- This view will only contain information on standby servers, since conflicts do not occur on master servers.
select * from pg_stat_database_conflicts where datname not in ('template1','template0');

