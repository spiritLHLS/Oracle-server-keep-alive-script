#!/bin/bash
CPU_USAGE=15
CPUS=$(nproc)
DURATION=$(echo "100 / $CPU_USAGE * $CPUS" | bc)
for i in $(seq 1 "$CPUS"); do
  nice -n 19 ionice -c 3 dd if=/dev/zero of=/dev/null &
done
sleep $DURATION
kill $(jobs -p)
