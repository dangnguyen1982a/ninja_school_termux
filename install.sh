#!/data/data/com.termux/files/usr/bin/bash
set -e

BASE="$HOME/ninja-school-v2-final"
NsoC="$BASE/NsoC"
WEB="$BASE/web"

echo "=========================================="
echo "        NINJA SCHOOL V2 - INSTALL"
echo "=========================================="

if [ ! -d "$BASE" ]; then
    echo "LỖI: Không tìm thấy $BASE"
    exit 1
fi

echo "[1] Cài dependency..."
pkg update -y
pkg install -y git ant openjdk-21 mariadb php

echo "[2] Kiểm tra NsoC..."

if [ ! -f "$NsoC/build.xml" ]; then
    echo "LỖI: Không tìm thấy NsoC/build.xml"
    exit 1
fi

echo "[3] Build NsoC..."
cd "$NsoC"
ant clean jar

if [ ! -f "$NsoC/dist/Monter.jar" ]; then
    echo "LỖI: Không tạo được Monter.jar"
    exit 1
fi

echo "[4] Kiểm tra Panel..."

if [ ! -f "$WEB/index.php" ]; then
    echo "LỖI: Không tìm thấy web/index.php"
    exit 1
fi

echo "[5] Kiểm tra script sửa database..."
if [ ! -f "$BASE/database/repair-aov.sh" ]; then
    echo "LỖI: Thiếu database/repair-aov.sh"
    exit 1
fi
chmod +x "$BASE/database/repair-aov.sh"
echo "Đã chuẩn bị script sửa database."
echo "Lưu ý: chạy script này sau khi MariaDB đã chạy và database aov đã được nhập:"
echo "  bash $BASE/database/repair-aov.sh"

if [ ! -f "$BASE/start-ninja.sh" ]; then
    echo "LỖI: Thiếu start-ninja.sh; hãy khôi phục file khởi động."
    exit 1
fi

echo
echo "=========================================="
echo "       CÀI ĐẶT HOÀN TẤT"
echo "=========================================="
echo
echo "Server + Panel:"
echo "  bash ~/ninja-school-v2-final/start-ninja.sh"
echo
echo "Panel:"
echo "  http://127.0.0.1:8080"
