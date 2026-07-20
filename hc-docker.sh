#!/usr/bin/env bash

# ==============================================================================
# Healthcheck Script for PostgreSQL running inside Docker Containers
# Derived from hc-md.sh & hc-cnpg.sh
#
# Audits PostgreSQL running in a Docker container (either locally or remotely)
# and formats the output report in Markdown (.md).
# ==============================================================================

set -o pipefail

# Set color codes for terminal stdout
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values (overridden by flags or environment variables)
CONTAINER_NAME="${DOCKER_CONTAINER:-}"
PGHOST="${PGHOST:-127.0.0.1}"
PGPORT="${PGPORT:-5432}"
DBUSER="${PGUSR:-${PGUSER:-postgres}}"
DBPASSWORD="${PGPASSWORD:-}"
DBNAME="${DBNAME:-postgres}"
OUTPUT_FILE="${OUTPUT_FILE:-}"
FORCE_EXEC=0

usage() {
    echo -e "${YELLOW}Usage:${NC} $0 [-c <container_name>] [-H <host>] [-P <port>] [-u <db_user>] [-w <db_password>] [-d <db_name>] [-o <output_file>] [-e]"
    echo "  -c: Docker container name or ID (Optional, enables Docker container metrics & exec mode)"
    echo "  -H: Database host IP or hostname (Optional, default: 127.0.0.1 or DOCKER_HOST)"
    echo "  -P: Database port (Optional, default: 5432)"
    echo "  -u: PostgreSQL superuser (Optional, default: postgres)"
    echo "  -w: PostgreSQL superuser password (Optional)"
    echo "  -d: Specific database to check, or 'all' to check all databases (Optional, default: postgres)"
    echo "  -o: Output report file path (Optional, default: [date]_[time]_[hostname]_hc-docker.md)"
    echo "  -e: Force using 'docker exec' to execute psql queries inside container"
    echo ""
    echo "Environment Variables Supported:"
    echo "  DOCKER_CONTAINER, PGHOST, PGPORT, PGUSR/PGUSER, PGPASSWORD, DBNAME, OUTPUT_FILE"
    exit 1
}

# Parse command line options
while getopts "c:H:P:u:w:d:o:eh" opt; do
    case ${opt} in
        c ) CONTAINER_NAME=$OPTARG ;;
        H ) PGHOST=$OPTARG ;;
        P ) PGPORT=$OPTARG ;;
        u ) DBUSER=$OPTARG ;;
        w ) DBPASSWORD=$OPTARG ;;
        d ) DBNAME=$OPTARG ;;
        o ) OUTPUT_FILE=$OPTARG ;;
        e ) FORCE_EXEC=1 ;;
        h ) usage ;;
        * ) usage ;;
    esac
done

# Set default output file with date, time, and hostname if not provided
if [ -z "$OUTPUT_FILE" ]; then
    DATE_STR=$(date +%Y%m%d)
    TIME_STR=$(date +%H%M%S)
    HOST_STR=$(hostname -s)
    PREFIX="${DATE_STR}_${TIME_STR}_${HOST_STR}"
    OUTPUT_FILE="${PREFIX}_hc-docker.md"
fi

# Find script directory and SQL files
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQLDIR="${SCRIPT_DIR}/sql"

if [ ! -d "$SQLDIR" ]; then
    echo -e "${RED}Error: SQL directory not found at '${SQLDIR}'. Please ensure sql/ files are available.${NC}"
    exit 1
fi

# Determine Execution Mode (Docker Exec vs TCP Connection)
USE_DOCKER_EXEC=0

if [ -n "$CONTAINER_NAME" ]; then
    if command -v docker &> /dev/null; then
        if docker ps --format '{{.Names}}' 2>/dev/null | grep -q -w "$CONTAINER_NAME" || docker ps --format '{{.ID}}' 2>/dev/null | grep -q "^$CONTAINER_NAME"; then
            CONTAINER_EXISTS=1
            if [ $FORCE_EXEC -eq 1 ]; then
                USE_DOCKER_EXEC=1
            fi
        else
            echo -e "${YELLOW}Warning: Container '${CONTAINER_NAME}' is not currently running locally on this host.${NC}"
            CONTAINER_EXISTS=0
        fi
    else
        echo -e "${YELLOW}Warning: 'docker' CLI not found on host. Container-level metrics will be skipped.${NC}"
        CONTAINER_EXISTS=0
    fi
