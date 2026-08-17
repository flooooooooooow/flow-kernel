#!/bin/sh
set -eu

mark ()
{
    printf 'FLOW_DIAG %s %s OK\n' "$1" "$2"
}

fail ()
{
    printf 'FLOW_DIAG FAIL %s\n' "$1" >&2
    exec sh
}

[ "$$" -eq 1 ] || fail "diagnostic init is not PID 1"
mark 010 PID1_START

mkdir -p /proc /sys /dev /tmp
mount -t proc proc /proc || fail "cannot mount procfs"
[ -r /proc/1/status ] || fail "PID 1 missing from procfs"
mark 020 PROCFS

mount -t sysfs sysfs /sys || fail "cannot mount sysfs"
[ -d /sys/devices ] || fail "sysfs device model missing"
mark 030 SYSFS

printf 'flow-kernel-diagnostic\n' >/tmp/flow-write-test || fail "cannot write /tmp"
grep -q 'flow-kernel-diagnostic' /tmp/flow-write-test || fail "write test mismatch"
mark 040 WRITE_TEST

[ -r /proc/cpuinfo ] || fail "cpuinfo unavailable"
[ -r /proc/meminfo ] || fail "meminfo unavailable"
grep -q '^processor' /proc/cpuinfo || fail "no CPU reported"
awk '/^MemTotal:/ { if ($2 > 0) ok=1 } END { exit ok ? 0 : 1 }' /proc/meminfo || fail "invalid MemTotal"
mark 050 CPU_MEMORY

uptime_ticks="$(cut -d. -f1 /proc/uptime 2>/dev/null || echo 0)"
[ "${uptime_ticks:-0}" -ge 0 ] || fail "clock unavailable"
mark 060 CLOCK

[ -d /sys/class ] || fail "sysfs classes missing"
[ -e /dev/console ] || mknod /dev/console c 5 1 || fail "console device unavailable"
mark 070 DEVICES

if [ -d /sys/class/net/lo ]; then
    mark 080 NETWORK
else
    fail "loopback interface missing"
fi

if grep -qE '(^|[[:space:]])bpf([[:space:]]|$)' /proc/filesystems 2>/dev/null; then
    mark 090 BPF
elif [ -e /proc/sys/kernel/unprivileged_bpf_disabled ]; then
    mark 090 BPF
else
    fail "BPF capability evidence missing"
fi

[ -x /opt/flow-hello ] || fail "Flow smoke binary missing"
/opt/flow-hello || fail "Flow smoke binary failed"
mark 100 FLOW_EXEC

mark 110 COMPLETE

while :
do
    sleep 3600
 done
