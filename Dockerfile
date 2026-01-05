###############################################################################
# BUILD STAGE
###############################################################################

FROM golang:1.19-alpine AS build

RUN set -x \
  && apk --no-cache --update add \
    bash \
    ca-certificates \
    curl \
    git \
    make

COPY . /app
WORKDIR /app

RUN set -x \
  && make -j 4 static

# 关键：在 build 阶段复制 entrypoint.sh 并赋予执行权限
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh


###############################################################################
# PACKAGE STAGE
###############################################################################

FROM scratch

# 直接复制已经有执行权限的 entrypoint.sh
COPY --from=build /entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["run", "/config.toml"]

COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build /app/mtg /mtg
