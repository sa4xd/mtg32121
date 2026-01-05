#!/bin/sh

# ================================
# 默认环境变量（可被外部覆盖）
# ================================
SECRET=${SECRET:-"ee00000000000000000000000000000000000000000000000000000000000000"}
PORT=${PORT:-443}
DOH_IP=${DOH_IP:-"8.8.8.8"}

# ================================
# 生成完整 config.toml
# ================================
cat <<EOF > /config.toml
###############################################################################
# mtg 完整配置模板（可生产使用）
###############################################################################

debug = false
secret = "${SECRET}"
bind-to = "0.0.0.0:${PORT}"
concurrency = 8192
prefer-ip = "prefer-ipv4"
domain-fronting-port = 443
tolerate-time-skewness = "5s"
allow-fallback-on-unknown-dc = false

###############################################################################
# Network 配置
###############################################################################
[network]
doh-ip = "${DOH_IP}"
proxies = [
]

[network.timeout]
tcp = "5s"
http = "10s"
idle = "1m"

###############################################################################
# 防御（Anti-Replay / Blocklist / Allowlist）
###############################################################################
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

###############################################################################
# Metrics（StatsD / Prometheus）
###############################################################################
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
# 启动 mtg
# ================================
exec /mtg "$@"
