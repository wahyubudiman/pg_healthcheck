SELECT 
    now()-pg_postmaster_start_time() "Uptime", 
    now()-ckpt.stats_reset "Since checkpointer reset",
    ckpt.num_timed "Checkpoints timed",
    ckpt.num_requested "Checkpoints req",
    round(100.0*ckpt.num_requested/nullif(ckpt.num_timed + ckpt.num_requested, 0),1) "Forced checkpoint ratio (%)",
    round(ckpt.write_time::numeric/nullif((ckpt.num_timed + ckpt.num_requested)*1000, 0),2) "Avg write time per checkpoint (s)",
    round(ckpt.sync_time::numeric/nullif((ckpt.num_timed + ckpt.num_requested)*1000, 0),2) "Avg sync time per checkpoint (s)",
    ckpt.buffers_written "Buffers written by checkpointer",
    bg.buffers_clean "Buffers clean by bgwriter",
    bg.maxwritten_clean "Maxwritten clean events",
    bg.buffers_alloc "Buffers allocated",
    current_setting('checkpoint_timeout') "checkpoint_timeout",
    current_setting('max_wal_size') "max_wal_size",
    current_setting('checkpoint_completion_target') "checkpoint_completion_target"
FROM pg_stat_checkpointer ckpt, pg_stat_bgwriter bg;
