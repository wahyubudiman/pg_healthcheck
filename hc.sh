#!/bin/bash

# Original: pg_healthcheck.sh; Version: 1.2
# https://github.com/francs/PostgreSQL-healthcheck-script
# Modified by Ujang Jaenudin (add a lot of command/scripts)

# index:
# grep "^\-\-[0-9]" hc.log
# --1. Hardware and OS Info
# --1.1 Hardware info
# --1.2 Distribution and kernel version
# --1.3 Kernel parameter related to Postgres
# --1.4 Boot Parameter
# --1.5 User Info and resource limit
# --1.6 Filesystem
# --1.6 More Network info
# --1.7 Services
# --1.8 Processes
# --1.9 Scheduled jobs
# --1.10 Installed packages
# --1.11 Readable files in /etc
# --1.12 Development tools available
# --1.13 SUID and GUID files
# --1.14 SUID and GUID writable files
# --1.15 Writable files outside HOME
# --1.16 Performance
# --1.17 Audit
# --1.18 Security Aspect
# --1.19 HA (Pacemaker)
# --2. Database Info and Configuration
# --2.1 Database Version and compilation info
# --2.2 postgresql.conf
# --2.3 pg_hba.conf
# --2.4 recovery.conf and recover.done
# --2.5 standby.signal and recovery.signal
# --3. Analyze postgresql log since 30 days ago until now
# --4. timed tasks
# --5. PostgreSQL Settings
# --5.0 Settings
# --5.0.1 current settings
# --5.0.2 file settings
# --5.0.3 database setting
# --5.0.4 role + database setting
# --5.1 Tablespace
# --5.2 Database Size
# --5.3 Roles/Users and Privileges
# --5.4 Check extensions installed on database
# --5.5 Check database fdw
# --5.6 Database XID Wraparound Healthcheck
# --6. TOP 10 SQL since the last inspection
# --6.1 TOP 20 Query, CPU Time
# --6.2 TOP 20 Query, Number of calls
# --6.3 TOP 20 Query, Single/elapsed time
# --6.4 DML that still running > 15 secs
# --6.5 SELECT that still running > 15 secs
# --7. database running status inspection
# --7.1 Number of connections
# --7.2 Autovacuum and vacuum related
# --7.3 Multi-database checking
# --7.4 Rollback + Hit ratio
# --7.5 Long Transaction (> 15 secs)
# --7.6 bgwriter and checkpoint
# --8. Replication
# --8.1 Replication settings
# --8.2 Replication status
# --8.3 Multi-database Replication Check
# --8.4 Multi-database pglogical Check
# --8.5 Query cancelled due to conflict, some are replication related


### + check db aktifitas brp ins/upd/del, check garbage % dari pg_stat_database
### + check db is in recovery (slave) or production read/write
### 
### https://postgrespro.com/list/thread-id/1490550
### 
### + di paling atas, tested on rhel7/rhel8 dan postgres >= 10
### 
### cek db aktifitas ins/upd/del/ddl
### cek grant dan grantee dgn admin option, sudah ada how to improve
### cek top table sibuk yg byk ins/upd/del
### cek top function hit
### 
### cek vacuum dan autovacuum config
### cek vacuum dan autovacuum statistik/best practice

### linux dmesg -t
### grab all .conf files from /etc and any other dirs
### grep error pada /var/log/messaged*
### grep error pada corosync.log jika terdeteksi pakai pacemaker
### + pg_stat_progress_vacuum.sql
### + view_tree.sql , tables_index_usage_rates.sql , slow_active_queries.sql ???
### + pg_stat_progress_% ???  pg_stat_progress_analyze and pg_stat_progress_cluster
### In other words, you should have some basic monitoring in place, collecting metrics from the database. For cleanup, you need to be looking at least at these values:
### 
### autovacuum info
### * 'pg_stat_all_tables.n_dead_tup' – number of dead tuples in each table (both user tables and system catalogs)
### * '(n_dead_tup / n_live_tup)' – ratio of dead/live tuples in each table
### * '(pg_class.relpages / pg_class.reltuples)' – space "per row"
###
### https://github.com/HariSekhon/SQL-scripts/blob/master/postgres_info.sql
### https://gist.github.com/jdxcode/4697366
### https://github.com/dataegret/pg-utils
### https://github.com/nilenso/postgresql-monitoring
### https://gist.github.com/ruckus/5718112
### https://github.com/NikolayS/postgres_dba
### https://gist.github.com/anvk/475c22cbca1edc5ce94546c871460fdd
### https://gist.github.com/zafergurel/7e203b80b18b0791a45ce9d80e1a8b89
### https://gist.github.com/NikolayS/b6ec676ea63ab8d4db680a4c0d88e8bf
### https://gist.github.com/mencargo/79447185034ebabcb49087008fbdc266
### https://github.com/HariSekhon/SQL-scripts
### https://gist.github.com/rgreenjr/3637525
### 
### Adaptive query optimization for PostgreSQL:
### https://github.com/postgrespro/aqo
### 
### 
### https://github.com/dhamaniasad/awesome-postgres

### The classic approach based on pg_stat_statements is good when we aim to keep SQL workload under control, to scale better. Usually, we considered total_time as the main metric if we aim to reduce the load on Postgres nodes, and took Top-N queries, analyzing them starting from position 1. If position 1 query was responsible for more than 40% of overall total_time it was considered as a very bad situation that requires attention sooner.
### https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/12197

 
# Load env
#. ~/.profile

# ask function
ASK_RET=0
askyn() {
   ASK_RET=0
   MSG1=""
   MSG2=""
   MSG3=""
   MSG4=""
   MSG5=""

   MSG1=$1
   MSG2=$2
   MSG3=$3
   MSG4=$4
   MSG5=$5
   
   if [ ! -z "$MSG1" ]; then echo "$MSG1"; fi
   if [ ! -z "$MSG2" ]; then echo "$MSG2"; fi
   if [ ! -z "$MSG3" ]; then echo "$MSG3"; fi
   if [ ! -z "$MSG4" ]; then echo "$MSG4"; fi
   if [ ! -z "$MSG5" ]; then echo "$MSG5"; fi
   T=0
   while [ $T -eq 0 ]
   do
      YESNO_DEFAULT=N
      YESNO=N
      read -p "Would you like to continue? Y|N [$YESNO_DEFAULT]: " YESNO
      YESNO="${YESNO:-$YESNO_DEFAULT}"
      YESNO_LOWER=`echo ${YESNO} | tr '[:lower:]' '[:upper:]'`
      CK1=`echo "ynYN" | grep $YESNO_LOWER | wc -l`
      if [ $CK1 -eq 1 ]; then
         if [ ${YESNO_LOWER} == "N" ]; then
            echo "your answer is ${YESNO_LOWER}, exit now"
            T=1
            ASK_RET=1
         else
            T=1
            ASK_RET=0
         fi
      else
         echo "You must press Y or y or N or n"
      fi
   done
}

clear
echo "Please run this script by root"
echo "Please remove hc.log and hc.pid before run this script"
echo " "
echo "The result will depend on OS packages: "
echo "lsscsi lshw sysfsutils sg3_utils numactl dmidecode ethtool hwinfo sysstat "
echo "lsof net-tools psmisc setools-console policycoreutils-python-utils"
echo " "
echo "Checking required packages..."
if command -v dpkg >/dev/null 2>&1; then
   for pkg in lsscsi lshw sysfsutils sg3_utils numactl dmidecode ethtool hwinfo sysstat lsof net-tools psmisc setools-console policycoreutils-python-utils; do
      dpkg -s "$pkg" 2>/dev/null | grep -q "Status: install ok" && echo "  $pkg: installed" || echo "  $pkg: NOT installed"
   done
