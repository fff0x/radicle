# syntax=docker/dockerfile:1
# Dockerfile version: 0.0.21

##
## MAIN
##

FROM alpine:3.22.4

##
## VARIABLES
##

ARG CAT=radicle
ARG APP=node
ARG APP_VERSION=0.0.13
ARG APP_DESCRIPTION="Radicle (seed|client) node"
# ------------------
ARG RADICLE_VERSION=1.10.3
ARG RADICLE_HTTPD_VERSION=0.29.0

LABEL \
  org.opencontainers.image.vendor="this-is-fine" \
  org.opencontainers.image.url="https://this-is-fine.io" \
  org.opencontainers.image.authors="Max Reineke <ff0x@this-is-fine.io>" \
  org.opencontainers.image.title="${CAT}-${APP}" \
  org.opencontainers.image.version="${APP_VERSION}" \
  org.opencontainers.image.description="$APP_DESCRIPTION" \
  org.opencontainers.image.source="https://radicle.network/nodes/seed.this-is-fine.io/rad:z6swfznxYAgUd7kdNCKbvCYwzEtu" 

# Shameless ripped of <https://app.radicle.xyz/nodes/seed.radicle.garden/rad:zNd4qti1Jc69mCBQAdBeK3Avzy4R>

##
## CONFIGURATION
##

ARG CAT_GID=10001
ARG APP_UID=10001
ARG TARGETARCH

##
## PREPARATION
##

USER root

# GENERIC

COPY --chmod=755 ep /ep

RUN \
  addgroup -S -g "$CAT_GID" "$CAT" \
  && adduser -S -u "$APP_UID" -G "$CAT" -h "/${APP}" -s /sbin/nologin -D "$APP"

RUN \
  apk upgrade --update --no-cache \
  && apk add --no-cache tzdata \
  && rm -rf /tmp/* /var/cache/apk/* /etc/localtime \
  && ln -sf /usr/share/zoneinfo/UTC /etc/localtime

# APP

RUN \
  apk add --update --no-cache check-jsonschema curl git git-daemon jq openssh xz \
  && curl -sSf https://radicle.dev/install | sh -s -- --no-modify-path --version="$RADICLE_VERSION" --prefix="/usr/local" \
  && if [[ "$TARGETARCH" == 'amd64' ]]; then ENV="x86_64"; elif [[ "$TARGETARCH" == 'arm64' ]]; then ENV="aarch64"; else ENV="$TARGETARCH"; fi \
  && curl -s -L "https://files.radicle.dev/releases/radicle-httpd/${RADICLE_HTTPD_VERSION}/radicle-httpd-${RADICLE_HTTPD_VERSION}-${ENV}-unknown-linux-musl.tar.xz" \
  | tar --strip-components=1 -xJ -C /usr/local \
  && mkdir -p "/${APP}/radicle" && chown -R "$APP":"$CAT" "/${APP}"

##
## ENVIRONMENT
##

USER "$APP"
WORKDIR "/${APP}"
VOLUME [ "/${APP}/radicle" ]
ENV RAD_HOME="/${APP}/radicle"

##
## PORTS
##

EXPOSE 8080
EXPOSE 8776

##
## INIT
##

ENTRYPOINT [ "/ep" ]
