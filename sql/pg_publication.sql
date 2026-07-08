select * from pg_publication;

select '' as text1;
select '' as text1;

WITH pc AS (SELECT pubname, COUNT(*) AS cnt FROM pg_publication_tables GROUP BY 1)
SELECT p.oid, p.pubname, current_database(), puballtables, pubinsert,
pubupdate, pubdelete, pc.cnt
FROM pg_publication p JOIN pc ON p.pubname = pc.pubname;
