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
timediff=`expr $currtime - $lastsync`
synctime=$(date +%s)
if [ "$timediff" -gt "$intervalsecs" ]; then
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