elif command -v rpm >/dev/null 2>&1; then
   rpm -q lsscsi lshw sysfsutils sg3_utils numactl dmidecode ethtool hwinfo 2>/dev/null | grep -v "not installed"
   rpm -q sysstat lsof net-tools psmisc setools-console policycoreutils-python-utils 2>/dev/null | grep -v "not installed"
else
   echo "No package manager (dpkg or rpm) found to verify requirements."
fi
echo " "
echo "WARNING: If some packages above are NOT installed or you are not running as root,"
echo "some OS/hardware audit details may be empty, but the script will continue."
echo " "


if [ -z "${CURRUSR}" ]; then
   CURRUSR=postgres
   VARTMP="null"
   read -p "Please define Linux/Unix postgres cluster user/owner (default user is ${CURRUSR}): " VARTMP
   if [ -z ${VARTMP} ] || [ "${VARTMP}" = "null" ]; then
      echo "You did not define Linux/Unix postgres cluster user/owner, assume ${CURRUSR}"
   else
      CURRUSR=${VARTMP}
   fi
fi

#CURRUSR=`who asm i|awk '{print $1}'`
PTEMP=`ps -fu ${CURRUSR} 2>/dev/null | grep "\-D " | grep -v grep | awk -F\-D '{print $1}' | awk '{print $NF}' | awk -F'/' '{NF--}1' | sed 's/ /\//g'`
PTEMP2=`echo ${PTEMP} | tr -s ' ' ':'`
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:/usr/lib/udev:/lib/udev:${PTEMP2}:${PATH}

CKDATA=`ps -fu ${CURRUSR} 2>/dev/null | grep "\-D " | grep -v grep | awk -F\-D '{print $2}' | sed 's/ //g' | wc -l`
if [ -z "${IS_REMOTE}" ]; then
   IS_REMOTE="N"
   if [[ ${CKDATA} -eq 1 ]]; then
      export PGDATA=`ps -fu ${CURRUSR} | grep "\-D " | grep -v grep | awk -F\-D '{print $2}' | sed 's/ //g'`
   elif [[ ${CKDATA} -gt 1 ]]; then
      echo "We detect more than 1 postgres cluster in this host"
      echo "${CKDATA}"
      PGDATATMP="null"
      read -p "Please define PGDATA path you want to check: " PGDATATMP
      if [ -z ${PGDATATMP} ]; then
         echo "You did not define PGDATA path, exit now"
         exit 1
      else
         export PGDATA=${PGDATATMP}
      fi
   else
      echo "Unable to detect local postgres cluster running in this host"
      read -p "Is this a Docker or Remote PostgreSQL database? Y|N [N]: " IS_REMOTE_INPUT
      IS_REMOTE_INPUT="${IS_REMOTE_INPUT:-N}"
      IS_REMOTE_UPPER=`echo ${IS_REMOTE_INPUT} | tr '[:lower:]' '[:upper:]'`
      if [ "${IS_REMOTE_UPPER}" = "Y" ]; then
         IS_REMOTE="Y"
         export PGDATA="/tmp/dummy_pgdata"
      else
         echo "Exit now"
         exit 1
      fi
   fi
else
   if [ "${IS_REMOTE}" = "Y" ]; then
      export PGDATA="/tmp/dummy_pgdata"
   else
      if [[ ${CKDATA} -eq 1 ]]; then
         export PGDATA=`ps -fu ${CURRUSR} | grep "\-D " | grep -v grep | awk -F\-D '{print $2}' | sed 's/ //g'`
      elif [[ ${CKDATA} -gt 1 ]]; then
         if [ -z "${PGDATA}" ]; then
            echo "Multiple local clusters detected. Please set PGDATA environment variable."
            exit 1
         fi
      else
         echo "IS_REMOTE is set to N, but no local postgres cluster detected. Exit now"
         exit 1
      fi
   fi
fi

CURDIR=$(cd $(dirname "$0"); pwd)

# Determine if the health check script is already running.
if [ -f hc.pid ]; then
  echo "The program $0 is running now !"
  echo "File hc.pid exists"
  exit 0
fi

# Determine if pg is alive
if [ "${IS_REMOTE}" = "N" ]; then
  if [ ! -f ${PGDATA}/postmaster.pid ]; then
    echo "PostgreSQL is down"
    echo "File ${PGDATA}/postmaster.pid does not exists"
    exit 0
  fi
fi

if [ -z "${PGHOST}" ]; then
   PGHOST=127.0.0.1
   VARTMP="null"
   read -p "Please define host to connect (default host is ${PGHOST}): " VARTMP
   if [ -z ${VARTMP} ] || [ "${VARTMP}" = "null" ]; then
      echo "You did not define host to connect, assume ${PGHOST}"
   else
      PGHOST=${VARTMP}
   fi
fi

if [ -z "${PGPORT}" ]; then
   PGPORT=5432
   VARTMP="null"
   read -p "Please define port to connect (default port is ${PGPORT}): " VARTMP
   if [ -z ${VARTMP} ] || [ "${VARTMP}" = "null" ]; then
      echo "You did not define port to connect, assume ${PGPORT}"
   else
      PGPORT=${VARTMP}
   fi
fi

if [ -z "${PGUSR}" ]; then
   PGUSR=postgres
   VARTMP="null"
   read -p "Please define superuser in ${PGDATA} cluster (default user is ${PGUSR}): " VARTMP
   if [ -z ${VARTMP} ] || [ "${VARTMP}" = "null" ]; then
      echo "You did not define superuser in ${PGDATA} cluster, assume ${PGUSR}"
   else
      PGUSR=${VARTMP}
   fi
fi

if [ -z "${PGPASSWORD}" ]; then
   VARTMP="null"
   read -s -p "Please define password for ${PGUSR} user: " VARTMP
   if [ -z ${VARTMP} ] || [ "${VARTMP}" = "null" ]; then
      echo "You did not define password for ${PGUSR} user, exit now"
      exit 1
   else
      export PGPASSWORD=${VARTMP}
   fi
   echo " "
fi

if [ -z "${DBNAME}" ]; then
   DBNAME=postgres
   VARTMP="null"
   read -p "Please define database to connect (default database is ${DBNAME}): " VARTMP
   if [ -z ${VARTMP} ] || [ "${VARTMP}" = "null" ]; then
      echo "You did not define database to connect, assume ${DBNAME}"
   else
      DBNAME=${VARTMP}
   fi
fi

PGCONN="psql -h ${PGHOST} -p ${PGPORT} -U ${PGUSR} -d ${DBNAME} "
SQLDIR=${CURDIR}/sql
DATE_STR=$(date +%Y%m%d)
TIME_STR=$(date +%H%M%S)
HOST_STR=$(hostname -s)
PREFIX="${DATE_STR}_${TIME_STR}_${HOST_STR}"
RPTFILE=${CURDIR}/${PREFIX}_hc.log
SQLDB="select datname from pg_database where datname not in ('template0','template1') order by 1;"

echo "Checking connection to postgres..."
${PGCONN} -At -c "select version();"
EXIT_CODE=$?;

if [ ${EXIT_CODE} -ne 0 ]; then 
   echo "Error Check connection to postgres, exit now"
   exit 1
fi

db_version=`${PGCONN} -At -c "select version();" | awk '{print $1,$2}'`
db_version_tmp=`echo ${db_version} | awk '{print $2}' | awk -F "." '{print $1}'`
db_version_tmp2=`echo ${db_version} | awk '{print $2}' | awk -F "." '{print $2}'`
db_version_major=$((db_version_tmp*1))
db_version_minor=$((db_version_tmp2*1))
db_big_version="${db_version_major}.${db_version_minor}"

