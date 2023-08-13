#!/bin/bash

set -euo pipefail

BASE_DIR=$(dirname "$0")

echo "stopping existing containers"
cd $BASE_DIR/..
docker-compose stop

echo "removing all docker containers"
docker container prune -f

