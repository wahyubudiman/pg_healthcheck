SELECT
   round(buffers_checkpoint/nullif(buffers_clean, 0),2) AS checkpoint_spike,
   ROUND(100.0*buffers_checkpoint/nullif(buffers_checkpoint + buffers_clean + buffers_backend, 0),2) AS checkpoint_pct,
   ROUND(100.0*buffers_clean/nullif(buffers_checkpoint + buffers_clean + buffers_backend, 0),2) AS bgwriter_pct,
   ROUND(100.0*buffers_backend/nullif(buffers_checkpoint + buffers_clean + buffers_backend, 0),2) AS backend_pct
FROM
   pg_stat_bgwriter
;
