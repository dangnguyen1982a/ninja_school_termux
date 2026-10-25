#!/data/data/com.termux/files/usr/bin/bash
set -e

BASE="$(cd "$(dirname "$0")/.." && pwd)"
DB="aov"
DATA_DIR="$PREFIX/var/lib/mysql"

echo "[DB 1/4] Kiểm tra MariaDB..."

if ! mariadb -uroot -Nse "SELECT 1" >/dev/null 2>&1; then
    if ! mariadb -h 127.0.0.1 -P 3306 -uroot -Nse "SELECT 1" >/dev/null 2>&1; then
        if [ ! -d "$DATA_DIR/mysql" ]; then
            echo "Khởi tạo dữ liệu MariaDB lần đầu..."
            mariadb-install-db --datadir="$DATA_DIR" \
                --auth-root-authentication-method=normal
        fi

        mariadbd-safe --datadir="$DATA_DIR" >/dev/null 2>&1 &

        ready=0
        for i in $(seq 1 30); do
            if mariadb -uroot -Nse "SELECT 1" >/dev/null 2>&1; then
                ready=1
                break
            fi
            sleep 1
        done

        if [ "$ready" -ne 1 ]; then
            echo "LỖI: MariaDB chưa khởi động được."
            exit 1
        fi
    fi
fi

echo "[DB 2/4] Kiểm tra database $DB..."

exists="$(mariadb -uroot -Nse \
    "SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name='$DB'")"

if [ "$exists" = "0" ]; then
    if [ ! -f "$BASE/database/nso.sql" ]; then
        echo "LỖI: Không tìm thấy database/nso.sql"
        exit 1
    fi

    echo "Tạo database mới và nhập SQL gốc..."
    mariadb -uroot -e \
        "CREATE DATABASE \`$DB\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"

    # Dump cũ có câu lệnh UPDATE bảng alert trước khi bảng này tồn tại.
    # --force cho phép tiếp tục nhập các câu lệnh còn lại.
    mariadb --force -uroot "$DB" < "$BASE/database/nso.sql" \
        > "$BASE/database/import-aov.log" 2>&1 || true
else
    echo "Database $DB đã tồn tại; giữ nguyên dữ liệu hiện có."
fi

echo "[DB 3/4] Kiểm tra bảng cốt lõi..."
for table in ninja npc map item; do
    count="$(mariadb -uroot -Nse \
        "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DB' AND table_name='$table'")"
    if [ "$count" = "0" ]; then
        echo "LỖI: Thiếu bảng $DB.$table sau khi nhập SQL."
        echo "Xem log: $BASE/database/import-aov.log"
        exit 1
    fi
done

echo "[DB 4/4] Áp dụng bản vá..."
bash "$BASE/database/repair-aov.sh"

echo "Hoàn tất thiết lập database $DB."
