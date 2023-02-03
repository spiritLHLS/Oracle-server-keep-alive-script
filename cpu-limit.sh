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

size=350
interval=10
MIN_SIZE=100
MIN_INTERVAL=3
while true; do
  cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
  if (( $(echo "$cpu_usage < 15" | bc -l) )); then
    if [ $(( $(date +%s) % 2 )) == 0 ]; then
      size=$((size+10))
    else
      interval=$(echo "$interval - 0.5" | bc)
    fi
    if [ $size -lt $MIN_SIZE ]; then
      size=$MIN_SIZE
    fi
    if [ $(echo "$interval < $MIN_INTERVAL" | bc -l) -eq 1 ]; then
      interval=$MIN_INTERVAL
    fi
    nice -n 19 calculate_primes $size &
  elif (( $(echo "$cpu_usage > 25" | bc -l) )); then
    if [ $(( $(date +%s) % 2 )) == 0 ]; then
      size=$((size-10))
    else
      interval=$(echo "$interval + 0.5" | bc)
    fi
    if [ $size -lt $MIN_SIZE ]; then
      size=$MIN_SIZE
    fi
    if [ $(echo "$interval < $MIN_INTERVAL" | bc -l) -eq 1 ]; then
      interval=$MIN_INTERVAL
    fi
  else
    echo ""
  fi
  sleep $interval
done
