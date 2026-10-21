SELECT
   ckpt.num_timed AS checkpoints_timed,
   ckpt.num_requested AS checkpoints_req,
   ROUND(100.0 * ckpt.num_timed / NULLIF(ckpt.num_timed + ckpt.num_requested, 0), 2) AS timed_pct,
   ROUND(100.0 * ckpt.num_requested / NULLIF(ckpt.num_timed + ckpt.num_requested, 0), 2) AS requested_pct,
   ckpt.buffers_written AS buffers_checkpoint,
   bg.buffers_clean,
   bg.maxwritten_clean,
   bg.buffers_alloc
FROM
   pg_stat_checkpointer ckpt,
   pg_stat_bgwriter bg;
