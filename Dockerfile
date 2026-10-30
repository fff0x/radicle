# syntax=docker/dockerfile:1
# Dockerfile version: 0.0.23

##
## MAIN
##

FROM alpine:3.22.7

##
## VARIABLES
##

ARG CAT=radicle
ARG APP=node
ARG APP_VERSION=0.0.13
ARG APP_DESCRIPTION="Radicle (seed|client) node"
# ------------------
ARG RADICLE_VERSION=1.10.3
ARG RADICLE_HTTPD_VERSION=0.30.0
# sha256sum of radicle-httpd-${RADICLE_HTTPD_VERSION}-<ENV>-unknown-linux-musl.tar.xz
ARG RADICLE_HTTPD_SHA256_X86_64=dd16f6f966e62fafee5a6547d1e31c8857c607c5d955380872c9e7a06500285f
ARG RADICLE_HTTPD_SHA256_AARCH64=ab6ab9f073f9ebc58b3132f9686b65d882250dc434fb4fea32806481f665dd80

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
  && case "$TARGETARCH" in \
       amd64) ENV="x86_64";   HTTPD_SHA256="$RADICLE_HTTPD_SHA256_X86_64" ;; \
       arm64) ENV="aarch64";  HTTPD_SHA256="$RADICLE_HTTPD_SHA256_AARCH64" ;; \
       *) echo "unsupported TARGETARCH=$TARGETARCH" >&2; exit 1 ;; \
     esac \
  && curl -fsS -L -o /tmp/httpd.tar.xz \
       "https://files.radicle.dev/releases/radicle-httpd/${RADICLE_HTTPD_VERSION}/radicle-httpd-${RADICLE_HTTPD_VERSION}-${ENV}-unknown-linux-musl.tar.xz" \
  && test "$(sha256sum /tmp/httpd.tar.xz | cut -d' ' -f1)" = "$HTTPD_SHA256" \
  && tar -xJf /tmp/httpd.tar.xz -C /usr/local --strip-components=1 \
  && rm -f /tmp/httpd.tar.xz \
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
