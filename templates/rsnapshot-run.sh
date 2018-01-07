#!/usr/bin/env bash

# this is called every 5 minutes

set -o errexit
set -o nounset

function log_info {
  msg=$1
  date=$(date +"%Y-%m-%d %T")
  echo "$date [$$] $msg"
}

function log_error {
  msg=$1
  date=$(date +"%Y-%m-%d %T")
  >&2 echo "$date [$$] $msg"
}

function time_to_secs {
  local val=$1
  local valnum=$(echo "$val" | sed 's/[^0-9]//g')
  local secs=0

  if [[ "$val" == *min ]]; then
    let secs="$valnum * 60"
  elif [[ "$val" == *h ]]; then
    let secs="$valnum * 60 * 60"
  elif [[ "$val" == *d ]]; then
    let secs="$valnum * 60 * 60 * 24"
  fi
  echo "$secs"
}

log_info "Starting ${0}..."
# Sleep a few seconds to not collide with rotating cronjobs starting at the full minute too
sleep 3
failedjob=0

{% for backup in rsnapshot_backups %}
{% if backup.enabled|default(True) %}
host="{{ backup.backup_host|default('') }}"
intervalsecs=$(time_to_secs "{{ backup.interval | replace('every', '') }}")

lastsync_file="/etc/rsnapshot/rsnapshot-{{ backup.name }}.lastsuccess"

if [ -f "$lastsync_file" ]; then
  lastsync=$(cat ${lastsync_file})
else
  lastsync=0
fi

currtime=$(date +%s)
let timediff="$currtime - $lastsync + 5"

function run_sync {
  log_info "Running sync for {{ backup.name }}"
  if ! rsnapshot -c /etc/rsnapshot/rsnapshot-{{ backup.name }}.conf sync; then
    log_error "Failed backup {{ backup.name }}"
    failedjob=1
  else
    echo "$currtime" > "$lastsync_file"
    log_info "Successfully synced {{ backup.name }}"
  fi
}

if [ "$timediff" -gt "$intervalsecs" ]; then
  pidfile="/var/run/rsnapshot-{{ backup.name }}.pid"
  sleeptime=0
  downtime=0
  maxsleeptime=60
  maxdowntime=$(time_to_secs "{{ backup.max_downtime|default(0) }}")
  lastuptimefile="/etc/rsnapshot/rsnapshot-{{ backup.name }}.lastuptime"
  lastuptime=$(cat "$lastuptimefile" 2>/dev/null || echo 0 )
  let downtime="$currtime - $lastuptime"

  log_info "Attempting sync for {{ backup.name }}"

  if [ -f "$pidfile" ] && kill -0 $(cat "$pidfile"); then
    log_info "rsnapshot for {{ backup.name }} is already running (either rotating or syncing)"
  elif ssh -q -o BatchMode=yes -o ConnectTimeout=1 {{ rsnapshot_ssh_args }} "$host" test || \
  [ $downtime -gt $maxdowntime ]; then
    echo $currtime > "$lastuptimefile"
    run_sync
  else
    log_info "SSH connect to host failed"
  fi

fi
{% endif %}
{% endfor %}
exit "$failedjob"
