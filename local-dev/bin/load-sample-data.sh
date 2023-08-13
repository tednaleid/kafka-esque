#! /usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/"

export DEFAULT_KAFKA_BROKER="esque-kafka:9092"
export KAFKA_BROKER="${KAFKA_BROKER:-$DEFAULT_KAFKA_BROKER}"

function populate_partition() {
  local topic=$1
  local partition=$2
  local number=$3
  local compression=${4:-none}

  local event_body
  # random data
  event_body=$(openssl rand -base64 1024 | tr -d '\n')

  echo "populating $topic:$partition with $number events using compression type $compression"
  seq "$number" |
    awk -v body="$event_body" '{printf "%s,%s\n", $1, body}' |
    pv -ablert |
    kcat -P -z "$compression" -p "$partition" -K',' -b "$KAFKA_BROKER" -t "$topic"
}

for PARTITION in {0..9}; do
  populate_partition ten-partitions-lz4 "$PARTITION" 100000 lz4
  populate_partition ten-partitions-snappy "$PARTITION" 10000 snappy
  populate_partition ten-partitions-none "$PARTITION" 10000 none
done
