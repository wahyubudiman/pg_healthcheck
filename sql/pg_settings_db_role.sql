SELECT r.rolname, d.datname, unnest(rs.setconfig) AS setting
FROM   pg_db_role_setting rs
LEFT   JOIN pg_authid     r ON r.oid = rs.setrole
LEFT   JOIN pg_database   d ON d.oid = rs.setdatabase
order by r.rolname, d.datname;