fi

# Helper function to execute psql queries
exec_psql_cmd() {
    local target_db=$1
    local query=$2

    if [ $USE_DOCKER_EXEC -eq 1 ]; then
        docker exec -i "$CONTAINER_NAME" psql -U "$DBUSER" -d "$target_db" -At -c "$query" 2>/dev/null
    else
        PGPASSWORD="$DBPASSWORD" psql -h "$PGHOST" -p "$PGPORT" -U "$DBUSER" -d "$target_db" -At -c "$query" 2>/dev/null
    fi
}

exec_psql_file() {
    local target_db=$1
    local sql_content=$2

    if [ $USE_DOCKER_EXEC -eq 1 ]; then
        echo "$sql_content" | docker exec -i "$CONTAINER_NAME" psql -U "$DBUSER" -d "$target_db" -q -X -f - 2>&1
    else
        echo "$sql_content" | PGPASSWORD="$DBPASSWORD" psql -h "$PGHOST" -p "$PGPORT" -U "$DBUSER" -d "$target_db" -q -X -f - 2>&1
    fi
}

# Test Connection
echo -ne "Testing PostgreSQL connection... "
PG_VERSION_NUM=$(exec_psql_cmd "postgres" "SHOW server_version_num;")
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ] || [ -z "$PG_VERSION_NUM" ]; then
    # Try falling back to docker exec if TCP failed and container is running
    if [ $USE_DOCKER_EXEC -eq 0 ] && [ -n "$CONTAINER_NAME" ] && [ "${CONTAINER_EXISTS:-0}" -eq 1 ]; then
        echo -e "[ ${YELLOW}TCP FAILED - Trying Docker Exec...${NC} ]"
        USE_DOCKER_EXEC=1
        PG_VERSION_NUM=$(exec_psql_cmd "postgres" "SHOW server_version_num;")
        EXIT_CODE=$?
    fi
fi

if [ $EXIT_CODE -ne 0 ] || [ -z "$PG_VERSION_NUM" ]; then
    echo -e "[ ${RED}FAILED${NC} ]"
    echo -e "${RED}Error: Cannot connect to PostgreSQL database (Host: ${PGHOST}:${PGPORT}, User: ${DBUSER}, Container: ${CONTAINER_NAME:-N/A}).${NC}"
    echo -e "${RED}Please verify credentials, port mappings, or container status.${NC}"
    exit 1
fi

PG_VERSION_FULL=$(exec_psql_cmd "postgres" "SELECT version();")
echo -e "[ ${GREEN}SUCCESS${NC} ]"

echo -e "${BLUE}======================================================================${NC}"
echo -e "${BLUE}   PostgreSQL Docker Container Health Check (Markdown Output)${NC}"
echo -e "${BLUE}======================================================================${NC}"
echo -e "Container Name: ${YELLOW}${CONTAINER_NAME:-None (TCP Only)}${NC}"
echo -e "Target Host:    ${YELLOW}${PGHOST}:${PGPORT}${NC}"
echo -e "DB User:        ${YELLOW}${DBUSER}${NC}"
echo -e "Target DBs:     ${YELLOW}${DBNAME}${NC}"
echo -e "Execution Mode: ${YELLOW}$([ $USE_DOCKER_EXEC -eq 1 ] && echo "Docker Exec" || echo "TCP/IP Network")${NC}"
echo -e "PG Version:     ${GREEN}${PG_VERSION_FULL}${NC}"
echo -e "Output File:    ${YELLOW}${OUTPUT_FILE}${NC}"
echo -e "${BLUE}======================================================================${NC}"

