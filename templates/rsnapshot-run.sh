#!/usr/bin/env bash

# this is called every 5 minutes

set -o errexit

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

log_info "Starting ${0}..."

{% for backup in rsnapshot_backups %}
intervalint={{ backup.interval | replace('every', '') | regex_replace ('[^0-9]*', '') }}
intervalunit="{{ backup.interval | replace('every', '') | regex_replace('[0-9]*', '') }}"
if [ "$intervalunit" == "min" ]; then
  intervalsecs=`expr $intervalint "*" 60`
elif [ "$intervalunit" == "h" ]; then
  intervalsecs=`expr $intervalint "*" 60 "*" 60`
fi

lastsync_file="/etc/rsnapshot/rsnapshot-{{ backup.name }}.lastsuccess"
if [ -f "$lastsync_file" ]; then
  lastsync=$(cat ${lastsync_file})
else
  lastsync=0
fi
currtime=$(date +%s)
timediff=`expr $currtime - $lastsync + 5`
synctime=$(date +%s)
if [ "$timediff" -gt "$intervalsecs" ]; then
  log_info "Attempting sync for {{ backup.name }}"
  pidfile="/var/run/rsnapshot-{{ backup.name }}.pid"
  sleeptime=0
  maxsleeptime=60
  while [ -f "$pidfile" ] && kill -0 $(cat "$pidfile") && [ $sleeptime -lt $maxsleeptime ]; do
    log_info "rsnapshot for {{ backup.name }} is already running (probably rotating)"
    sleep 5
    sleeptime=`expr $sleeptime + 5`
  done
  log_info "Running sync for {{ backup.name }}"
  if ! rsnapshot -c /etc/rsnapshot/rsnapshot-{{ backup.name }}.conf sync; then
    log_error "Failed backup {{ backup.name }}"
    failedjobs=1
  else
    echo "$synctime" > "$lastsync_file"
    log_info "Successfully synced {{ backup.name }}"
  fi
fi
{% endfor %}
if [ "$failedjobs" == 1 ]; then
  exit 1
fi
