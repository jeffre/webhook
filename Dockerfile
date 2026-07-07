FROM alpine:3.23
ARG WEBHOOK_VER=2.8.3
ARG RUN_UID=1000

RUN apk add --no-cache \
    bash \
    docker-cli \
    docker-cli-compose \
    git \
    openssh-client \
    su-exec

RUN wget -qO- https://github.com/adnanh/webhook/releases/download/$WEBHOOK_VER/webhook-linux-amd64.tar.gz \
    | tar -xz --strip-components=1 -C /usr/local/bin/

RUN adduser -D -u ${RUN_UID} webhook

WORKDIR ${WEBHOOK_WORKDIR:-/}

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

EXPOSE 9000

ENTRYPOINT ["entrypoint.sh"]
CMD ["webhook", "-hooks=/config/hooks.yaml", "-template", "-verbose", "-hotreload"]
