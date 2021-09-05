#!/usr/bin/env bash

. /etc/rsnapshot/functions.sh

backup_name="rotation"
function pidfile_release() {
  rm "$pidfile"
}
trap pidfile_release EXIT

pidfile="/var/run/rsnapshot-rotate.pid"
if [ -f "$pidfile" ] && kill -0 $(cat "$pidfile"); then
  pid=$(cat "$pidfile")
  log_info "already rotating.. (pid: $pidfile)"
  exit
fi

echo $$ > "$pidfile"
log_info "checking rotations"

{% for backup in rsnapshot_backups %}
{% if backup.enabled|default(True) %}
/etc/rsnapshot/rsnapshot-rotate-{{ backup.name }}.sh
{% endif %}
{% endfor %}

