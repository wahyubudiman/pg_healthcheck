select s.setting max_conn,a.used_session used_conn ,s.setting::bigint - a.used_session conn_remain 
from pg_settings s, (select count(*) as used_session from pg_stat_activity) a 
where s.name='max_connections';
