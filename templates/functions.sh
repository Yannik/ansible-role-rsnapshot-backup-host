#!/usr/bin/env bash

function log_info {
  msg=$1
  date=$(date +"%Y-%m-%d %T")
  echo "$date [$$] {$backup_name} $msg"
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
    secs=$(($valnum * 60))
  elif [[ "$val" == *h ]]; then
    secs=$(($valnum * 60 * 60))
  elif [[ "$val" == *d ]]; then
    secs=$(($valnum * 60 * 60 * 24))
  elif [[ "$val" == *w ]]; then
    secs=$(($valnum * 60 * 60 * 24 * 7))
  fi
  echo "$secs"
}

