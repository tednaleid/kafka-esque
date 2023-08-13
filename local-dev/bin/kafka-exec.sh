#! /usr/bin/env bash

set -euo pipefail

export KAFKA_CONTAINER="${KAFKA_CONTAINER:-esque-kafka}"

function docker_kafka_exec() {
  set -x
  docker exec "$KAFKA_CONTAINER" /bin/bash -c "$*"
  { set +x; } 2>/dev/null
}

if [ "$#" -eq 0 ]; then
  docker_kafka_exec "ls /opt/kafka/bin/*.sh"
else
  docker_kafka_exec "$*"
fi
