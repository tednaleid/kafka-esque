#!/bin/bash

set -euo pipefail

BASE_DIR=$(dirname "$0")
CERT_DIR=$BASE_DIR/../certs

echo "stopping existing containers"
cd $BASE_DIR/..
docker-compose stop

echo "removing all docker containers"
docker container prune -f

if [[ -d $CERT_DIR ]]; then
    echo "removing generated certs directory"
    rm -r $CERT_DIR
fi
