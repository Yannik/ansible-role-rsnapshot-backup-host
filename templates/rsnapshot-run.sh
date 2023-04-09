#!/usr/bin/env bash

# this is called every 5 minutes

set -o errexit
set -o nounset

backup_name="global"
. /etc/rsnapshot/functions.sh

log_info "Starting ${0}..."
failedjob=0

{% for backup in rsnapshot_backups %}
{% if backup.enabled|default(True) %}
backup_name="{{ backup.name }}"
host="{{ backup.backup_host|default('') }}"
intervalsecs=$(time_to_secs "{{ backup.interval | replace('every', '') }}")

lastsync_file="/etc/rsnapshot/rsnapshot-{{ backup.name }}.lastsuccess"

if [ -f "$lastsync_file" ]; then
  lastsync=$(cat ${lastsync_file})
else
  lastsync=0
fi

currtime=$(date +%s)
timediff=$(($currtime - $lastsync + 5))

function run_sync {
  log_info "Running sync for {{ backup.name }}"
  if ! rsnapshot -c /etc/rsnapshot/rsnapshot-{{ backup.name }}.conf sync; then
    log_error "Failed backup {{ backup.name }}"
    failedjob=1
  else
    echo "$currtime" > "$lastsync_file"
    log_info "Successfully synced"
    /etc/rsnapshot/rsnapshot-rotate.sh
  fi
}

if [ "$timediff" -gt "$intervalsecs" ]; then
  pidfile="/var/run/rsnapshot-{{ backup.name }}.pid"
  sleeptime=0
  downtime=0
  maxsleeptime=60
  maxdowntime=$(time_to_secs "{{ backup.max_downtime|default(rsnapshot_max_downtime) }}")
  lastuptimefile="/etc/rsnapshot/rsnapshot-{{ backup.name }}.lastuptime"
  lastuptime=$(cat "$lastuptimefile" 2>/dev/null || echo 0 )
  downtime=$(($currtime - $lastuptime))

  log_info "Attempting sync"

  if [ -f "$pidfile" ] && kill -0 $(cat "$pidfile"); then
    log_info "rsnapshot for {{ backup.name }} is already running (either rotating or syncing)"
  elif ssh -q -o ConnectTimeout=1 {{ rsnapshot_ssh_args }} "$host" test; then
    log_info "Host reachable, starting sync"
    echo $currtime > "$lastuptimefile"
    run_sync
  elif [ $downtime -gt $maxdowntime ]; then
    log_info "Downtime exceeded, forcing sync for error notification"
    echo $currtime > "$lastuptimefile"
    run_sync
  else
    log_info "SSH connect to host failed"
  fi

fi
{% endif %}
{% endfor %}
exit "$failedjob"
