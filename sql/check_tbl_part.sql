SELECT
    nspname ,
    relname ,
    COUNT(*) AS partition_num
FROM
    pg_class c ,
    pg_namespace n ,
    pg_inherits i
WHERE
    c.oid = i.inhparent
    AND c.relnamespace = n.oid
    AND c.relhassubclass
    AND c.relkind = 'r'
GROUP BY 1,2 ORDER BY partition_num DESC;
