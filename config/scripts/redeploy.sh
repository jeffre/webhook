#!/bin/bash
set -euo pipefail

COMMIT="$1"
USERNAME="$2"
USEREMAIL="$3"
REPONAME="$4"

cd "$REPONAME"
git pull
docker compose up --build -d --remove-orphans
docker image prune -f
