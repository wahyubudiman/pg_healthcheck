select usename,datname,state,wait_event_type,wait_event,xact_start,query 
from pg_stat_activity 
where now()-xact_start>interval '15 sec' 
and query !~ '^COPY' 
and state<>'idle' 
order by xact_start;
