#!/bin/bash
while true
do
  mem_total=$(free | awk '/Mem/ {print $2}')
  mem_used=$(free | awk '/Mem/ {print $3}')
  mem_usage=$(echo "scale=2; $mem_used/$mem_total * 100.0" | bc)
  if [ $(echo "$mem_usage < 15" | bc) -eq 1 ]; then
    target_mem_usage=$(echo "scale=0; $mem_total * 0.15 / 1" | bc)
    stress_mem=$(echo "$target_mem_usage - $mem_used" | bc) -b
    stress --vm 1 --vm-bytes "${stress_mem}K" -b
    cpulimit -e stress -l 30 -b
    sleep 10
  else
    sleep 10
    kill -9 $(pidof cpulimit)
    kill -9 $(jobs -p)
    sleep 60
  fi
done
