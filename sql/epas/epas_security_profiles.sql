SELECT (to_regclass('sys.edb_profile') IS NOT NULL) AS has_profile \gset
\if :has_profile
SELECT * FROM sys.edb_profile;
\else
SELECT 'sys.edb_profile not installed' AS edb_profile_status;
\endif
