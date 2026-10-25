#!/data/data/com.termux/files/usr/bin/bash
set -e
BASE="$(cd "$(dirname "$0")/.." && pwd)"

DB="${DB:-aov}"

if ! mariadb -uroot -Nse "SELECT 1" >/dev/null 2>&1; then
    echo "LỖI: MariaDB chưa chạy."
    exit 1
fi

if ! mariadb -uroot -Nse "SHOW DATABASES LIKE '$DB'" | grep -qx "$DB"; then
    echo "LỖI: Chưa có database $DB. Hãy nhập database gốc trước."
    exit 1
fi

sql() {
    mariadb -uroot "$DB" -e "$1"
}

has_table() {
    [ "$(mariadb -uroot -Nse \
      "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DB' AND table_name='$1'")" != "0" ]
}

has_col() {
    [ "$(mariadb -uroot -Nse \
      "SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='$DB' AND table_name='$1' AND column_name='$2'")" != "0" ]
}

rename_col() {
    local table="$1" old="$2" new="$3"
    if has_table "$table" && has_col "$table" "$old" && ! has_col "$table" "$new"; then
        sql "ALTER TABLE \`$table\` RENAME COLUMN \`$old\` TO \`$new\`"
        echo "Đã đổi $table.$old -> $new"
    fi
}

echo "[1/5] Sửa tên bảng và cột..."

if has_table Mob && ! has_table mob; then
    sql 'RENAME TABLE `Mob` TO `mob`'
fi

if has_table ItemSell && ! has_table itemsell; then
    sql 'RENAME TABLE `ItemSell` TO `itemsell`'
fi

rename_col npc head headId
rename_col npc body bodyId
rename_col npc leg legId
rename_col map tileID tile
rename_col map bgID backid
rename_col map typeMap type
rename_col item isUpToUp uptoup

echo "[2/5] Bổ sung cột còn thiếu..."

if has_table npc && ! has_col npc menu; then
    sql "ALTER TABLE npc ADD COLUMN menu TEXT DEFAULT '[]'"
fi

if has_table map && ! has_col map itemcay; then
    sql "ALTER TABLE map ADD COLUMN itemcay TEXT NOT NULL DEFAULT '[]'"
fi

if has_table ninja; then
    for col in eventPoint vip diemnap PointMax; do
        if ! has_col ninja "$col"; then
            sql "ALTER TABLE ninja ADD COLUMN \`$col\` INT NOT NULL DEFAULT 0"
        fi
    done
fi

echo "[3/5] Tạo các bảng còn thiếu..."

sql "CREATE TABLE IF NOT EXISTS alert (
    content TEXT NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"

if [ "$(mariadb -uroot -Nse "SELECT COUNT(*) FROM ${DB}.alert")" = "0" ]; then
    sql "INSERT INTO alert (content) VALUES ('Chào mừng đến với Ninja School V2!')"
fi

sql "CREATE TABLE IF NOT EXISTS thiendia (
    id INT NOT NULL AUTO_INCREMENT,
    week VARCHAR(50) NOT NULL,
    type INT NOT NULL,
    data LONGTEXT DEFAULT NULL,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"

sql "UPDATE thiendia SET data='[]' WHERE data IS NULL"

sql "CREATE TABLE IF NOT EXISTS shinwa (
    id INT NOT NULL PRIMARY KEY,
    data LONGTEXT NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"

sql "INSERT IGNORE INTO shinwa (id,data) VALUES
(-1,'[]'),(0,'[]'),(1,'[]'),(2,'[]'),(3,'[]'),(4,'[]'),
(5,'[]'),(6,'[]'),(7,'[]'),(8,'[]'),(9,'[]'),(10,'[]'),(11,'[]')"

sql "CREATE TABLE IF NOT EXISTS xep_hang_level (
    id INT NOT NULL AUTO_INCREMENT,
    ninja_id INT NOT NULL,
    name VARCHAR(40) NOT NULL,
    level INT NOT NULL DEFAULT 1,
    \`class\` VARCHAR(50) NOT NULL DEFAULT '',
    \`time\` VARCHAR(50) NOT NULL DEFAULT '',
    PRIMARY KEY (id),
    KEY idx_ninja_id (ninja_id),
    KEY idx_level (level)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"

echo "[4/5] Nạp dữ liệu nj_* nếu bảng chưa có dữ liệu..."

for table in nj_arrow nj_part nj_image nj_effect nj_skill; do
    file="$BASE/database/${table}_import.sql"
    if [ -f "$file" ]; then
        count="$(mariadb -uroot -Nse \
          "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DB' AND table_name='$table'")"
        if [ "$count" = "0" ]; then
            mariadb -uroot "$DB" < "$file"
        else
            rows="$(mariadb -uroot -Nse "SELECT COUNT(*) FROM \`$DB\`.\`$table\`")"
            if [ "$rows" = "0" ]; then
                mariadb -uroot "$DB" < "$file"
            fi
        fi
    fi
done

echo "[5/5] Hoàn tất sửa database $DB."
