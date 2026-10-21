SELECT 'pg_stat_checkpointer' AS stat_type,
       num_timed, num_requested, write_time, sync_time, buffers_written, stats_reset
FROM pg_stat_checkpointer;

SELECT 'pg_stat_bgwriter' AS stat_type,
       buffers_clean, maxwritten_clean, buffers_alloc, stats_reset
FROM pg_stat_bgwriter;
