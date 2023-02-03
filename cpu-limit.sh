#!/bin/bash
# by spiritlhl
# from https://github.com/spiritLHLS/Oracle-server-keep-alive-script

function calculate_primes() {
  size=$1
  for ((i=2;i<=$size;i++)); do
    for ((j=2;j<=i/2;j++)); do
      if [ $((i%j)) == 0 ]; then
        break
      fi
    done
    if [ $j -gt $((i/2)) ]; then
      echo $i &> /dev/null  
    fi
  done
}

size=500
interval=2
while true; do
  cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
  calculate_primes $size &
  if (( $(echo "$cpu_usage < 20" | bc -l) )); then
    size=$((size+10))
    interval=$((interval+1))
  elif (( $(echo "$cpu_usage > 25" | bc -l) )); then
    size=$((size-10))
    interval=$((interval-1))
  fi
  sleep $interval
done
