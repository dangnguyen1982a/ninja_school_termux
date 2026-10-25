#!/data/data/com.termux/files/usr/bin/bash

BASE="$(cd "$(dirname "$0")" && pwd)"
PANEL="$BASE/web"

clear
echo "=========================================="
echo "              NSO VIP PANEL"
echo "=========================================="
echo
echo "Panel: http://127.0.0.1:8080"
echo "Database: aov"
echo
echo "Đang khởi động..."
echo

cd "$HOME" || exit 1

exec php \
  -d opcache.enable=0 \
  -d opcache.enable_cli=0 \
  -S 127.0.0.1:8080 \
  -t "$PANEL"