# Check pg_stat_statements
PG_STAT_STATEMENT=0
has_stat_statements=$(exec_psql_cmd "postgres" "select 1 where exists (select extname from pg_extension where extname='pg_stat_statements');")
if [ "$has_stat_statements" = "1" ]; then
    PG_STAT_STATEMENT=1
    echo -e "Extension:      ${GREEN}pg_stat_statements is enabled${NC}"
else
    echo -e "Extension:      ${YELLOW}pg_stat_statements is NOT enabled. Performance queries will be skipped.${NC}"
fi

# Initialize Output File
rm -f "$OUTPUT_FILE"
touch "$OUTPUT_FILE"

# Header Markdown
{
    echo "# PostgreSQL Docker Container Health Check Report"
    echo ""
    echo "* **Generated on:** $(date)"
    echo "* **Hostname:** \`$(hostname)\`"
    echo "* **Docker Container:** \`${CONTAINER_NAME:-N/A}\`"
    echo "* **PGHOST:** \`${PGHOST}\`"
    echo "* **PGPORT:** \`${PGPORT}\`"
    echo "* **PGUSR:** \`${DBUSER}\`"
    echo "* **Target DBNAME:** \`${DBNAME}\`"
    echo "* **Execution Mode:** \`$([ $USE_DOCKER_EXEC -eq 1 ] && echo "Docker Exec" || echo "TCP/IP Network")\`"
    echo "* **PG Version:** \`${PG_VERSION_FULL}\`"
    echo ""
    echo "---"
    echo ""
} >> "$OUTPUT_FILE"