#Create a report file
if [ -f ${RPTFILE} ]; then
   rm -f ${RPTFILE}
fi

touch ${RPTFILE}
echo "Healthcheck on $(date)" > ${RPTFILE}
echo "On $(hostname -a)" >> ${RPTFILE}
echo "IP Address $(hostname -i)" >> ${RPTFILE}
echo "PGHOST: ${PGHOST}" >> ${RPTFILE}
echo "PGPORT: ${PGPORT}" >> ${RPTFILE}
echo "PGUSR:  ${PGUSR}" >> ${RPTFILE}
echo "DBNAME: ${DBNAME}" >> ${RPTFILE}
echo " " >> ${RPTFILE}
echo " " >> ${RPTFILE}

if [  ${db_version_major} -lt 9 ]; then
   echo -e "WARNING: Only postgresql 9 or above are supported at this time"
   exit 1
fi

PG_STAT_STATEMENT=0
# Check if pg_stat_statements extension is installed
if [ ${db_version_major} -eq 9 ] && [ ${db_version_minor} -eq 0 ]; then
  pg_stat_statements=`${PGCONN} -At -c "select 1 where exists (select viewname from pg_views where viewname='pg_stat_statements');"`
  echo "pg_stat_statements: ${pg_stat_statements}"
  if [ -z ${pg_stat_statements} ]; then
     echo "for better output please install pg_stat_statements..."
     PG_STAT_STATEMENT=0
     #exit 1
   else
     PG_STAT_STATEMENT=1
   fi
else
  pg_stat_statements=`${PGCONN} -At -c "select 1 where exists (select extname from pg_extension where extname='pg_stat_statements');"`
   if [ -z ${pg_stat_statements} ]; then
      echo "for better output please install pg_stat_statements..."
      PG_STAT_STATEMENT=0
      #exit 1
   else
      PG_STAT_STATEMENT=1
   fi
fi

#Create script run tag file
touch hc.pid
TEEFILE=" tee -a ${RPTFILE}"

echo -e "###############################    PostgreSQL healthcheck    #####################################" | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "--1. Hardware and OS Info" | ${TEEFILE} > /dev/null
echo -e "--1.1 Hardware info" | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "dmidecode output: " | ${TEEFILE} > /dev/null
dmidecode 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "lshw output: " | ${TEEFILE} > /dev/null
lshw 2> /dev/null | ${TEEFILE} > /dev/null 
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "lspci output: " | ${TEEFILE} > /dev/null
lspci -v 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "CPU info:" | ${TEEFILE} > /dev/null
lscpu 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "Memory Info:" | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "dmidecode and lshw type memory output: " | ${TEEFILE} > /dev/null
dmidecode --type memory 2> /dev/null | ${TEEFILE} > /dev/null
lshw -c memory 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "dmidecode type memory speed output: " | ${TEEFILE} > /dev/null
dmidecode -t memory | grep -i speed 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "/proc/meminfo contents:" | ${TEEFILE} > /dev/null
cat /proc/meminfo 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "Memory+swap usages in MB:" | ${TEEFILE} > /dev/null
free -m 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "Disk Info:" | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "host hba info detail by systool, fabric_name --> san switch " | ${TEEFILE} > /dev/null
ls /sys/class/fc_host/* 2> /dev/null | ${TEEFILE} > /dev/null
systool -c fc_host -v 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "host hba node name (wwnn), port name (wwpn), fabric_name --> san switch" | ${TEEFILE} > /dev/null
ls -1c /sys/class/fc_host/host*/*_name 2> /dev/null | xargs -I {} grep -H -v "ZzZz" {} | sort 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "host hba port id, fabric_name --> san switch" | ${TEEFILE} > /dev/null
ls -1c /sys/class/fc_host/host*/port_id 2> /dev/null | xargs -I {} grep -H -v "ZzZz" {} | sort 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "Storage wwnn and wwpn (if fabric: port identifier) by systool" | ${TEEFILE} > /dev/null
systool -c fc_transport -v 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "Storage wwnn and wwpn (if fabric: port identifier)" | ${TEEFILE} > /dev/null
ls -1c /sys/bus/scsi/devices/target*/fc_transport/target*/*_name  2> /dev/null | xargs -I {} grep -H -v "ZzZz" {} | sort 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "Storage port id (if fabric: port identifier)" | ${TEEFILE} > /dev/null
ls -1c /sys/bus/scsi/devices/target*/fc_transport/target*/port_id 2> /dev/null | xargs -I {} grep -H -v "ZzZz" {} | sort 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "kernel assigned scsi address plus sdN and sgN names" | ${TEEFILE} > /dev/null
sg_map -i -x 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "lsscsi output:" | ${TEEFILE} > /dev/null
lsscsi --scsi_id -g 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "multipath output:" | ${TEEFILE} > /dev/null
multipath -ll 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "lsblk output:" | ${TEEFILE} > /dev/null
lsblk 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "blkid output:" | ${TEEFILE} > /dev/null
blkid 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "/proc/partitions contents:" | ${TEEFILE} > /dev/null
cat /proc/partitions 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "pvs -o pv_all output:" | ${TEEFILE} > /dev/null
pvs -o pv_all 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "vgs -o vg_all output:" | ${TEEFILE} > /dev/null
vgs -o vg_all 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "lvs -o lv_all output:" | ${TEEFILE} > /dev/null
lvs -o lv_all 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "lvs custom output:" | ${TEEFILE} > /dev/null
lvs -o stripes,stripesize,size,vg_name,lv_name,lv_layout,lv_active,lv_read_ahead,metadata_lv,lv_profile 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "Network Info:" | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "lshw and hwinfo (s) output:" | ${TEEFILE} > /dev/null
lshw -c network 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
hwinfo --network --short 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
lspci 2> /dev/null | egrep -i 'network|ethernet|wireless|wi-fi' | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "ip link show net device name " | ${TEEFILE} > /dev/null
ip link show 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "ip link show ethtool " | ${TEEFILE} > /dev/null
ip link show | grep "^[0-9]"| awk -F: '{print $2}' | tr -d ' ' | awk '{print $1}' 2> /dev/null | ${TEEFILE} > /dev/null
ip link show | grep "^[0-9]"| awk -F: '{print $2}' | tr -d ' ' | awk '{print $1}' | xargs -i ethtool {} 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "ip link show ethtool -i" | ${TEEFILE} > /dev/null
ip link show | grep "^[0-9]"| awk -F: '{print $2}' | tr -d ' ' | awk '{print $1}' 2> /dev/null | ${TEEFILE} > /dev/null
ip link show | grep "^[0-9]"| awk -F: '{print $2}' | tr -d ' ' | awk '{print $1}' | xargs -i ethtool -i {} 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null

echo -e "--1.2 Distribution and kernel version" | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "/etc/issue contents:" | ${TEEFILE} > /dev/null
cat /etc/issue 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
for FILESA in `ls /etc/*-release`; do echo "${FILESA} content:"; echo "---------------------------------------"; cat ${FILESA}; echo " "; done | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "/proc/version contents:" | ${TEEFILE} > /dev/null
cat /proc/version 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "uname -a output:" | ${TEEFILE} > /dev/null
uname -a 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "lsb_release -a output:" | ${TEEFILE} > /dev/null
lsb_release -a 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "Kernel Version:" | ${TEEFILE} > /dev/null
uname -r 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null

