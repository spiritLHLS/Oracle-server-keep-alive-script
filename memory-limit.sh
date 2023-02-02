#!/bin/bash
while true
do
  mem_total=$(free | awk '/Mem/ {print $2}')
  mem_used=$(free | awk '/Mem/ {print $3}')
  mem_usage=$(echo "scale=2; $mem_used/$mem_total * 100.0" | bc)
  target_mem_usage=$(echo "scale=0; $mem_total * 0.20 / 1" | bc)
  stress_mem=$(echo "$target_mem_usage - $mem_used" | bc) -b
  stress --vm 1 --vm-bytes "${stress_mem}K" --timeout 110
  cpulimit -p $(pidof stress) -l 40 -b
  sleep 130
  kill -9 $(pidof cpulimit)
  kill -9 $(jobs -p)
  sleep 900
done
