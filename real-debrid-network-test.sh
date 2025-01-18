#!/bin/bash

# Color variables
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ips=(
"45.download.real-debrid.com"
"45.download.real-debrid.com"
"rbx.download.real-debrid.com"
"syd1.download.real-debrid.com"
"hkg1.download.real-debrid.com"
"sgp1.download.real-debrid.com"
"sgpo1.download.real-debrid.com"
"mum1-6.download.real-debrid.com"
"mum1-4.download.real-debrid.com"
"jkt1-4.download.real-debrid.com"
"den1.download.real-debrid.com"
"sea1.download.real-debrid.com"
"nyk1.download.real-debrid.com"
"chi1.download.real-debrid.com"
"lax1.download.real-debrid.com"
"mia1.download.real-debrid.com"
"dal1.download.real-debrid.com"
)

tempfile=$(mktemp)

traceroute_and_parse() {
  local ip=$1
  local output
  local hops
  local latency

  output=$(traceroute -n -q 1 -w 1 "$ip" 2>&1)

  if [ $? -eq 0 ]; then
    hops=$(echo "$output" | wc -l | tr -d ' ')
    latency=$(echo "$output" | tail -1 | awk '{print $3}' | tr -d 'ms')
    speed=$(curl -s -m 10 -o /dev/null -w "%{size_download}" "$ip/speedtest/testDefault.rar" | awk '{bytes=$1; bits=bytes*8; megabits=bits/1000000/10; print megabits}')
    echo -e "Host: ${GREEN}$ip${NC}, Hops: ${GREEN}$hops${NC}, Latency: ${GREEN}${latency}ms${NC}, Speed: ${GREEN}${speed}Mbps${NC}"
    echo "$ip $hops $latency $speed" >> "$tempfile"
  else
    echo "Error performing traceroute for $ip" >&2
  fi
}

traceroute_speed() {
  for ip in "${ips[@]}"; do
    traceroute_and_parse "$ip" 
  done
}


echo -e "${YELLOW}Starting tests...${NC}"
traceroute_speed

echo -e "${YELLOW}Sorting results...${NC}"
sort -n -k 2,2 -k 3,3 "$tempfile" > "${tempfile}_sorted"
lowest_latency=$(awk 'NR==1{print $3}' "${tempfile}_sorted")
latency_threshold=$(bc <<< "$lowest_latency + ($lowest_latency / 4)")
while IFS= read -r line; do
  read -r ip hops latency speed <<< "$line"
  if (( $(bc <<< "$latency <= $latency_threshold") )); then
    echo -e "Host: ${GREEN}$ip${NC}, Hops: ${GREEN}$hops${NC}, Latency: ${GREEN}${latency}ms${NC}, Speed: ${GREEN}${speed}Mbps${NC}"
  fi
  done < "${tempfile}_sorted"

rm "$tempfile" "${tempfile}_sorted"

