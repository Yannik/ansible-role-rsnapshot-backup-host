#!/usr/bin/env bash

set -o errexit
set -o nounset

backup_name="{{ backup.name }}"

. /etc/rsnapshot/functions.sh


{% set ns = namespace() %}
{% for entry in backup.retain_settings %}

intervalsecs=$(time_to_secs "{{ entry.name | replace('every', '') }}")

lastsync_file="/etc/rsnapshot/rsnapshot-{{ backup.name }}.lastsuccess"

{% if ns.previous_entry is defined %}
  rotate_from_dir="{{ backup.snapshot_root }}/{{ ns.previous_entry.name }}.{{ ns.previous_entry.keep-1 }}"

  if [ -d "$rotate_from_dir" ]; then
    rotate_from_timestamp=$(stat -c %Y "$rotate_from_dir")
  else
    rotate_from_timestamp=0
  fi
{% else %}
  if [ -f "$lastsync_file" ]; then
    rotate_from_timestamp=$(cat "$lastsync_file")
  else
    rotate_from_timestamp=0
  fi
{% endif %}

current_newest="{{ backup.snapshot_root }}/{{ entry.name }}.0"
if [ -d "$current_newest" ]; then
  current_newest_timestamp=$(stat -c %Y "$current_newest")
else
  current_newest_timestamp=0
fi
currtime="$(date +%s)"
timediff_current=$(($currtime - $current_newest_timestamp))
if [ "$timediff_current" -gt "$intervalsecs" ]; then
  timediff_rotation=$(($rotate_from_timestamp - $current_newest_timestamp))
  min_timediff=$(($intervalsecs / 2))

  if [ "$timediff_rotation" -gt "$min_timediff" ]; then
    log_info "Starting rotation {{ entry.name }}"
    rsnapshot -c /etc/rsnapshot/rsnapshot-{{ backup.name }}.conf {{ entry.name }} &> /dev/null
    log_info "Finished rotation"
  else
    log_info "Timediff too small, skipping rotation {{ entry.name }}"
  fi
fi
{% set ns.previous_entry = entry %}
{% endfor %}
