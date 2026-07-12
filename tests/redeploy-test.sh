#!/bin/bash

cd "$(dirname "$0")"
pwd
source ../.env

WEBHOOK_URL="${WEBHOOK_SCHEMA:-http}://${WEBHOOK_HOST:-localhost:9000}"
HMAC=${REDEPLOY_HMAC:-foobar}

BODY='{
  "head_commit": {
    "id": "01abcdef"
  },
  "pusher": {
    "email": "user@example.com",
    "name": "Example User"
  },
  "ref": "refs/heads/main",
  "repository": {
    "full_name": "owner/repo",
    "name": "repo"
  }
}
'

SIG=$(printf '%s' "${BODY}" | openssl dgst -sha256 -hmac "${HMAC}" | sed 's/^.* //')

curl -X POST \
  --header "Content-Type: application/json" \
  --header "X-Hub-Signature-256: sha256=$SIG" \
  -d "${BODY}" \
  --url "${WEBHOOK_URL}/hooks/redeploy"
