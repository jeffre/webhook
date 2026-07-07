# webhook

A lightweight Docker container that listens for GitHub push events and automatically redeploys your Docker Compose projects.

When a push to `main` arrives with a valid HMAC signature, the container runs `git pull` and `docker compose up --build -d` in the matching project directory.

## How it works

1. GitHub sends a webhook `POST` to `/hooks/redeploy`
2. The payload is validated against an HMAC-SHA256 signature (`X-Hub-Signature-256`)
3. On success, `config/scripts/redeploy.sh` runs `git pull` and rebuilds the stack in `$WEBHOOK_WORKDIR/<repo-name>`

Built on [adnanh/webhook](https://github.com/adnanh/webhook).

## Setup

### 1. Clone and configure

```bash
git clone https://github.com/jguymon/webhook.git
cd webhook
cp .env.example .env   # then fill in values
```

### 2. Edit `.env`

```env
REDEPLOY_HMAC=your-secret-here         # shared secret for GitHub webhook HMAC validation
WEBHOOK_SCHEMA=https                   # http or https (used by the test script)
WEBHOOK_HOST=webhook.example.com       # hostname served by your reverse proxy
WEBHOOK_WORKDIR=/home/user/code        # parent directory of your repo(s)
```

### 3. Lay out your projects

Each repo you want to auto-deploy must be checked out under `WEBHOOK_WORKDIR`, with the directory name matching the GitHub repository name:

```
/home/user/code
  my-app/
  another-service/
```

`WEBHOOK_WORKDIR` is bind-mounted into the container at the same path, so paths resolve identically inside and outside.

The container user (`webhook`) needs SSH credentials for `git pull`. Your host's `$HOME/.ssh` is mounted read-only into the container — make sure it has a key authorized for your repos.

### 4. Start

```bash
docker compose up --build -d
```

### 5. Configure GitHub

In your repo's **Settings → Webhooks**, add a webhook:

- **Payload URL:** `https://webhook.example.com/hooks/redeploy`
- **Content type:** `application/json`
- **Secret:** the value of `REDEPLOY_HMAC`
- **Events:** Just the push event

## Reverse proxy (optional)

Consider creating a `docker-compose.override.yml` to wire up your own reverse proxy without touching the base compose file. Example for Traefik:

```yaml
services:
  webhook:
    labels:
      traefik.enable: true
      traefik.http.routers.webhook.entrypoints: https-wan
      traefik.http.routers.webhook.rule: "Host(`${WEBHOOK_HOST}`)"
    networks:
      - traefik-net

networks:
  traefik-net:
    external: true
```

## Testing

With the container running and `.env` populated, fire a test payload:

```bash
./tests/redeploy-test.sh
```

This signs a synthetic GitHub push payload with your HMAC secret and posts it to the webhook endpoint.

## Security notes

- All incoming payloads are rejected unless the `X-Hub-Signature-256` header matches the shared secret — only GitHub (or someone with your secret) can trigger a deploy
- The process inside the container runs as a non-root `webhook` user
- `$HOME/.ssh` is mounted read-only
- Mounting `/var/run/docker.sock` gives the container root-equivalent access on the host — standard for CD webhooks, but scope your deployment accordingly
