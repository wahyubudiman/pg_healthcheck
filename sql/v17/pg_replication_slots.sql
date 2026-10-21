SELECT slot_name, plugin, slot_type, active, temporary, 
       conflicting,
       coalesce(failover::text, 'n/a') AS failover,
       coalesce(synced::text, 'n/a') AS synced,
       wal_status, safe_wal_size
FROM pg_replication_slots;
