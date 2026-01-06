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

RUN apk --no-cache add busybox-extras wget

# -------------------------
# 安装 cloudflared（官方二进制）
# -------------------------
RUN wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
    -O /usr/local/bin/cloudflared && \
    chmod +x /usr/local/bin/cloudflared

COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build /app/mtg /mtg
COPY --from=build /app/example.config.toml /config.toml

# 创建简单的静态HTML页面
RUN echo '<html><body><h1>Blog</h1><p>Blog Page</p></body></html>' > /index.html

# -------------------------
# 环境变量（可 docker run 覆盖）
# -------------------------
ENV CFTUN_HOSTNAME="" 
    
ENV CFTUN_TOKEN=""

# -------------------------
# 创建启动脚本
# -------------------------
RUN echo '#!/bin/sh' > /start.sh && \
    echo 'httpd -p 3000 -h / &' >> /start.sh && \
    echo 'echo "启动 cloudflared TCP 隧道..."' >> /start.sh && \
    echo 'cloudflared tunnel --url tcp://127.0.0.1:3128 --hostname "$CFTUN_HOSTNAME" --token "$CFTUN_TOKEN" &' >> /start.sh && \
    echo 'echo "启动 mtg..."' >> /start.sh && \
    echo '/mtg run /config.toml' >> /start.sh && \
    chmod +x /start.sh

EXPOSE 3128 3000

ENTRYPOINT ["/start.sh"]