echo -e "--1.3 Kernel parameter related to Postgres" | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "VM Page size: `getconf PAGE_SIZE`" | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "Shared memory:" | ${TEEFILE} > /dev/null
echo -e "SHMMNI: `sysctl -n kernel.shmmni`" | ${TEEFILE} > /dev/null
echo -e "SHMMAX: `sysctl -n kernel.shmmax`" | ${TEEFILE} > /dev/null
echo -e "SHMALL: `sysctl -n kernel.shmall`" | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "Semaphores:" | ${TEEFILE} > /dev/null
echo -e "SEMMSL: `sysctl -n kernel.sem | awk '{print $1}'`" | ${TEEFILE} > /dev/null
echo -e "SEMMNS: `sysctl -n kernel.sem | awk '{print $2}'`" | ${TEEFILE} > /dev/null
echo -e "SEMOPM: `sysctl -n kernel.sem | awk '{print $3}'`" | ${TEEFILE} > /dev/null
echo -e "SEMMNI: `sysctl -n kernel.sem | awk '{print $4}'`" | ${TEEFILE} > /dev/null
# kernel.sem = SEMMSL SEMMNS       SEMOPM   SEMMNI
#              32000  1024000000      500    32000
# SEMMSL	Maximum number of semaphores per set	at least 17
# SEMMNS	Maximum number of semaphores system-wide	ceil((max_connections + autovacuum_max_workers + max_worker_processes + 5) / 16) * 17 plus room for other applications
# SEMOPM  The maximum number of operations that may be specified in a semop(2) call. (http://man7.org/linux/man-pages/man5/proc.5.html)
# SEMMNI	Maximum number of semaphore identifiers (i.e., sets)	at least ceil((max_connections + autovacuum_max_workers + max_worker_processes + 5) / 16) plus room for other applications
# oracle. kernel.sem = 250 32000 100 128
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "OVERCOMMIT_MEMORY: `sysctl -n vm.overcommit_memory`" | ${TEEFILE} > /dev/null
echo -e "OVERCOMMIT_RATIO: `sysctl -n vm.overcommit_ratio`" | ${TEEFILE} > /dev/null
echo -e "FILE-MAX: `cat /proc/sys/fs/file-max`" | ${TEEFILE} > /dev/null
echo -e "OOM_SCORE_ADJ: `cat /proc/self/oom_score_adj`" | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "All printable sysctl values (current settings)" | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
sysctl -a 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null

echo -e "--1.4 Boot Parameter" | ${TEEFILE} > /dev/null
echo -e "BOOT PARAMS: `cat /proc/cmdline`" | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "/etc/default/grub contents:" | ${TEEFILE} > /dev/null
cat /etc/default/grub 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null

echo -e "--1.5 User Info and resource limit" | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "Current user: `whoami`" | ${TEEFILE} > /dev/null
echo -e "Resource Soft Limit:" | ${TEEFILE} > /dev/null
ulimit -aS | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "Resource Hard Limit:" | ${TEEFILE} > /dev/null
ulimit -aH | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
if [ "${IS_REMOTE}" = "N" ]; then
   echo -e "Postgres owner, ${CURRUSR} user:" | ${TEEFILE} > /dev/null
   echo -e "Resource Soft Limit:" | ${TEEFILE} > /dev/null
   su - ${CURRUSR} -c "ulimit -aS" | ${TEEFILE} > /dev/null
   echo -e " " | ${TEEFILE} > /dev/null
   echo -e " " | ${TEEFILE} > /dev/null
   echo -e "Resource Hard Limit:" | ${TEEFILE} > /dev/null
   su - ${CURRUSR} -c "ulimit -aH" | ${TEEFILE} > /dev/null
   echo -e " " | ${TEEFILE} > /dev/null
   echo -e " " | ${TEEFILE} > /dev/null
fi
echo -e "User ID and GID:" | ${TEEFILE} > /dev/null
echo -e "Current user: `whoami`" | ${TEEFILE} > /dev/null
id -a | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
if [ "${IS_REMOTE}" = "N" ]; then
   echo -e "Postgres owner, ${CURRUSR} user:" | ${TEEFILE} > /dev/null
   id -a ${CURRUSR} | ${TEEFILE} > /dev/null
   echo -e " " | ${TEEFILE} > /dev/null
   echo -e " " | ${TEEFILE} > /dev/null
fi
echo -e "--1.6 Filesystem" | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "mount -l output:" | ${TEEFILE} > /dev/null
mount -l | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "/proc/mounts contents:" | ${TEEFILE} > /dev/null
cat /proc/mounts 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "/etc/fstab contents:" | ${TEEFILE} > /dev/null
cat /etc/fstab 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "df -h output:" | ${TEEFILE} > /dev/null
df -h 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "df -i output:" | ${TEEFILE} > /dev/null
df -i 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo "PostgreSQL filesystem info" | ${TEEFILE} > /dev/null
for I in `ps -fu ${CURRUSR}| grep "\-D " | grep -v grep | awk -F\-D '{print $2}'`
do
   df -h ${I} 2> /dev/null | ${TEEFILE} > /dev/null
   echo -e " " | ${TEEFILE} > /dev/null
   df -i ${I} 2> /dev/null | ${TEEFILE} > /dev/null
done
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null

echo -e "--1.6 More Network info" | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "ifconfig -a output:" | ${TEEFILE} > /dev/null
ifconfig -a 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "ip commands output:" | ${TEEFILE} > /dev/null
ip addr show 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "ip route show output:" | ${TEEFILE} > /dev/null
ip route show 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "netstat -nr output:" | ${TEEFILE} > /dev/null
netstat -nr 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "/etc/hosts contents:" | ${TEEFILE} > /dev/null
cat /etc/hosts 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "/etc/resolv.conf contents:" | ${TEEFILE} > /dev/null
cat /etc/resolv.conf 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "/etc/nsswitch.conf contents:" | ${TEEFILE} > /dev/null
cat /etc/nsswitch.conf 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "arp output:" | ${TEEFILE} > /dev/null
arp 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
arp -a 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
arp -e 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
arp -n 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "service/socket listening on TCP:" | ${TEEFILE} > /dev/null
netstat -ltnp 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "service/socket listening on UDP:" | ${TEEFILE} > /dev/null
netstat -lunp 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "service/socket listening on unix domain SOCKET:" | ${TEEFILE} > /dev/null
netstat -lxnp 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "Displaying established with their PID number:" | ${TEEFILE} > /dev/null
netstat -tpn 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null

echo -e "--1.7 Services" | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
systemctl -a 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
service --status-all 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
chkconfig --list 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
systemctl -t service -a 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null

echo -e "--1.8 Processes" | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "pstree -a output:" | ${TEEFILE} > /dev/null
pstree -a 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "ps aux output:" | ${TEEFILE} > /dev/null
ps aux 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null

echo -e "--1.9 Scheduled jobs" | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "list files in /etc/cron*:" | ${TEEFILE} > /dev/null
find /etc/cron* -ls 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "list files in /var/spool/cron*:" | ${TEEFILE} > /dev/null
find /var/spool/cron* -ls 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "systemctl list-timers --all output:" | ${TEEFILE} > /dev/null
systemctl list-timers --all 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null

echo -e "--1.10 Installed packages" | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
dpkg -l 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
pacman -Qqen 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
rpm -qa 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
yum list installed 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
apt --installed list 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
aptitude search '~i' 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
dnf list installed 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null

echo -e "--1.11 Readable files in /etc" | ${TEEFILE} > /dev/null
find /etc -user `id -u ${CURRUSR}` -perm -u=r -o -group `id -g ${CURRUSR}` -perm -g=r -o -perm -o=r -ls | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null

echo -e "--1.12 Development tools available" | ${TEEFILE} > /dev/null
which gcc g++ python perl clisp nasm ruby gdb make java php clang clang++ 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null

echo -e "--1.13 SUID and GUID files" | ${TEEFILE} > /dev/null
find / -path /sys -prune -o -path /proc -prune -o -path /dev -prune -user `id -u ${CURRUSR}` -type f -perm -u=s -o -type f -perm -g=s -ls | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null

