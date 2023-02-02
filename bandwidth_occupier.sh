#!/bin/bash
max_bandwidth=$(speedtest-cli --bytes --simple | grep -Eo "[0-9]+")
bandwidth_to_use=$(echo "$max_bandwidth * 0.15" | bc)
dd if=/dev/zero bs=$bandwidth_to_use count=$((5 * 60))
