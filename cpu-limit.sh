#!/bin/bash
CPU_USAGE=25
# sudo cgcreate -g cpu:/cpulimit
# sudo echo 200000 > /sys/fs/cgroup/cpu/cpulimit/cpu.cfs_quota_us
# sudo cgexec -g cpu:cpulimit stress
while true
do
  CPUS=$(nproc)
  stress --cpu "$CPUS" --timeout 120
  cpulimit -e stress -l "$CPU_LIMIT"
  sleep 130
  kill -9 $(pidof cpulimit)
  kill -9 $(jobs -p)
  sleep 800
done

# while true
# do
#   CPUS=$(nproc)
#   CPU_LIMIT=$(echo "$CPU_USAGE / $CPUS" | bc -l)
#   for i in $(seq 1 "$CPUS"); do
#     cpulimit -l "$CPU_LIMIT" -b dd if=/dev/zero of=/dev/null &
#   done
#   sleep 900
#   kill $(jobs -p)
# done