echo -e "--1.14 SUID and GUID writable files" | ${TEEFILE} > /dev/null
find / -path /sys -prune -o -path /proc -prune -o -path /dev -prune -group `id -g ${CURRUSR}` -perm -g=w -o -perm -u=s -o -perm -o=w -perm -u=s -o -perm -o=w -perm -g=s -ls | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null

echo -e "--1.15 Writable files outside HOME" | ${TEEFILE} > /dev/null
TMPIDUPG=`id -u ${CURRUSR}`
TMPHOMEPG=`cat /etc/passwd | grep ${TMPIDUPG} | awk -F: '{print $6}'`
find / -path "$TMPHOMEPG" -o -path /sys -prune -o -path /proc -prune -o -path /dev -prune -o \( ! -type l \) \( -user `id -u ${CURRUSR}` -perm -u=w -o -group `id -g ${CURRUSR}` -perm -g=w -o -perm -o=w \) -ls | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null

#rm -f ${CURDIR}/perf.txt
echo -e "--1.16 Performance" | ${TEEFILE} > /dev/null
echo -e "Uptime and load average" | ${TEEFILE} > /dev/null
echo -e "Hostname: `hostname; uptime`" | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "top output:" | ${TEEFILE} > /dev/null
top -c -b -n 5 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "iostat #1 output:" | ${TEEFILE} > /dev/null
iostat -xtm 1 15 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "iostat #2 output:" | ${TEEFILE} > /dev/null
iostat -xtmN 1 15 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "vmstat output:" | ${TEEFILE} > /dev/null
vmstat -Sm  1 15 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "free output:" | ${TEEFILE} > /dev/null
free -m 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "/proc/swaps contents:" | ${TEEFILE} > /dev/null
cat /proc/swaps 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "netstat -s output:" | ${TEEFILE} > /dev/null
netstat -s 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "netstat after 10s" | ${TEEFILE} > /dev/null
sleep 10
netstat -s 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "netstat -tulnpe output:" | ${TEEFILE} > /dev/null
netstat -tulnpe  2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "lsof output:" | ${TEEFILE} > /dev/null
lsof -Pn 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "lsof TCP output:" | ${TEEFILE} > /dev/null
lsof -i TCP -Pn 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "lsof UDP output:" | ${TEEFILE} > /dev/null
lsof -i UDP -Pn 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "find WAIT state" | ${TEEFILE} > /dev/null
netstat -natp | grep -i wait 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null

echo -e "--1.17 Audit" | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "check audit service:" | ${TEEFILE} > /dev/null
systemctl | grep audit 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "auditctl output:" | ${TEEFILE} > /dev/null
auditctl -l 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "/etc/audit/auditd.conf contents:" | ${TEEFILE} > /dev/null
cat /etc/audit/auditd.conf 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "/etc/audit/audit.conf contents:" | ${TEEFILE} > /dev/null
cat /etc/audit/audit.conf 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "/etc/audit/rules.d contents:" | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
for FILESA in `ls /etc/audit/rules.d/*`; do echo "${FILESA} content:"; echo "---------------------------------------"; cat ${FILESA}; echo " "; done | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "Audit report summary:" | ${TEEFILE} > /dev/null
aureport -x --summary 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "Audit report failed:" | ${TEEFILE} > /dev/null
aureport --failed 2> /dev/null | ${TEEFILE} > /dev/null


echo -e "--1.18 Security Aspect" | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "SELinux getenforce:" | ${TEEFILE} > /dev/null
getenforce 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "/etc/selinux/config contents:" | ${TEEFILE} > /dev/null
cat /etc/selinux/config 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "SELinux sestatus:" | ${TEEFILE} > /dev/null
sestatus 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "SELinux seinfo -u:" | ${TEEFILE} > /dev/null
seinfo -u 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "SELinux seinfo -r:" | ${TEEFILE} > /dev/null
seinfo -r 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "SELinux seinfo --all:" | ${TEEFILE} > /dev/null
seinfo --all 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "SELinux semanage port -l:" | ${TEEFILE} > /dev/null
semanage port -l 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "SELinux semanage boolean -l:" | ${TEEFILE} > /dev/null
semanage boolean -l 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "SELinux getsebool -a:" | ${TEEFILE} > /dev/null
getsebool -a 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "iptables --list:" | ${TEEFILE} > /dev/null
iptables --list 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "firewall-cmd --list-all-zones:" | ${TEEFILE} > /dev/null
firewall-cmd --list-all-zones 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "firewall-cmd --get-default-zone:" | ${TEEFILE} > /dev/null
firewall-cmd --get-default-zone 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "firewall-cmd --list-services:" | ${TEEFILE} > /dev/null
firewall-cmd --list-services 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "firewall-cmd --list-ports:" | ${TEEFILE} > /dev/null
firewall-cmd --list-ports 2> /dev/null | ${TEEFILE} > /dev/null


echo -e "--1.19 HA (Pacemaker)" | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "pcs config:" | ${TEEFILE} > /dev/null
pcs config 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "pcs constraint show --full:" | ${TEEFILE} > /dev/null
pcs constraint show --full 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "pcs quorum config:" | ${TEEFILE} > /dev/null
pcs quorum config 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "/etc/corosync/corosync.conf contents:" | ${TEEFILE} > /dev/null
cat /etc/corosync/corosync.conf 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "corosync-cmapctl output:" | ${TEEFILE} > /dev/null
corosync-cmapctl 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "crm_simulate -sL output:" | ${TEEFILE} > /dev/null
crm_simulate -sL 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "lsmod | egrep (wd|dog) output:" | ${TEEFILE} > /dev/null
lsmod | egrep "(wd|dog)" 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "sbd query-watchdog output:" | ${TEEFILE} > /dev/null
sbd query-watchdog 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "/etc/sysconfig/sbd contents:" | ${TEEFILE} > /dev/null
cat /etc/sysconfig/sbd 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "/usr/lib/systemd/system/corosync.service contents:" | ${TEEFILE} > /dev/null
cat /usr/lib/systemd/system/corosync.service 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "systemctl status corosync|pcsd|pacemaker:" | ${TEEFILE} > /dev/null
systemctl status corosync 2> /dev/null | ${TEEFILE} > /dev/null
systemctl status pcsd 2> /dev/null | ${TEEFILE} > /dev/null
systemctl status pacemaker 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "/var/log/pacemaker.log Contents:" | ${TEEFILE} > /dev/null
cat /var/log/pacemaker.log 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "/var/log/cluster/corosync.log Contents:" | ${TEEFILE} > /dev/null
cat /var/log/cluster/corosync.log 2> /dev/null | ${TEEFILE} > /dev/null


echo -e "--1.20 OS Log Check" | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "Dmesg output:" | ${TEEFILE} > /dev/null
dmesg -T 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "File Contents /var/log/message*:" | ${TEEFILE} > /dev/null
for FILESA in `ls /var/log/message*`; do echo "${FILESA} content:"; echo "---------------------------------------"; cat ${FILESA}; echo " "; echo " "; done | ${TEEFILE} > /dev/null

echo -e "--1.21 Config Files Check" | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "List *.conf in /etc:" | ${TEEFILE} > /dev/null
find /etc -type f -name "*.conf" -ls 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "List *.conf not in /etc:" | ${TEEFILE} > /dev/null
find / -name '*.conf' -not \( -path "/proc/*" -o -path "/dev/*" -o -path "/sys/*" -o -path "/etc/*" \) -ls 2> /dev/null | ${TEEFILE} > /dev/null


