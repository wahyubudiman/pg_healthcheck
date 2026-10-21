SELECT (to_regclass('sys.edb_redact_policy') IS NOT NULL) AS has_redact \gset
\if :has_redact
SELECT * FROM sys.edb_redact_policy;
\else
SELECT 'sys.edb_redact_policy not installed' AS edb_redaction_status;
\endif