run_sql_script() {
    local sql_file=$1
    local target_db=$2
    local label=$3
    
    echo -e "Running [${YELLOW}${label}${NC}] on database [${GREEN}${target_db}${NC}]..."
    {
        echo "### ${label}"
        echo "* **Target Database:** \`${target_db}\`"
        echo "* **SQL Script:** \`${sql_file}\`"
        echo ""
        echo "\`\`\`text"
    } >> "$OUTPUT_FILE"
    
    # Handle version-specific SQL adjustments for PG 17+ (checkpoint columns moved to pg_stat_checkpointer)
    if [ "$sql_file" = "bgwr-ckpt-report.sql" ] && [ "$PG_VERSION_NUM" -ge 170000 ]; then
        exec_psql_file "$target_db" '
SELECT 
        now()-pg_postmaster_start_time()    "Uptime", now()-stats_reset     "Since stats reset",
        round(100.0*checkpoints_req/total_checkpoints,1)                    "Forced checkpoint ratio (%)",
        round(np.min_since_reset/total_checkpoints,2)                       "Minutes between checkpoints",
        round(checkpoint_write_time::numeric/(total_checkpoints*1000),2)    "Average write time per checkpoint (s)",
        round(checkpoint_sync_time::numeric/(total_checkpoints*1000),2)     "Average sync time per checkpoint (s)",
        round(total_buffers/np.mp,1)                                        "Total MB written",
        round(buffers_checkpoint/(np.mp*total_checkpoints),2)               "MB per checkpoint",
        round(buffers_checkpoint/(np.mp*np.min_since_reset*60),2)           "Checkpoint MBps",
        round(buffers_clean/(np.mp*np.min_since_reset*60),2)                "Bgwriter MBps",
        round(buffers_backend/(np.mp*np.min_since_reset*60),2)              "Backend MBps",
        round(total_buffers/(np.mp*np.min_since_reset*60),2)                "Total MBps",
        round(1.0*buffers_alloc/total_buffers,3)                            "New buffer allocation ratio",        
        round(100.0*buffers_checkpoint/total_buffers,1)                     "Clean by checkpoints (%)",
        round(100.0*buffers_clean/total_buffers,1)                          "Clean by bgwriter (%)",
        round(100.0*buffers_backend/total_buffers,1)                        "Clean by backends (%)",
        round(100.0*maxwritten_clean/(np.min_since_reset*60000/np.bgwr_delay),2)            "Bgwriter halt-only length (buffers)",
        coalesce(round(100.0*maxwritten_clean/(nullif(buffers_clean,0)/np.bgwr_maxp),2),0)  "Bgwriter halt ratio (%)",
        --------------------------------------         --------------------------------------,
        bgstats.*
  FROM (
    SELECT bg.buffers_clean, bg.maxwritten_clean, bg.buffers_alloc, bg.stats_reset,
        cp.num_timed checkpoints_timed, cp.num_requested checkpoints_req, cp.write_time checkpoint_write_time, cp.sync_time checkpoint_sync_time, cp.buffers_written buffers_checkpoint,
        coalesce((SELECT sum(writes) FROM pg_stat_io WHERE backend_type = client backend AND object = relation), 0) buffers_backend,
        cp.num_timed + cp.num_requested total_checkpoints,
        cp.buffers_written + bg.buffers_clean + coalesce((SELECT sum(writes) FROM pg_stat_io WHERE backend_type = client backend AND object = relation), 0) total_buffers,
        pg_postmaster_start_time() startup,
        current_setting(checkpoint_timeout) checkpoint_timeout,
        current_setting(max_wal_size) max_wal_size,
        current_setting(checkpoint_completion_target) checkpoint_completion_target,
        current_setting(bgwriter_delay) bgwriter_delay,
        current_setting(bgwriter_lru_maxpages) bgwriter_lru_maxpages,
        current_setting(bgwriter_lru_multiplier) bgwriter_lru_multiplier
    FROM pg_stat_bgwriter bg, pg_stat_checkpointer cp
        ) bgstats,
        (
    SELECT
        round(extract(epoch from now() - stats_reset)/60)::numeric min_since_reset,
        (1024 * 1024 / block.setting::numeric) mp,
        delay.setting::numeric bgwr_delay,
        lru.setting::numeric bgwr_maxp
    FROM pg_stat_bgwriter bg
    JOIN pg_settings lru   ON lru.name = bgwriter_lru_maxpages
    JOIN pg_settings delay ON delay.name = bgwriter_delay
    JOIN pg_settings block ON block.name = block_size
        ) np;' >> "$OUTPUT_FILE"
    elif [ "$sql_file" = "pg_chkpt_bg_be_pct.sql" ] && [ "$PG_VERSION_NUM" -ge 170000 ]; then
        exec_psql_file "$target_db" '
SELECT
   round(cp.buffers_written/nullif(bg.buffers_clean, 0),2) AS checkpoint_spike,
   ROUND(100.0*cp.buffers_written/nullif(cp.buffers_written + bg.buffers_clean + coalesce((SELECT sum(writes) FROM pg_stat_io WHERE backend_type = client backend AND object = relation), 0), 0),2) AS checkpoint_pct,
   ROUND(100.0*bg.buffers_clean/nullif(cp.buffers_written + bg.buffers_clean + coalesce((SELECT sum(writes) FROM pg_stat_io WHERE backend_type = client backend AND object = relation), 0), 0),2) AS bgwriter_pct,
   ROUND(100.0*coalesce((SELECT sum(writes) FROM pg_stat_io WHERE backend_type = client backend AND object = relation), 0)/nullif(cp.buffers_written + bg.buffers_clean + coalesce((SELECT sum(writes) FROM pg_stat_io WHERE backend_type = client backend AND object = relation), 0), 0),2) AS backend_pct
FROM
   pg_stat_bgwriter bg, pg_stat_checkpointer cp
;' >> "$OUTPUT_FILE"
    else
        if [ -f "${SQLDIR}/${sql_file}" ]; then
            if [ "$PG_VERSION_NUM" -ge 130000 ]; then
                sql_content=$(sed 's/total_time/total_exec_time/g' "${SQLDIR}/${sql_file}")
            else
                sql_content=$(sed 's/total_exec_time/total_time/g' "${SQLDIR}/${sql_file}")
            fi
            exec_psql_file "$target_db" "$sql_content" >> "$OUTPUT_FILE"
        else
            echo "Warning: SQL file ${sql_file} not found in ${SQLDIR}" >> "$OUTPUT_FILE"
        fi
    fi
    
    {
        echo "\`\`\`"
        echo ""
    } >> "$OUTPUT_FILE"
}