echo -e "--1.22 Kernel Modules" | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "/etc/modprobe.conf Contents:" | ${TEEFILE} > /dev/null
cat /etc/modprobe.conf 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "File Contents in /etc/modprobe.d:" | ${TEEFILE} > /dev/null
for FILESA in `ls /etc/modprobe.d/*`; do echo "${FILESA} contents:"; echo "---------------------------------------"; cat ${FILESA}; echo " "; echo " "; done | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "List Modules in use:" | ${TEEFILE} > /dev/null
lsmod 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "List Modules Description in use:" | ${TEEFILE} > /dev/null
for FILESA in `lsmod | awk '{print $1}'`; do echo "${FILESA} Information:"; echo "---------------------------------------"; modinfo ${FILESA}; echo " "; echo " "; done | ${TEEFILE} > /dev/null


echo -e "--1.23 Time and Timezone" | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "timedatectl output:" | ${TEEFILE} > /dev/null
timedatectl status 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
timedatectl show-timesync 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "systemctl status systemd-timesyncd output:" | ${TEEFILE} > /dev/null
systemctl status systemd-timesyncd 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "File /etc/localtime detail:" | ${TEEFILE} > /dev/null
ls -l /etc/localtime 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "NTP Check:" | ${TEEFILE} > /dev/null
systemctl status ntpd 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "/etc/ntp/ntp.conf  Contents:" | ${TEEFILE} > /dev/null
cat /etc/ntp/ntp.conf 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "/etc/ntpd.conf Contents:" | ${TEEFILE} > /dev/null
cat /etc/ntpd.conf 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "ntpstat output: " | ${TEEFILE} > /dev/null
ntpstat 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "ntpq -pn output: " | ${TEEFILE} > /dev/null
ntpq -pn 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "ntpq -p output: " | ${TEEFILE} > /dev/null
ntpq -p 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "Chrony Check:" | ${TEEFILE} > /dev/null
systemctl status chronyd 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "/etc/chrony.conf Contents:" | ${TEEFILE} > /dev/null
cat /etc/chrony.conf 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "chronyc sources output:" | ${TEEFILE} > /dev/null
chronyc sources 2> /dev/null | ${TEEFILE} > /dev/null

echo -e "--1.24 Locale Settings" | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "locale output:" | ${TEEFILE} > /dev/null
locale 2> /dev/null | ${TEEFILE} > /dev/null

echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "locale charmap output:" | ${TEEFILE} > /dev/null
locale charmap 2> /dev/null | ${TEEFILE} > /dev/null


echo -e "--2. Database Info and Configuration" | ${TEEFILE} > /dev/null
echo -e "--2.1 Database Version and compilation info" | ${TEEFILE} > /dev/null
echo -e "Database Version: ${db_version}" | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "Database compilation configuration information" | ${TEEFILE} > /dev/null
pg_config 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
data_directory=`${PGCONN} -At -c "SELECT setting from pg_settings where name = 'data_directory';"`
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo "data_directory: ${data_directory}" | ${TEEFILE} > /dev/null 
if [ "${IS_REMOTE}" = "N" ]; then
   echo "pg_controldata output:" | ${TEEFILE} > /dev/null 
   pg_controldata -D ${data_directory} 2> /dev/null | ${TEEFILE} > /dev/null
else
   echo "pg_controldata skipped for remote/docker database" | ${TEEFILE} > /dev/null
fi
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null

echo -e "--2.2 postgresql.conf" | ${TEEFILE} > /dev/null
TMPPGDATA=`${PGCONN} -At -P format=unaligned -c "SHOW config_file"`
if [ "${IS_REMOTE}" = "N" ]; then
   echo -e "md5 value: `md5sum ${TMPPGDATA}`" | ${TEEFILE} > /dev/null
   echo -e "\nnon-default value:" | ${TEEFILE} > /dev/null
   if [ ! -f ${PGDATA}/postgresql.conf ]; then
      grep "^[a-z]" ${TMPPGDATA} 2> /dev/null | ${TEEFILE} > /dev/null
   else
      grep "^[a-z]" ${PGDATA}/postgresql.conf 2> /dev/null | ${TEEFILE} > /dev/null
   fi
else
   echo "Config file path in database: ${TMPPGDATA}" | ${TEEFILE} > /dev/null
   echo "Detail config file content check skipped for remote/docker database" | ${TEEFILE} > /dev/null
fi

echo -e "\npostgresql.auto.conf" | ${TEEFILE} > /dev/null
if [ "${IS_REMOTE}" = "N" ]; then
   TMPPGAUTO=$(cd $(dirname "$TMPPGDATA"); pwd)
   echo -e "md5 value: `md5sum ${TMPPGAUTO}/postgresql.auto.conf`" | ${TEEFILE} > /dev/null
   echo -e "\nnon-default value:" | ${TEEFILE} > /dev/null
   if [ ! -f ${PGDATA}/postgresql.auto.conf ]; then
      grep "^[a-z]" ${TMPPGAUTO}/postgresql.auto.conf 2> /dev/null | ${TEEFILE} > /dev/null
   else
      grep "^[a-z]" ${PGDATA}/postgresql.auto.conf 2> /dev/null | ${TEEFILE} > /dev/null
   fi
else
   echo "Detail auto config check skipped for remote/docker database" | ${TEEFILE} > /dev/null
fi
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null

echo -e "\n--2.3 pg_hba.conf" | ${TEEFILE} > /dev/null
TMPPGHBA=`${PGCONN} -At -P format=unaligned -c "SHOW hba_file"`
if [ "${IS_REMOTE}" = "N" ]; then
   echo -e "md5 value: `md5sum ${TMPPGHBA}`" | ${TEEFILE} > /dev/null
   echo -e "\nnon-default value:" | ${TEEFILE} > /dev/null
   if [ ! -f ${PGDATA}/pg_hba.conf ]; then
      grep "^[a-z]" ${TMPPGHBA} 2> /dev/null | ${TEEFILE} > /dev/null
   else
      grep "^[a-z]" ${PGDATA}/pg_hba.conf 2> /dev/null | ${TEEFILE} > /dev/null
   fi
else
   echo "HBA file path in database: ${TMPPGHBA}" | ${TEEFILE} > /dev/null
   echo "Detail HBA config check skipped for remote/docker database" | ${TEEFILE} > /dev/null
fi
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null

echo -e "\n--2.4 recovery.conf and recover.done" | ${TEEFILE} > /dev/null
if [ "${IS_REMOTE}" = "N" ]; then
   if [ -f "${PGDATA}/recovery.conf" ] || [ -f "${PGDATA}/recovery.done" ]; then
      echo -e "md5 value:` md5sum ${PGDATA}/recovery.*`" | ${TEEFILE} > /dev/null
      echo -e "recovery.conf contents:" | ${TEEFILE} > /dev/null
      cat ${PGDATA}/recovery.conf 2> /dev/null | ${TEEFILE} > /dev/null
      echo -e " " | ${TEEFILE} > /dev/null
      echo -e " " | ${TEEFILE} > /dev/null
      echo -e "recovery.done contents:" | ${TEEFILE} > /dev/null
      cat ${PGDATA}/recovery.cone 2> /dev/null | ${TEEFILE} > /dev/null
   else
      echo -e "WARNING: recovery.conf/recovery.done recovery configuration file does not exist." | ${TEEFILE} > /dev/null
   fi
else
   echo "Skipped for remote/docker database" | ${TEEFILE} > /dev/null
fi
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null

