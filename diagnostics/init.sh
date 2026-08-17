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

evidence ()
{
    printf 'FLOW_EVIDENCE %s=%s\n' "$1" "$2"
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
evidence kernel_release "$(cat /proc/sys/kernel/osrelease)"
mark 020 PROCFS OK

mount -t sysfs sysfs /sys || fail "cannot mount sysfs"
[ -d /sys/devices ] || fail "sysfs device model missing"
mark 030 SYSFS OK

if grep -qE '(^|[[:space:]])devtmpfs($|[[:space:]])' /proc/filesystems 2>/dev/null; then
    mount -t devtmpfs devtmpfs /dev || fail "kernel advertises devtmpfs but mount failed"
    evidence devtmpfs_supported true
    evidence devtmpfs_mounted true
else
    evidence devtmpfs_supported false
    evidence devtmpfs_mounted false
fi
[ -d /sys/class ] || fail "sysfs classes missing"
[ -e /dev/null ] || mknod /dev/null c 1 3 || fail "cannot provide /dev/null"
[ -e /dev/console ] || mknod /dev/console c 5 1 || fail "cannot provide /dev/console"
[ -e /dev/urandom ] || mknod /dev/urandom c 1 9 || fail "cannot provide /dev/urandom"
printf 'device-test\n' >/dev/null || fail "/dev/null is not writable"
mark 040 DEVICES OK

printf 'flow-kernel-diagnostic\n' >/tmp/flow-write-test || fail "cannot write /tmp"
grep -q '^flow-kernel-diagnostic$' /tmp/flow-write-test || fail "write test mismatch"
mark 050 WRITE_TEST OK

[ -r /proc/cpuinfo ] || fail "cpuinfo unavailable"
cpu_count="$(grep -c '^processor' /proc/cpuinfo || true)"
[ "$cpu_count" -gt 0 ] || fail "no CPU reported"
evidence cpu_count "$cpu_count"
mark 060 CPU OK

[ -r /proc/meminfo ] || fail "meminfo unavailable"
mem_kb="$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)"
[ "${mem_kb:-0}" -gt 0 ] || fail "invalid MemTotal"
evidence mem_total_kb "$mem_kb"
mark 070 MEMORY OK

before="$(cut -d. -f1 /proc/uptime)"
sleep 1
after="$(cut -d. -f1 /proc/uptime)"
[ "$after" -gt "$before" ] || fail "monotonic clock did not advance"
evidence uptime_seconds "$after"
mark 080 CLOCK_TIMER OK

rm -f /tmp/flow-rng
dd if=/dev/urandom of=/tmp/flow-rng bs=16 count=1 2>/dev/null || fail "cannot read urandom"
[ "$(wc -c </tmp/flow-rng)" -eq 16 ] || fail "urandom returned wrong byte count"
entropy="$(cat /proc/sys/kernel/random/entropy_avail 2>/dev/null || echo unknown)"
evidence entropy_available "$entropy"
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

block_devices="$(ls /sys/class/block 2>/dev/null | tr '\n' ',' | sed 's/,$//' || true)"
if [ -n "$block_devices" ]; then
    evidence block_devices "$block_devices"
    mark 140 BLOCK OK
else
    advisory 140 BLOCK
fi

if [ -d /sys/class/net/lo ] && [ -r /proc/net/dev ]; then
    net_interfaces="$(ls /sys/class/net 2>/dev/null | tr '\n' ',' | sed 's/,$//')"
    evidence net_interfaces "$net_interfaces"
    mark 150 NETWORK OK
else
    fail "loopback/network stack missing"
fi

if [ -r /etc/resolv.conf ] && grep -q '^[[:space:]]*nameserver[[:space:]]' /etc/resolv.conf; then
    evidence dns_configured true
    mark 160 DNS OK
else
    evidence dns_configured false
    advisory 160 DNS
fi

[ -e /proc/self/ns/mnt ] || fail "mount namespace handle missing"
[ -e /proc/self/ns/pid ] || fail "pid namespace handle missing"
[ -e /proc/self/ns/net ] || fail "network namespace handle missing"
mark 170 NAMESPACES OK

cgroup_capable=false
cgroup_mounted=false
if grep -qE '(^|[[:space:]])cgroup2($|[[:space:]])' /proc/filesystems 2>/dev/null; then
    cgroup_capable=true
    if mount -t cgroup2 cgroup2 /sys/fs/cgroup 2>/dev/null; then
        cgroup_mounted=true
    fi
elif grep -qE '(^|[[:space:]])cgroup($|[[:space:]])' /proc/filesystems 2>/dev/null; then
    cgroup_capable=true
    if mount -t cgroup cgroup /sys/fs/cgroup 2>/dev/null; then
        cgroup_mounted=true
    fi
fi
evidence cgroup_capable "$cgroup_capable"
evidence cgroup_mounted "$cgroup_mounted"
if [ "$cgroup_mounted" = true ]; then
    mark 180 CGROUP OK
else
    advisory 180 CGROUP
fi

if grep -qE '(^|[[:space:]])bpf($|[[:space:]])' /proc/filesystems 2>/dev/null; then
    evidence bpf_capable true
    mark 190 BPF OK
elif [ -e /proc/sys/kernel/unprivileged_bpf_disabled ]; then
    evidence bpf_capable true
    mark 190 BPF OK
else
    evidence bpf_capable false
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
