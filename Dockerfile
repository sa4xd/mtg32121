###############################################################################
# BUILD STAGE
###############################################################################
FROM golang:1.19-bullseye AS build


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

# -------------------------
# 构建 cftun
# -------------------------
RUN git clone https://github.com/fmnx/cftun.git /app/cftun-src \
    && cd /app/cftun-src \
    && go build -o /usr/local/bin/cftun .


###############################################################################
# PACKAGE STAGE
###############################################################################
FROM alpine:latest

RUN apk --no-cache add busybox-extras

COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build /app/mtg /mtg
COPY --from=build /app/example.config.toml /config.toml
COPY --from=build /usr/local/bin/cftun /usr/local/bin/cftun

# -------------------------
# 环境变量（可 docker run 覆盖）
# -------------------------
ENV CFTUN_PORT=3128 \
    CFTUN_PROTOCOL=tcp \
    CFTUN_HOSTNAME="" \
    CFTUN_TOKEN=""

# -------------------------
# 静态博客
# -------------------------
RUN echo '<html><body><h1>Blog</h1><p>Blog Page</p></body></html>' > /index.html

# -------------------------
# 启动脚本：httpd + cftun + mtg
# -------------------------
RUN echo '#!/bin/sh' > /start.sh && \
    echo 'httpd -p 3000 -h / &' >> /start.sh && \
    echo 'echo "生成 cftun 配置..."' >> /start.sh && \
    echo 'printf "tunnels:\n  - hostname: %s\n    service: tcp://127.0.0.1:%s\n    protocol: %s\n" "$CFTUN_HOSTNAME" "$CFTUN_PORT" "$CFTUN_PROTOCOL" > /cftun.yaml' >> /start.sh && \
    echo 'echo "启动 cftun..."' >> /start.sh && \
    echo 'cftun --config /cftun.yaml --token "$CFTUN_TOKEN" &' >> /start.sh && \
    echo 'echo "启动 mtg..."' >> /start.sh && \
    echo '/mtg run /config.toml' >> /start.sh && \
    chmod +x /start.sh

EXPOSE 3128 3000

ENTRYPOINT ["/start.sh"]
