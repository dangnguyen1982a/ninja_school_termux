import struct, json

src = "NsoC/res/cache/data/nj_effect"
out = "nj_effect_import.sql"

with open(src, "rb") as f:
    data = f.read()

if len(data) < 2:
    raise SystemExit("Loi: File du lieu qua ngan")

count = struct.unpack_from(">H", data, 0)[0]
pos = 2
rows = []

for n in range(count):
    if pos + 3 > len(data):
        raise SystemExit(f"Loi: Thieu ban ghi {n}")

    eid, num = struct.unpack_from(">HB", data, pos)
    pos += 3
    info = []

    for j in range(num):
        if pos + 4 > len(data):
            raise SystemExit(f"Loi: Thieu chi tiet hieu ung {n}")

        img, dx, dy = struct.unpack_from(">Hbb", data, pos)
        pos += 4
        info.append({"imgId": img, "dx": dx, "dy": dy})

    rows.append((eid, json.dumps(info, separators=(",", ":"))))

if pos != len(data):
    raise SystemExit(f"Loi: Da doc {pos}/{len(data)} byte")

with open(out, "w", encoding="utf-8") as f:
    f.write("CREATE TABLE IF NOT EXISTS `nj_effect` ("
            "`id` SMALLINT NOT NULL PRIMARY KEY, "
            "`info` LONGTEXT NOT NULL"
            ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;\n")
    f.write("DELETE FROM `nj_effect`;\n")
    for eid, info in rows:
        info = info.replace("\\", "\\\\").replace("'", "\\'")
        f.write(
            "INSERT INTO `nj_effect` (`id`,`info`) "
            f"VALUES ({eid},'{info}');\n"
        )

print("Kiem tra thanh cong")
print("So hieu ung:", count)
print("So byte:", len(data))
print("Da tao:", out)
