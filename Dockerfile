###############################################################################
# BUILD STAGE

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

###############################################################################
# PACKAGE STAGE

FROM alpine:latest

RUN apk --no-cache add busybox-extras

COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build /app/mtg /mtg
COPY --from=build /app/example.config.toml /config.toml

# 创建简单的静态HTML页面
RUN echo '<html><body><h1>MTG Proxy Server</h1><p>Static Blog Page</p></body></html>' > /index.html

# 创建启动脚本
RUN echo '#!/bin/sh' > /start.sh && \
    echo 'httpd -p 3000 -h / &' >> /start.sh && \
    echo '/mtg run /config.toml' >> /start.sh && \
    chmod +x /start.sh

EXPOSE 3128 3000

ENTRYPOINT ["/start.sh"]
