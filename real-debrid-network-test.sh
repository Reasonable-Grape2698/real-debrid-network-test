#!/bin/bash

# set -x

# Color variables
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Start of the script
echo -e "${YELLOW}Starting REAL-DEBRID network tests...${NC}"
echo "https://github.com/debridmediamanager/real-debrid-network-test"

ips=(
  "20.download.real-debrid.cloud"
  "20.download.real-debrid.com"
  "21.download.real-debrid.cloud"
  "21.download.real-debrid.com"
  "22.download.real-debrid.cloud"
  "22.download.real-debrid.com"
  "23.download.real-debrid.cloud"
  "23.download.real-debrid.com"
  "30.download.real-debrid.cloud"
  "30.download.real-debrid.com"
  "31.download.real-debrid.cloud"
  "31.download.real-debrid.com"
  "32.download.real-debrid.cloud"
  "32.download.real-debrid.com"
  "34.download.real-debrid.cloud"
  "34.download.real-debrid.com"
  "40.download.real-debrid.cloud"
  "40.download.real-debrid.com"
  "41.download.real-debrid.cloud"
  "41.download.real-debrid.com"
  "42.download.real-debrid.cloud"
  "42.download.real-debrid.com"
  "43.download.real-debrid.cloud"
  "43.download.real-debrid.com"
  "44.download.real-debrid.cloud"
  "44.download.real-debrid.com"
  "45.download.real-debrid.cloud"
  "45.download.real-debrid.com"
  "50.download.real-debrid.cloud"
  "50.download.real-debrid.com"
  "51.download.real-debrid.cloud"
  "51.download.real-debrid.com"
  "52.download.real-debrid.cloud"
  "52.download.real-debrid.com"
  "53.download.real-debrid.cloud"
  "53.download.real-debrid.com"
  "54.download.real-debrid.cloud"
  "54.download.real-debrid.com"
  "55.download.real-debrid.cloud"
  "55.download.real-debrid.com"
  "56.download.real-debrid.cloud"
  "56.download.real-debrid.com"
  "57.download.real-debrid.cloud"
  "57.download.real-debrid.com"
  "58.download.real-debrid.cloud"
  "58.download.real-debrid.com"
  "59.download.real-debrid.cloud"
  "59.download.real-debrid.com"
  "60.download.real-debrid.cloud"
  "60.download.real-debrid.com"
  "61.download.real-debrid.cloud"
  "61.download.real-debrid.com"
  "62.download.real-debrid.cloud"
  "62.download.real-debrid.com"
  "63.download.real-debrid.cloud"
  "63.download.real-debrid.com"
  "64.download.real-debrid.cloud"
  "64.download.real-debrid.com"
  "65.download.real-debrid.cloud"
  "65.download.real-debrid.com"
  "66.download.real-debrid.cloud"
  "66.download.real-debrid.com"
  "67.download.real-debrid.cloud"
  "67.download.real-debrid.com"
  "68.download.real-debrid.cloud"
  "68.download.real-debrid.com"
  "69.download.real-debrid.cloud"
  "69.download.real-debrid.com"
  "hkg1.download.real-debrid.com"
  "lax1.download.real-debrid.com"
  "lon1.download.real-debrid.com"
  "mum1.download.real-debrid.com"
  "rbx.download.real-debrid.com"
  "sgp1.download.real-debrid.com"
  "tlv1.download.real-debrid.com"
  "tyo1.download.real-debrid.com"
)

tempfile=$(mktemp)
echo -e "${GREEN}Temporary file created at $tempfile${NC}"

traceroute_and_parse() {
  local ip=$1
  local output
  local hops
  local latency

  output=$(traceroute -n -q 1 -w 1 "$ip" 2>&1)

  if [ $? -eq 0 ]; then
    hops=$(echo "$output" | wc -l | tr -d ' ')
    latency=$(echo "$output" | tail -1 | awk '{print $3}' | tr -d 'ms')

    echo "$ip $hops $latency" >> "$tempfile"
  else
    echo "Error performing traceroute for $ip" >&2
  fi
}

batch_traceroute() {
  local batch_size=10
  local count=0

  for ip in "${ips[@]}"; do
    traceroute_and_parse "$ip" &
    ((count++))

    if (( count % batch_size == 0 )); then
      wait
      count=0
    fi
  done
  echo "Waiting for the final batch to complete..."
  wait
}

batch_traceroute

echo -e "${YELLOW}Sorting results...${NC}"
sort -n -k 2,2 -k 3,3 "$tempfile" > "${tempfile}_sorted"

echo -e "${YELLOW}Calculating latency threshold...${NC}"
lowest_latency=$(awk 'NR==1{print $3}' "${tempfile}_sorted")
latency_threshold=$(bc <<< "$lowest_latency + ($lowest_latency / 4)")

echo -e "${YELLOW}Displaying hosts within latency threshold:${NC}"
while IFS= read -r line; do
  read -r ip hops latency <<< "$line"
  if (( $(bc <<< "$latency <= $latency_threshold") )); then
    echo -e "Host: ${GREEN}$ip${NC}, Hops: ${GREEN}$hops${NC}, Latency: ${GREEN}${latency}ms${NC}"
  fi
done < "${tempfile}_sorted"

echo -e "${YELLOW}Cleaning up temporary files...${NC}"
rm "$tempfile" "${tempfile}_sorted"
echo -e "${GREEN}Temporary files removed. Network test operation complete.${NC}"
