#!/bin/sh
set -eu

now_ms ()
{
    if [ -r /proc/uptime ]; then
        awk '{ split($1, a, "."); frac=a[2] "000"; printf "%d", (a[1] * 1000) + substr(frac, 1, 3) }' /proc/uptime
    else
        printf '0'
    fi
}

mark ()
{
    printf 'FLOW_DIAG %s %s %s t_ms=%s\n' "$1" "$2" "$3" "$(now_ms)"
}

fail ()
{
    printf 'FLOW_DIAG FAIL %s t_ms=%s\n' "$1" "$(now_ms)" >&2
    while :; do sleep 3600; done
}

advisory ()
{
    mark "$1" "$2" WARN
}

[ "$$" -eq 1 ] || fail "diagnostic init is not PID 1"
mark 010 PID1_START OK

mkdir -p /proc /sys /dev /tmp /run /sys/fs/cgroup
mount -t proc proc /proc || fail "cannot mount procfs"
[ -r /proc/1/status ] || fail "PID 1 missing from procfs"
mark 020 PROCFS OK

mount -t sysfs sysfs /sys || fail "cannot mount sysfs"
[ -d /sys/devices ] || fail "sysfs device model missing"
mark 030 SYSFS OK

[ -d /sys/class ] || fail "sysfs classes missing"
[ -e /dev/null ] || mknod /dev/null c 1 3 || fail "cannot create /dev/null"
[ -e /dev/console ] || mknod /dev/console c 5 1 || fail "cannot create /dev/console"
[ -e /dev/urandom ] || mknod /dev/urandom c 1 9 || fail "cannot create /dev/urandom"
mark 040 DEVICES OK

printf 'flow-kernel-diagnostic\n' >/tmp/flow-write-test || fail "cannot write /tmp"
grep -q '^flow-kernel-diagnostic$' /tmp/flow-write-test || fail "write test mismatch"
mark 050 WRITE_TEST OK

[ -r /proc/cpuinfo ] || fail "cpuinfo unavailable"
grep -q '^processor' /proc/cpuinfo || fail "no CPU reported"
mark 060 CPU OK

[ -r /proc/meminfo ] || fail "meminfo unavailable"
awk '/^MemTotal:/ { if ($2 > 0) ok=1 } END { exit ok ? 0 : 1 }' /proc/meminfo || fail "invalid MemTotal"
mark 070 MEMORY OK

before="$(cut -d. -f1 /proc/uptime)"
sleep 1
after="$(cut -d. -f1 /proc/uptime)"
[ "$after" -gt "$before" ] || fail "monotonic clock did not advance"
mark 080 CLOCK_TIMER OK

rm -f /tmp/flow-rng
dd if=/dev/urandom of=/tmp/flow-rng bs=16 count=1 2>/dev/null || fail "cannot read urandom"
[ "$(wc -c </tmp/flow-rng)" -eq 16 ] || fail "urandom returned wrong byte count"
mark 090 RNG OK

( exit 0 ) &
child=$!
wait "$child" || fail "child process did not exit cleanly"
mark 100 PROCESS OK

sleep 30 &
child=$!
kill -TERM "$child" || fail "cannot signal child"
set +e
wait "$child" 2>/dev/null
rc=$?
set -e
[ "$rc" -ne 0 ] || fail "signal did not terminate child"
mark 110 SIGNAL OK

printf 'flow-pipe-test\n' | grep -q '^flow-pipe-test$' || fail "pipe IPC failed"
mark 120 PIPE_IPC OK

rm -rf /tmp/flow-fs
mkdir /tmp/flow-fs || fail "mkdir failed"
printf 'abc123\n' >/tmp/flow-fs/a || fail "file create failed"
grep -q '^abc123$' /tmp/flow-fs/a || fail "file read failed"
mv /tmp/flow-fs/a /tmp/flow-fs/b || fail "rename failed"
ln /tmp/flow-fs/b /tmp/flow-fs/c || fail "hard link failed"
cmp /tmp/flow-fs/b /tmp/flow-fs/c || fail "linked file mismatch"
mark 130 FILESYSTEM OK

if [ -d /sys/class/block ] && [ -n "$(ls -A /sys/class/block 2>/dev/null)" ]; then
    mark 140 BLOCK OK
else
    advisory 140 BLOCK
fi

if [ -d /sys/class/net/lo ] && [ -r /proc/net/dev ]; then
    mark 150 NETWORK OK
else
    fail "loopback/network stack missing"
fi

if [ -r /etc/resolv.conf ] && grep -q '^[[:space:]]*nameserver[[:space:]]' /etc/resolv.conf; then
    mark 160 DNS OK
else
    advisory 160 DNS
fi

[ -e /proc/self/ns/mnt ] || fail "mount namespace handle missing"
[ -e /proc/self/ns/pid ] || fail "pid namespace handle missing"
[ -e /proc/self/ns/net ] || fail "network namespace handle missing"
mark 170 NAMESPACES OK

if grep -qE '(^|[[:space:]])cgroup2?($|[[:space:]])' /proc/filesystems 2>/dev/null; then
    mark 180 CGROUP OK
else
    advisory 180 CGROUP
fi

if grep -qE '(^|[[:space:]])bpf($|[[:space:]])' /proc/filesystems 2>/dev/null; then
    mark 190 BPF OK
elif [ -e /proc/sys/kernel/unprivileged_bpf_disabled ]; then
    mark 190 BPF OK
else
    fail "BPF capability evidence missing"
fi

[ -x /opt/flow-hello ] || fail "Flow smoke binary missing"
/opt/flow-hello || fail "Flow smoke binary failed"
mark 200 FLOW_EXEC OK

mark 210 COMPLETE OK
printf 'FLOW_DIAG SUMMARY HEALTHY t_ms=%s\n' "$(now_ms)"

while :
do
    sleep 3600
done