# --- 1. DOCKER CONTAINER METRICS & HEALTH ---
if [ -n "$CONTAINER_NAME" ] && command -v docker &> /dev/null && [ "${CONTAINER_EXISTS:-0}" -eq 1 ]; then
    echo -e "\n${BLUE}--- 1. Gathering Docker Container Metrics ---${NC}"
    {
        echo "## 1. Docker Container Health & Metrics"
        echo ""
        echo "### Container Inspection Summary"
        echo "\`\`\`json"
        docker inspect "$CONTAINER_NAME" | grep -E '"(Id|Created|Path|State|Status|Running|RestartCount|Image|HostConfig|Mounts|NetworkSettings)"' | head -n 40
        echo "\`\`\`"
        echo ""
        echo "### Container Resource Utilization (\`docker stats\`)"
        echo "\`\`\`text"
        docker stats "$CONTAINER_NAME" --no-stream
        echo "\`\`\`"
        echo ""
        echo "### Recent Container Logs (Last 30 lines)"
        echo "\`\`\`text"
        docker logs "$CONTAINER_NAME" --tail 30 2>&1
        echo "\`\`\`"
        echo ""
        echo "---"
        echo ""
    } >> "$OUTPUT_FILE"
fi


# --- 2. INSTANCE LEVEL DATABASE METRICS ---
echo -e "\n${BLUE}--- 2. Auditing Instance-Level PostgreSQL Settings ---${NC}"
{
    echo "## 2. Instance-Level PostgreSQL Settings"
    echo ""
} >> "$OUTPUT_FILE"

run_sql_script "pg_settings.sql" "postgres" "Config settings from files"
run_sql_script "pg_settings_file.sql" "postgres" "Global configurations detailed"
run_sql_script "pg_settings_hba.sql" "postgres" "HBA rules configurations"
run_sql_script "pg_settings_db.sql" "postgres" "Database-specific parameters"
run_sql_script "pg_settings_db_role.sql" "postgres" "Database & Role specific parameters"
run_sql_script "db_size.sql" "postgres" "Database sizes on disk"
run_sql_script "role_grant.sql" "postgres" "User Roles and Privileges inherited"
run_sql_script "dbconn_size.sql" "postgres" "Connections load auditing"
run_sql_script "vacuum_settings.sql" "postgres" "Vacuum & Autovacuum Configurations"
run_sql_script "database_xid_age.sql" "postgres" "Transaction ID age wraparound check"
run_sql_script "rollback_hit_ratio.sql" "postgres" "Rollback and buffer hit ratio"
run_sql_script "bgwriter_chkpt.sql" "postgres" "Background writer status"
run_sql_script "pg_chkpt_bg_be_pct.sql" "postgres" "Checkpoint write distribution percentage"
run_sql_script "bgwr-ckpt-report.sql" "postgres" "Background writer and checkpoint report"

{
    echo "---"
    echo ""
} >> "$OUTPUT_FILE"


# --- 3. REPLICATION METRICS ---
echo -e "\n${BLUE}--- 3. Auditing Replication Status ---${NC}"
{
    echo "## 3. Replication Status"
    echo ""
} >> "$OUTPUT_FILE"

run_sql_script "sr_sync_param.sql" "postgres" "Replication settings audit"
run_sql_script "sr_stat.sql" "postgres" "Streaming replication status (Master side)"
run_sql_script "pg_stat_wal_receiver.sql" "postgres" "Streaming replication status (Replica side)"
run_sql_script "pg_replication_slots.sql" "postgres" "Replication slots details"
run_sql_script "db_conflict_slave.sql" "postgres" "Standby recovery conflicts"

{
    echo "---"
    echo ""
} >> "$OUTPUT_FILE"


# --- 4. PERFORMANCE & RUNNING QUERIES ---
echo -e "\n${BLUE}--- 4. Auditing Query Performance & Active Sessions ---${NC}"
{
    echo "## 4. Performance & Active Sessions"
    echo ""
} >> "$OUTPUT_FILE"

