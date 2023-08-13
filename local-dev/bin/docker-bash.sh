#! /usr/bin/env bash

set -euo pipefail

export KAFKA_CONTAINER="${KAFKA_CONTAINER:-ESQUE_KAFKA}"

set -x
docker exec -it "$KAFKA_CONTAINER" "/bin/bash"
{ set +x; } 2>/dev/null

