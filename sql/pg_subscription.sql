select * from pg_subscription;

select '' as text1;
select '' as text1;

WITH
			sc AS (SELECT srsubid, COUNT(*) AS c FROM pg_subscription_rel GROUP BY 1),
			swc AS (SELECT subid, COUNT(*) AS c FROM pg_stat_subscription GROUP BY 1)
		SELECT
			s.oid, s.subname, current_database(), subenabled,
			array_length(subpublications, 1) AS pubcount, sc.c AS tabcount,
			swc.c AS workercount,
			COALESCE(ss.received_lsn::text, ''),
			COALESCE(ss.latest_end_lsn::text, ''),
			ss.last_msg_send_time, ss.last_msg_receipt_time,
			COALESCE(EXTRACT(EPOCH FROM ss.latest_end_time)::bigint, 0)
		FROM
			pg_subscription s
			JOIN sc ON s.oid = sc.srsubid
			JOIN pg_stat_subscription ss ON s.oid = ss.subid
			JOIN swc ON s.oid = swc.subid
		WHERE
			ss.relid IS NULL
;
