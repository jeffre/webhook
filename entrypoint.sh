#!/bin/bash
set -e

DOCKER_GID=$(stat -c '%g' /var/run/docker.sock 2>/dev/null || echo 0)

if [ "$DOCKER_GID" != "0" ]; then
    if ! getent group "$DOCKER_GID" > /dev/null 2>&1; then
        addgroup -g "$DOCKER_GID" docker-host
    fi
    DOCKER_GROUP=$(getent group "$DOCKER_GID" | cut -d: -f1)
    adduser webhook "$DOCKER_GROUP" 2>/dev/null || true
fi

exec su-exec webhook env HOME=/home/webhook "$@"
