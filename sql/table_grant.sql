select * from (select a.schemaname, a.tablename, b.usename,
  has_table_privilege(usename, quote_ident(schemaname) || '.' || quote_ident(tablename), 'select') as has_select,
  has_table_privilege(usename, quote_ident(schemaname) || '.' || quote_ident(tablename), 'insert') as has_insert,
  has_table_privilege(usename, quote_ident(schemaname) || '.' || quote_ident(tablename), 'update') as has_update,
  has_table_privilege(usename, quote_ident(schemaname) || '.' || quote_ident(tablename), 'delete') as has_delete, 
  has_table_privilege(usename, quote_ident(schemaname) || '.' || quote_ident(tablename), 'references') as has_references, 
  has_table_privilege(usename, quote_ident(schemaname) || '.' || quote_ident(tablename), 'truncate') as has_truncate, 
  has_table_privilege(usename, quote_ident(schemaname) || '.' || quote_ident(tablename), 'trigger') as has_trigger, 
  has_table_privilege(usename, quote_ident(schemaname) || '.' || quote_ident(tablename), 'select with grant option') as has_select_go,
  has_table_privilege(usename, quote_ident(schemaname) || '.' || quote_ident(tablename), 'insert with grant option') as has_insert_go,
  has_table_privilege(usename, quote_ident(schemaname) || '.' || quote_ident(tablename), 'update with grant option') as has_update_go,
  has_table_privilege(usename, quote_ident(schemaname) || '.' || quote_ident(tablename), 'delete with grant option') as has_delete_go, 
  has_table_privilege(usename, quote_ident(schemaname) || '.' || quote_ident(tablename), 'references with grant option') as has_references_go, 
  has_table_privilege(usename, quote_ident(schemaname) || '.' || quote_ident(tablename), 'truncate with grant option') as has_truncate_go, 
  has_table_privilege(usename, quote_ident(schemaname) || '.' || quote_ident(tablename), 'trigger with grant option') as has_trigger_go 
from pg_tables a, pg_user b 
where a.schemaname not in ('information_schema','pg_catalog')
order by a.schemaname, a.tablename) as x
where x.has_select_go='t' 
or x.has_insert_go='t'
or x.has_update_go='t'
or x.has_delete_go='t'
or x.has_references_go='t'
or x.has_truncate_go='t'
or x.has_trigger_go='t';
