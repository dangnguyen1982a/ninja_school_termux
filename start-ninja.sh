#!/data/data/com.termux/files/usr/bin/bash
set -e

BASE="$(cd "$(dirname "$0")" && pwd)"
NsoC="$BASE/NsoC"
WEB="$BASE/web"

echo "=========================================="
echo "          NINJA SCHOOL V2"
echo "=========================================="

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

echo "[2] Kiểm tra database..."

mariadb -h 127.0.0.1 -P 3306 -u root \
    -e "USE aov; SELECT 1;" >/dev/null

echo "Database OK."

echo "[3] Khởi động Panel..."

php -d opcache.enable=0 \
    -d opcache.enable_cli=0 \
    -S 127.0.0.1:8080 \
    -t "$WEB" \
    > "$BASE/panel.log" 2>&1 &

echo "Panel: http://127.0.0.1:8080"

echo "[4] Khởi động NsoC..."

cd "$NsoC"

exec java -cp "dist/Monter.jar:lib/*" server.NinjaSchool
