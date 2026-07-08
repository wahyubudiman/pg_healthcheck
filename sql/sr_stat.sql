select 
usename
,application_name
,client_addr 
,client_hostname 
,client_port 
,backend_start 
,state 
,sync_state
,write_lag 
,flush_lag 
,replay_lag
,sync_priority 
,sent_lsn
,write_lsn 
,flush_lsn 
,replay_lsn
from pg_stat_replication;
