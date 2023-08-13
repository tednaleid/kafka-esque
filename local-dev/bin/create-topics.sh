#! /usr/bin/env bash

set -euo pipefail

cd "$(dirname $0)/"

export ZOOKEEPER_CONTAINER="${ZOOKEEPER_CONTAINER:-esque-zookeeper}"
export ZOOKEEPER_PORT="${ZOOKEEPER_PORT:-2181}"
export ZOOKEEPER_HOST_PORT="$ZOOKEEPER_CONTAINER:$ZOOKEEPER_PORT"

export KAFKA_CONTAINER="${KAFKA_CONTAINER:-esque-kafka}"

function docker_kafka_exec() {
  set -x
  docker exec "$KAFKA_CONTAINER" /bin/bash -c "$@"
  { set +x; } 2>/dev/null
}

function create_topic() {
  local topic_name=$1
  local partitions="${2:-3}"

  if [[ -z "$topic_name" ]]; then
    echo "create_topic: error - missing topic name"
    exit 1
  fi

  docker_kafka_exec "kafka-topics.sh --create --zookeeper $ZOOKEEPER_HOST_PORT --replication-factor 1 --partitions $partitions --topic $topic_name" || true
}

# topics with partitions and expected producer compression
create_topic "ten-partitions-lz4" 10
create_topic "ten-partitions-snappy" 10
create_topic "ten-partitions-none" 10

docker_kafka_exec "kafka-topics.sh --describe --zookeeper $ZOOKEEPER_HOST_PORT"
