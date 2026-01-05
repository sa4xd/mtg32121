#!/bin/sh

SECRET=${SECRET:-"7i62-DSE3Au7X5wAwB9T9NVhenVyZS5taWNyb3NvZnQuY29t"}
PORT=${PORT:-443}

cat <<EOF > /config.toml
debug = false
secret = "${SECRET}"
bindTo = "0.0.0.0:${PORT}"

[network]
doh-ip = "8.8.8.8"
EOF

exec /mtg "$@"
