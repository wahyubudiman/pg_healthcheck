SELECT datname, a.rolname, pg_encoding_to_char(encoding), datcollate, datctype, pg_size_pretty(pg_database_size(datname)) db_size
FROM pg_database d, pg_authid a
WHERE d.datdba = a.oid AND datname NOT IN ('template0' ,'template1' ,'postgres' )
ORDER BY pg_database_size(datname) DESC;
