SELECT d.datname, unnest(setconfig) AS setting
FROM pg_db_role_setting 
JOIN pg_database AS d ON setdatabase = d.oid;