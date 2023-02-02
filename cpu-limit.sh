#!/bin/bash
CPU_USAGE=20
while true
do
  CPUS=$(nproc)
  stress --cpu "$CPUS"
  cpulimit -e stress -l "$CPU_LIMIT" --timeout 120
  sleep 120
  kill -9 $(pidof cpulimit)
  kill -9 $(jobs -p)
  sleep 900
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
