import struct, json

src = "NsoC/res/cache/data/nj_skill"
out = "nj_skill_import.sql"

with open(src, "rb") as f:
    data = f.read()

if len(data) < 2:
    raise SystemExit("Loi: File nj_skill qua ngan")

count = struct.unpack_from(">H", data, 0)[0]
pos = 2
rows = []

def read_info():
    global pos
    if pos + 1 > len(data):
        raise ValueError("Thieu so luong SkillInfoPaint")
    num = data[pos]
    pos += 1
    arr = []

    keys = [
        "status", "effS0Id", "e0dx", "e0dy",
        "effS1Id", "e1dx", "e1dy",
        "effS2Id", "e2dx", "e2dy",
        "arrowId", "adx", "ady"
    ]

    for _ in range(num):
        if pos + 25 > len(data):
            raise ValueError("Du lieu SkillInfoPaint bi thieu")
        status = struct.unpack_from(">b", data, pos)[0]
        pos += 1
        vals = struct.unpack_from(">hhhhhhhhhhhh", data, pos)
        pos += 24
        obj = {"status": status}
        obj.update(dict(zip(keys[1:], vals)))
        arr.append(obj)
    return arr

try:
    for n in range(count):
        if pos + 5 > len(data):
            raise ValueError(f"Thieu ban ghi ky nang {n}")

        skill_id, eff_id = struct.unpack_from(">HH", data, pos)
        num_eff = struct.unpack_from(">b", data, pos + 4)[0]
        pos += 5

        stand = read_info()
        fly = read_info()

        rows.append((
            skill_id, eff_id, num_eff,
            json.dumps(stand, separators=(",", ":")),
            json.dumps(fly, separators=(",", ":"))
        ))
except (ValueError, struct.error) as e:
    raise SystemExit(f"Loi doc file: {e}; byte {pos}/{len(data)}")

if pos != len(data):
    raise SystemExit(
        f"Loi: Da doc {pos}/{len(data)} byte. Khong tao SQL."
    )

with open(out, "w", encoding="utf-8") as f:
    f.write(
        "CREATE TABLE IF NOT EXISTS `nj_skill` ("
        "`skillId` SMALLINT NOT NULL PRIMARY KEY,"
        "`effId` SMALLINT NOT NULL,"
        "`numEff` TINYINT NOT NULL,"
        "`skillStand` LONGTEXT NOT NULL,"
        "`skillFly` LONGTEXT NOT NULL"
        ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;\n"
    )
    f.write("DELETE FROM `nj_skill`;\n")

    for sid, eid, num, stand, fly in rows:
        def esc(s):
            return s.replace("\\", "\\\\").replace("'", "\\'")
        f.write(
            "INSERT INTO `nj_skill` "
            "(`skillId`,`effId`,`numEff`,`skillStand`,`skillFly`) "
            f"VALUES ({sid},{eid},{num},'{esc(stand)}','{esc(fly)}');\n"
        )

print("Kiem tra thanh cong")
print("So ky nang:", count)
print("So byte:", len(data))
print("Da tao:", out)
