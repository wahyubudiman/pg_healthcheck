select datname,
round(100*xact_commit::numeric/(case when xact_rollback > 0 then xact_rollback else 1 end + xact_commit),2) commit_ratio,
round(100*xact_rollback::numeric/(case when xact_commit > 0 then xact_commit else 1 end + xact_rollback),2) rollback_ratio,
round(100*blks_hit::numeric/(case when blks_read>0 then blks_read else 1 end + blks_hit),2) buffer_hit_ratio,
round(100*blks_read::numeric/(case when blks_hit>0 then blks_hit else 1 end + blks_read),2) read_ratio 
from pg_stat_database;
