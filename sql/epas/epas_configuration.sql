SELECT name, setting, unit, short_desc 
FROM pg_settings 
WHERE name IN (
    'edb_audit', 'edb_audit_directory', 'edb_audit_filename', 'edb_audit_statement', 
    'edb_redwood_date', 'edb_redwood_greatest_least', 'edb_redwood_strings', 
    'db_dialect', 'edb_dynatune', 'edb_dynatune_profile'
)
ORDER BY name;
