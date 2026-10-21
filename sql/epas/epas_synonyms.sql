SELECT (to_regclass('sys.all_synonyms') IS NOT NULL) AS has_synonyms \gset
\if :has_synonyms
SELECT count(*) AS total_synonyms FROM sys.all_synonyms;
SELECT synname, schemaname, synowner, tablename, tablespace 
FROM sys.all_synonyms 
LIMIT 30;
\else
SELECT 'sys.all_synonyms not installed' AS total_synonyms;
\endif
