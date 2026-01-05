#!/bin/sh

# ================================
# 默认环境变量（可被外部覆盖）
# ================================
SECRET=${SECRET:-"7mGTeoIU5qRH_arNqG_Q405henVyZS5taWNyb3NvZnQuY29t"}
PORT=${PORT:-443}
DOH_IP=${DOH_IP:-"8.8.8.8"}

# ================================
# 自动获取服务器 IP（优先 IPv4）
# ================================
SERVER_IP=$(wget -qO- https://api.ipify.org || echo "127.0.0.1")

# ================================
# 生成完整 config.toml
# ================================
cat <<EOF > /config.toml
debug = false
secret = "${SECRET}"
bind-to = "0.0.0.0:${PORT}"
concurrency = 8192
prefer-ip = "prefer-ipv4"
domain-fronting-port = 443
tolerate-time-skewness = "5s"
allow-fallback-on-unknown-dc = false

[network]
doh-ip = "${DOH_IP}"
proxies = [
]

[network.timeout]
tcp = "5s"
http = "10s"
idle = "1m"

[defense.anti-replay]
enabled = true
max-size = "1mib"
error-rate = 0.001

[defense.blocklist]
enabled = true
download-concurrency = 2
urls = [
    "https://iplists.firehol.org/files/firehol_level1.netset",
]
update-each = "24h"

[defense.allowlist]
enabled = false
download-concurrency = 2
urls = [
]
update-each = "24h"

[stats.statsd]
enabled = false
address = "127.0.0.1:8888"
metric-prefix = "mtg"
tag-format = "datadog"

[stats.prometheus]
enabled = true
bind-to = "127.0.0.1:3129"
http-path = "/"
metric-prefix = "mtg"
EOF

# ================================
# 输出 TG 代理链接
# ================================
echo "=============================================="
echo " MTProto Proxy is running"
echo " Server: ${SERVER_IP}"
echo " Port:   ${PORT}"
echo " Secret: ${SECRET}"
echo ""
echo " TG Proxy Link:"
echo " tg://proxy?server=${SERVER_IP}&port=${PORT}&secret=${SECRET}"
echo "=============================================="

# ================================
# 启动 mtg
# ================================
exec /mtg "$@"
