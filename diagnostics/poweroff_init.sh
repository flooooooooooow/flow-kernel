#!/bin/sh
set -eu

printf 'FLOW_LIFECYCLE POWEROFF_START\n'
mkdir -p /proc
mount -t proc proc /proc || true
sync
printf 'FLOW_LIFECYCLE POWEROFF_REQUESTED\n'
poweroff -f
printf 'FLOW_LIFECYCLE POWEROFF_FAILED\n'
while :; do sleep 3600; done
