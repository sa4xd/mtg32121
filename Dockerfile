###############################################################################
# BUILD STAGE (Debian, because cftun requires glibc + Go >= 1.20)
###############################################################################
FROM golang:1.20-bullseye AS build

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    make \
    bash \
    curl

# -------------------------
# 构建 mtg（你的原逻辑）
# -------------------------
COPY . /app
WORKDIR /app
RUN make -j 4 static

# -------------------------
# 构建 cftun（修复 go.mod 缺失）
# -------------------------
RUN git clone https://github.com/fmnx/cftun.git /app/cftun-src

WORKDIR /app/cftun-src

# cftun 仓库缺少 go.mod → 自动生成
RUN go mod init cftun && \
    go mod tidy

# 构建 cftun
RUN go build -o /usr/local/bin/cftun .


###############################################################################
# PACKAGE STAGE (Alpine runtime)
###############################################################################
FROM alpine:latest

RUN apk --no-cache add busybox-extras

COPY --from=build /usr/local/bin/cftun /usr/local/bin/cftun
COPY --from=build /app/mtg /mtg
COPY --from=build /app/example.config.toml /config.toml
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

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
    echo 'printf "tunnels:\n  - hostname: %s\n    service: tcp://127.0.0.1:%s\n    protocol: %s\n" "$CFTUN_HOSTNAME" "$CFTUN_PORT" "$CFTUN_PROTOCOL" > /cftun.yaml' >> /start.sh && \
    echo 'cftun --config /cftun.yaml --token "$CFTUN_TOKEN" &' >> /start.sh && \
    echo '/mtg run /config.toml' >> /start.sh && \
    chmod +x /start.sh

EXPOSE 3128 3000

ENTRYPOINT ["/start.sh"]
