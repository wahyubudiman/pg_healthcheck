select datname,usename, application_name, client_addr, backend_start, xact_start, query_start, 
state_change, wait_event_type, wait_event, query, backend_type    
from pg_stat_activity 
where state = 'active' 
and now() - query_start > '15 sec'::interval 
and query ~* '^(insert|update|delete)';