echo -e "\n--2.5 standby.signal and recovery.signal" | ${TEEFILE} > /dev/null
if [ "${IS_REMOTE}" = "N" ]; then
   if [ -f "${PGDATA}/standby.signal" ] || [ -f "${PGDATA}/recovery.signal" ]; then
      echo -e "md5 value:` md5sum ${PGDATA}/*.signal`" | ${TEEFILE} > /dev/null
      echo -e "standby.signal contents:" | ${TEEFILE} > /dev/null
      cat ${PGDATA}/standby.signal 2> /dev/null | ${TEEFILE} > /dev/null
      echo -e " " | ${TEEFILE} > /dev/null
      echo -e " " | ${TEEFILE} > /dev/null
      echo -e "recovery.signal contents:" | ${TEEFILE} > /dev/null
      cat ${PGDATA}/recovery.signal 2> /dev/null | ${TEEFILE} > /dev/null
   else
      echo -e "WARNING: standby.signal/recovery.signal file does not exist." | ${TEEFILE} > /dev/null
   fi
else
   echo "Skipped for remote/docker database" | ${TEEFILE} > /dev/null
fi
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null

# Error classification and number of times in csvlog since the last inspection
echo -e "\n\n--3. Analyze postgresql log since 30 days ago until now" | ${TEEFILE} > /dev/null
# pg 9.x
# log_directory=`${PGCONN} -At -c "select case when setting='pg_log' then '${PGDATA}/pg_log' else setting end from pg_settings where name='log_directory';"`

# pg 10.x
# log_directory=`${PGCONN} -At -c "select case when setting='log' then '${PGDATA}/log' else setting end from pg_settings where name='log_directory';"`
# Log analysis only supports the csv log format. The current policy only analyzes the logs before January.
#awk -F "," '{print $12" "$13}' ${log_directory}/postgresql-`date +%Y`-`date +%m`*.csv |grep -E "WARNING|ERROR|FATAL|PANIC"|sort|uniq -c|sort -rn
# find ${log_directory}/. -name "*.log" -ctime  -30 -exec awk -F "," '{print $12" "$13}' '{}' \; | grep -E "WARNING|ERROR|FATAL|PANIC"|sort|uniq -c|sort -rn | ${TEEFILE} > /dev/null

if [ "${IS_REMOTE}" = "N" ]; then
   log_directory=`${PGCONN} -At -c "select trim(setting) from pg_settings where name='log_directory';"`
   echo "log_directory: ${data_directory}/${log_directory}" | ${TEEFILE} > /dev/null
   find ${data_directory}/${log_directory} -name "*.log" -ctime -30 -exec awk '{print $4" "$5}' '{}' \; | grep -E "WARNING|ERROR|FATAL|PANIC"|sort|uniq -c|sort -rn | ${TEEFILE} > /dev/null
else
   echo "Local postgres log analysis skipped for remote/docker database" | ${TEEFILE} > /dev/null
fi
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null


# Timing tasks, subject to change
echo -e "\n\n--4. timed tasks" | ${TEEFILE} > /dev/null
# improve by cat all cron entries
echo -e "listed all user cron entries:" | ${TEEFILE} > /dev/null
for user in $(cut -f1 -d: /etc/passwd); do CK=`crontab -u $user -l 2>/dev/null|wc -l`; if [ $CK -gt 0 ]; then echo "crontab entries user: $user"; echo "------------------------------"; crontab -u $user -l 2>/dev/null; echo " "; fi | grep -v '^#'; done | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
# todo: check pg_cron entries if any

# Database Object Information
echo -e "\n\n#05, database object information" | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null

get_db_object_info(){
${PGCONN} <<EOF
\echo '\n--5. PostgreSQL Settings'
\echo '\n--5.0 Settings'
\echo '\n '
\echo '\n--5.0.1 current settings'
\i ${SQLDIR}/pg_settings.sql
\echo '\n '
\echo '\n '
\echo '\n--5.0.2 file settings'
\i ${SQLDIR}/pg_settings_file.sql
\echo '\n '
\echo '\n '
\i ${SQLDIR}/pg_settings_hba.sql
\echo '\n '
\echo '\n '
\echo '\n--5.0.3 database setting'
\echo '\n '
\i ${SQLDIR}/pg_settings_db.sql
\echo '\n '
\echo '\n '
\echo '\n--5.0.4 role + database setting'
\echo '\n '
\i ${SQLDIR}/pg_settings_db_role.sql
\echo '\n '
\echo '\n '
\echo '\n--5.1 Tablespace'
\db
\echo '\n '
\echo '\n '
\echo '\n--5.2 Database Size'
\echo '\n '
\i ${SQLDIR}/db_size.sql
\echo '\n '
\echo '\n '
\echo '\n--5.3 Roles/Users and Privileges'
\du
\echo '\n '
\i ${SQLDIR}/role_grant.sql
\echo '\n '
\q  
EOF
}

get_db_object_info 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null


check_db_extension()
{
   echo -e "\n\nCheck database extension" 
   for db_name in `${PGCONN} -At -c "${SQLDB}"`
   do
       DB_URL="-h ${PGHOST} -p ${PGPORT} -d ${db_name} -U ${PGUSR}"
       echo -e "##### database ${db_name} "
       psql ${DB_URL} <<EOF
\dx
\q  
EOF
   done
return 0
}

echo -e "\n\n--5.4 Check extensions installed on database" | ${TEEFILE} > /dev/null
check_db_extension 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null


check_db_fdw()
{
   echo -e "\n\nCheck database fdw" 
   for db_name in `${PGCONN} -At -c "${SQLDB}"`
   do
       DB_URL="-h ${PGHOST} -p ${PGPORT} -d ${db_name} -U ${PGUSR}"
       echo -e "##### database ${db_name} "
       psql ${DB_URL} <<EOF
\des
\dES+
\det+
\des+
\deu+
\dew+
select * from pg_foreign_data_wrapper;
select * from pg_foreign_server;
select * from pg_user_mapping;
select * from pg_foreign_table;
\q  
EOF
   done
return 0
}

echo -e "\n\n--5.5 Check database fdw" | ${TEEFILE} > /dev/null
check_db_fdw 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null


echo -e "--5.6 Database XID Wraparound Healthcheck" | ${TEEFILE} > /dev/null
${PGCONN} -f ${SQLDIR}/database_xid_age.sql 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null

# TOP 10 SQL since the last inspection
echo -e "\n\n--6. TOP 10 SQL since the last inspection" | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "--6.1 TOP 20 Query, CPU Time" | ${TEEFILE} > /dev/null
if [ ${PG_STAT_STATEMENT} -eq 1 ]; then
   ${PGCONN} -qtX -0 -f ${SQLDIR}/top20qry_cputime.sql | sed /--/g | ${TEEFILE} > /dev/null
fi
echo -e "\n------------------------------------------------------------------------------------------------------\n" | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null

echo -e "--6.2 TOP 20 Query, Number of calls" | ${TEEFILE} > /dev/null
if [ ${PG_STAT_STATEMENT} -eq 1 ]; then
   ${PGCONN} -qtX -0 -f ${SQLDIR}/top20qry_numcalls.sql | sed /--/g | ${TEEFILE} > /dev/null
fi
echo -e "\n------------------------------------------------------------------------------------------------------\n" | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null

echo -e "--6.3 TOP 20 Query, Single/elapsed time" | ${TEEFILE} > /dev/null
if [ ${PG_STAT_STATEMENT} -eq 1 ]; then
   ${PGCONN} -qtX -0 -f ${SQLDIR}/top20qry_elapsedtime.sql | sed /--/g | ${TEEFILE} > /dev/null
fi
echo -e "\n------------------------------------------------------------------------------------------------------\n" | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null

echo -e "--6.4 DML that still running > 15 secs" | ${TEEFILE} > /dev/null
${PGCONN} -qtX -0 -f ${SQLDIR}/slow_dml.sql | sed /--/g | ${TEEFILE} > /dev/null
echo -e "\n------------------------------------------------------------------------------------------------------\n" | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null

