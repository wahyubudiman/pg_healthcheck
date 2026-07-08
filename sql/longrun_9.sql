select usename,datname,waiting,xact_start,current_query 
from pg_stat_activity 
where now()-xact_start>interval '15 sec' 
and current_query !~ '^COPY' 
order by xact_start;
