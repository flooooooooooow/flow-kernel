#!/bin/sh
set -eu

printf 'FLOW_LIFECYCLE REBOOT_START\n'
mkdir -p /proc
mount -t proc proc /proc || true
sync
printf 'FLOW_LIFECYCLE REBOOT_REQUESTED\n'
reboot -f
printf 'FLOW_LIFECYCLE REBOOT_FAILED\n'
while :; do sleep 3600; done
