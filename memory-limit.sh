#!/bin/bash
# by spiritlhl
# from https://github.com/spiritLHLS/Oracle-server-keep-alive-script

while true
do
  mem_total=$(free | awk '/Mem/ {print $2}')
  mem_used=$(free | awk '/Mem/ {print $3}')
  mem_usage=$(echo "scale=2; $mem_used/$mem_total * 100.0" | bc)
  if [ $(echo "$mem_usage < 25" | bc) -eq 1 ]; then
    target_mem_usage=$(echo "scale=0; $mem_total * 0.25 / 1" | bc)
    stress_mem=$(echo "$target_mem_usage - $mem_used" | bc)
    stress_mem_in_gb=$(echo "scale=0; $stress_mem / 1024 / 1024" | bc)
    fallocate -l "${stress_mem_in_gb}G" /dev/shm/file
    sleep 60
    rm /dev/shm/file
  else
    sleep 0.8
  fi
done

