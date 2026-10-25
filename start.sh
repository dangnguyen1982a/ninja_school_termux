#!/data/data/com.termux/files/usr/bin/bash
set -e

BASE="$(cd "$(dirname "$0")" && pwd)"
NsoC="$BASE/NsoC"
WEB="$BASE/web"

clear

echo "=========================================="
echo "          NINJA SCHOOL V2"
echo "=========================================="
echo

echo "[1] Kiểm tra MariaDB..."

if ! mariadb -h 127.0.0.1 -P 3306 -u root -e "SELECT 1;" >/dev/null 2>&1; then
    echo "MariaDB chưa chạy. Đang khởi động..."

    mariadbd-safe >/dev/null 2>&1 &

    echo "Đang chờ MariaDB..."

    for i in {1..30}; do
        if mariadb -h 127.0.0.1 -P 3306 -u root -e "SELECT 1;" >/dev/null 2>&1; then
            echo "MariaDB đã sẵn sàng."
            break
        fi
        sleep 1
    done

    if ! mariadb -h 127.0.0.1 -P 3306 -u root -e "SELECT 1;" >/dev/null 2>&1; then
        echo "LỖI: Không thể khởi động MariaDB."
        exit 1
    fi
else
    echo "MariaDB đang chạy."
fi

echo
echo "[2] Kiểm tra database..."

mariadb -h 127.0.0.1 -P 3306 -u root \
    -e "USE aov; SELECT 1;" >/dev/null

echo "Database aov: OK."

echo
echo "[3] Khởi động Admin Panel..."

if ! pgrep -f "php.*127.0.0.1:8080" >/dev/null 2>&1; then
    php \
        -d opcache.enable=0 \
        -d opcache.enable_cli=0 \
        -S 127.0.0.1:8080 \
        -t "$WEB" \
        > "$BASE/panel.log" 2>&1 &

    sleep 1
fi

echo "Panel: http://127.0.0.1:8080"

echo
echo "[4] Khởi động Ninja School Server..."
echo

cd "$NsoC"

exec java -cp "dist/Monter.jar:lib/*" server.NinjaSchool
