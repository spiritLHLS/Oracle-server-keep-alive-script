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
    stress_mem_in_mb=$(echo "scale=0; $stress_mem / 1024" | bc)
    dd if=/dev/zero of=/tmp/dd.tmp bs=1024m count="${stress_mem_in_mb}"
    timeout 60 rm /tmp/dd.tmp
  else
    sleep 0.8
  fi
done


