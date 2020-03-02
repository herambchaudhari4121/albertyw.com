#!/bin/bash

# This script will build and deploy a new docker image

set -exuo pipefail
IFS=$'\n\t'

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd "$DIR"/..

CONTAINER="albertyw"
PORT="5000"
NETWORK="$CONTAINER"_net
DEPLOY_BRANCH="${1:-}"
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
set +x  # Do not print contents of .env
source .env
set -x

if [ -n "$DEPLOY_BRANCH" ]; then
    # Update repository
    git checkout "$DEPLOY_BRANCH"
    git fetch -tp
    git pull
fi

# Build container and network
docker pull "$(grep FROM Dockerfile | awk '{print $2}')"
docker build -t "$CONTAINER:$BRANCH" .
docker network inspect "$NETWORK" &>/dev/null ||
    docker network create --driver bridge "$NETWORK"

# Start container
docker stop "$CONTAINER" || true
docker container rm "$CONTAINER" || true
docker run \
    --detach \
    --restart=always \
    --publish="127.0.0.1:$PORT:$PORT" \
    --network="$NETWORK" \
    --mount type=bind,source="$(pwd)"/app/static,target=/var/www/app/app/static \
    --mount type=bind,source="$(pwd)"/logs,target=/var/www/app/logs \
    --name="$CONTAINER" "$CONTAINER:$BRANCH"

if [ "$ENV" = "production" ] && [ "$BRANCH" = "master" ]; then
    # Cleanup docker
    docker container prune --force --filter "until=168h"
    docker image prune --force --filter "until=168h"
    docker volume prune --force
    docker network prune --force

    # Update nginx
    sudo service nginx reload
fi