echo -e "--6.5 SELECT that still running > 15 secs" | ${TEEFILE} > /dev/null
${PGCONN} -qtX -0 -f ${SQLDIR}/slow_qry.sql | sed /--/g | ${TEEFILE} > /dev/null
echo -e "\n------------------------------------------------------------------------------------------------------\n" | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null


echo -e "\n\n--7. database running status inspection" | ${TEEFILE} > /dev/null
echo -e "--7.1 Number of connections" | ${TEEFILE} > /dev/null
${PGCONN} -f ${SQLDIR}/dbconn_size.sql | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null

echo -e "\n--7.2 Autovacuum and vacuum related" | ${TEEFILE} > /dev/null 
${PGCONN} -f ${SQLDIR}/vacuum_settings.sql | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null

muti_db_vacuum()
{
 declare -a SQLFILE=(last_autovacuum_and_autoanalyze.sql postrgesql_autovacuum_queue_detailed.sql)
 declare -a SQLNOTE=('Last vacuum, analyze' 'autovacuum queue detail')

IDX=0
 
for I in ${SQLFILE[@]}
do
   echo -e "\n\n########### ${SQLNOTE[$IDX]} ###############" 
   IDX=$((IDX+1))
   for db_name in `${PGCONN} -At -c "${SQLDB}"`
    do
       DB_URL="-h ${PGHOST} -p ${PGPORT} -d ${db_name} -U ${PGUSR}"
       echo -e "##### database ${db_name} "
       psql ${DB_URL} -f "${SQLDIR}/${I}"
    done
done
return 0
}

echo -e " " | ${TEEFILE} > /dev/null
muti_db_vacuum 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null


muti_db_check_file()
{
 declare -a SQLFILE=(pg_settings_table.sql table_grant.sql tbl8gb.sql tbl_5idx.sql idx_unused.sql junkdata.sql check_seq.sql check_tbl_part.sql table_bloat_check.sql index_bloat_check.sql no_stats_table_check.sql unused_indexes.sql needed_indexes.sql fk_no_index.sql duplicate_indexes_fuzzy.sql tbl_hit_ratio.sql idx_hit_ratio.sql check_fillfactor.sql lock_blocker.sql)
 declare -a SQLNOTE=('Specific Table Settings' 'table grant with grant option' 'tables larger than 8GB and age' 'Table with more than 5 indexes' 'Unused or infrequently index index used' 'Garbage Ratio > 20%' 'Check Sequences, remaining < 500mio' 'Check table partitions' 'Check Table Bloat' 'Check Index Bloat' 'Check Table without statistics' 'Unused Indexes' 'Needed index on columns' 'FK without index' 'Columns used in many Indexes' 'Table Hit Ratio' 'Index Hit Ratio' 'Check Fillfactor' 'Locking and Blocking')

IDX=0
 
for I in ${SQLFILE[@]}
do
   echo -e "\n\n########### ${SQLNOTE[$IDX]} ###############" 
   IDX=$((IDX+1))
   for db_name in `${PGCONN} -At -c "${SQLDB}"`
    do
       DB_URL="-h ${PGHOST} -p ${PGPORT} -d ${db_name} -U ${PGUSR}"
       echo -e "##### database ${db_name} "
       psql ${DB_URL} -f "${SQLDIR}/${I}"
    done
done
return 0
}


echo -e "\n\n--7.3 Multi-database checking" | ${TEEFILE} > /dev/null
muti_db_check_file 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null

echo -e "\n\n--7.4 Rollback + Hit ratio" | ${TEEFILE} > /dev/null
${PGCONN} -f ${SQLDIR}/rollback_hit_ratio.sql | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null

echo -e "\n\n--7.5 Long Transaction (> 15 secs)" | ${TEEFILE} > /dev/null

if [ ${db_big_version} == '9.0' ] || [ ${db_big_version} == '9.1' ]; then
   ${PGCONN} -xt -f ${SQLDIR}/longrun_9.sql | ${TEEFILE} > /dev/null
else  
   ${PGCONN} -xt -f ${SQLDIR}/longrun_10.sql | ${TEEFILE} > /dev/null
fi
echo -e " " | ${TEEFILE} > /dev/null

echo -e "\n--7.6 bgwriter and checkpoint" | ${TEEFILE} > /dev/null 
${PGCONN} -xt -f ${SQLDIR}/bgwriter_chkpt.sql 2> /dev/null | ${TEEFILE} > /dev/null
${PGCONN} -xt -f ${SQLDIR}/pg_chkpt_bg_be_pct.sql 2> /dev/null | ${TEEFILE} > /dev/null
${PGCONN} -xt -f ${SQLDIR}/bgwr-ckpt-report.sql 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null

echo -e "\n--8. Replication" | ${TEEFILE} > /dev/null 
echo -e "\n--8.1 Replication settings" | ${TEEFILE} > /dev/null 
${PGCONN} -f ${SQLDIR}/sr_sync_param.sql 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null

echo -e "\n--8.2 Replication status" | ${TEEFILE} > /dev/null 
echo -e "Replication status (Master Side)" | ${TEEFILE} > /dev/null
${PGCONN} -f ${SQLDIR}/sr_stat.sql 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null
echo -e "Replication status (Slave Side)" | ${TEEFILE} > /dev/null
${PGCONN} -f ${SQLDIR}/pg_stat_wal_receiver.sql 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null

muti_db_replication_file()
{
 declare -a SQLFILE=(pg_replication_slots.sql pg_publication.sql pg_publication_tables.sql pg_subscription.sql pg_stat_subscription.sql)
 declare -a SQLNOTE=('All Replication Slots' 'Logical Replication Publication (Master Side)' 'Logical Replication Publication Tables (Master Side)' 'Logical Replication Subscription (Slave Side)' 'Logical Replication Status (Slave Side)')

IDX=0
 
for I in ${SQLFILE[@]}
do
   echo -e "\n\n########### ${SQLNOTE[$IDX]} ###############" 
   IDX=$((IDX+1))
   for db_name in `${PGCONN} -At -c "${SQLDB}"`
    do
       DB_URL="-h ${PGHOST} -p ${PGPORT} -d ${db_name} -U ${PGUSR}"
       echo -e "##### database ${db_name} "
       psql ${DB_URL} -f "${SQLDIR}/${I}"
    done
done
return 0
}

echo -e "\n\n--8.3 Multi-database Replication Check" | ${TEEFILE} > /dev/null
muti_db_replication_file 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null


muti_db_pglogical()
{
 declare -a SQLFILE=(pglogical_replication_check.sql)
 declare -a SQLNOTE=('pglogical check... ')

IDX=0
 
for I in ${SQLFILE[@]}
do
   echo -e "\n\n########### ${SQLNOTE[$IDX]} ###############" 
   IDX=$((IDX+1))
   for db_name in `${PGCONN} -At -c "${SQLDB}"`
    do
       DB_URL="-h ${PGHOST} -p ${PGPORT} -d ${db_name} -U ${PGUSR}"
       echo -e "##### database ${db_name} "
       psql ${DB_URL} -At -f "${SQLDIR}/${I}"
    done
done
return 0
}

echo -e "\n\n--8.4 Multi-database pglogical Check" | ${TEEFILE} > /dev/null
muti_db_pglogical 2> /dev/null | ${TEEFILE} > /dev/null
echo -e " " | ${TEEFILE} > /dev/null

 
echo -e "\n--8.5 Query cancelled due to conflict, some are replication related" | ${TEEFILE} > /dev/null 
${PGCONN} -f ${SQLDIR}/db_conflict_slave.sql 2> /dev/null | ${TEEFILE} > /dev/null


# Delete run tag file
sleep 2
rm -f hc.pid

echo -e "\nDatabase Health Check Report ${RPTFILE} has been generated."
