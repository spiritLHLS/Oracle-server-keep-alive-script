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

low_main() {
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
      calculate_primes $size &
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
}

high_main(){
  for ((i=0;i<$cores;i++))
  do
      {
          dd if=/dev/zero of=/dev/null
      } &
  done
  wait
}

arch=$(uname -m)
cores=$(nproc)
if [ "$arch" = "armv7l" ] || [ "$arch" = "armv8" ] || [ "$arch" = "armv8l" ] || [ "$arch" = "aarch64" ] || [ "$arch" = "arm" ] ; then
  if [ $cores -eq 3 ] || [ $cores -eq 4 ]; then
    high_main
  else
    size=600
    interval=5
    MIN_SIZE=400
    MIN_INTERVAL=1
    low_main
  fi
else
  size=450
  interval=10
  MIN_SIZE=200
  MIN_INTERVAL=2
  low_main
fi