run_sql_script "slow_dml.sql" "postgres" "DML queries running > 15s"
run_sql_script "slow_qry.sql" "postgres" "SELECT queries running > 15s"
run_sql_script "slow_active_queries.sql" "postgres" "Active queries running > 2 min"
run_sql_script "lock_blocker.sql" "postgres" "Locks and Blockers details"

if [ "$PG_VERSION_NUM" -lt 100000 ]; then
    run_sql_script "longrun_9.sql" "postgres" "Open transactions in PG 9.x > 15s"
else
    run_sql_script "longrun_10.sql" "postgres" "Open transactions in PG 10+ > 15s"
fi

if [ "$PG_STAT_STATEMENT" -eq 1 ]; then
    run_sql_script "top20qry_cputime.sql" "postgres" "Top 20 queries by CPU workload"
    run_sql_script "top20qry_elapsedtime.sql" "postgres" "Top 20 queries by single execution time"
    run_sql_script "top20qry_numcalls.sql" "postgres" "Top 20 queries by count of invocations"
fi

{
    echo "---"
    echo ""
} >> "$OUTPUT_FILE"


# --- 5. MULTI-DATABASE OBJECT CHECKS ---
echo -e "\n${BLUE}--- 5. Auditing Schema and Maintenance (Per-Database) ---${NC}"
{
    echo "## 5. Schema and Table Maintenance"
    echo ""
} >> "$OUTPUT_FILE"

# Fetch database list to check
if [ "$DBNAME" = "all" ]; then
    DB_RAW_LIST=$(exec_psql_cmd "postgres" "select datname from pg_database where datname not in ('template0','template1') and datallowconn = true order by 1;")
    DB_LIST=($DB_RAW_LIST)
else
    DB_LIST=("$DBNAME")
fi

declare -a PER_DB_SCRIPTS=(
    "last_autovacuum_and_autoanalyze.sql"
    "postrgesql_autovacuum_queue_detailed.sql"
    "pg_settings_table.sql"
    "table_grant.sql"
    "tbl8gb.sql"
    "tbl_5idx.sql"
    "idx_unused.sql"
    "junkdata.sql"
    "check_seq.sql"
    "check_tbl_part.sql"
    "table_bloat_check.sql"
    "index_bloat_check.sql"
    "no_stats_table_check.sql"
    "unused_indexes.sql"
    "needed_indexes.sql"
    "fk_no_index.sql"
    "duplicate_indexes_fuzzy.sql"
    "tbl_hit_ratio.sql"
    "idx_hit_ratio.sql"
    "check_fillfactor.sql"
)

for db in "${DB_LIST[@]}"; do
    echo -e "Auditing database: ${GREEN}${db}${NC}"
    {
        echo "### Database: \`${db}\`"
        echo ""
    } >> "$OUTPUT_FILE"
    
    for script in "${PER_DB_SCRIPTS[@]}"; do
        if [ -f "${SQLDIR}/${script}" ]; then
            run_sql_script "$script" "$db" "Per-DB Audit: ${script}"
        fi
    done
    
    # Check for publications & subscriptions (logical replication)
    run_sql_script "pg_publication.sql" "$db" "Logical Replication Publication"
    run_sql_script "pg_publication_tables.sql" "$db" "Logical Replication Tables"
    run_sql_script "pg_subscription.sql" "$db" "Logical Replication Subscription"
    run_sql_script "pg_stat_subscription.sql" "$db" "Logical Replication Subscription Workers"
    
    HAS_PGLOGICAL=$(exec_psql_cmd "$db" "SELECT count(*) FROM pg_extension WHERE extname = 'pglogical';" | tr -d '[:space:]')
    if [ "$HAS_PGLOGICAL" = "1" ]; then
        run_sql_script "pglogical_replication_check.sql" "$db" "Third-party PGLogical replication"
    fi
done

echo -e "\n${GREEN}======================================================================${NC}"
echo -e "Docker Health Check Report successfully generated at: ${YELLOW}${OUTPUT_FILE}${NC}"
echo -e "${GREEN}======================================================================${NC}"
