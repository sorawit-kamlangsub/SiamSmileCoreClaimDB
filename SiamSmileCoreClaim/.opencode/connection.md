# Connection Strings

ไฟล์นี้เก็บข้อมูลการเชื่อมต่อฐานข้อมูล อ่านเฉพาะตอนที่ต้องเชื่อมต่อ DB เท่านั้น
กฎการ query และ schema ดูที่ `context.md`

> **ห้าม hardcode รหัสผ่านในไฟล์นี้** ให้อ่านจาก environment variable หรือ secret store เท่านั้น

---

## Database หลัก

```
Server=<server>;Database=<db>;User Id=<user>;Password=%DB_PASSWORD%;TrustServerCertificate=True;
```

| หัวข้อ | รายละเอียด |
|---|---|
| Environment variable ของรหัสผ่าน | `DB_PASSWORD` |
| สิทธิ์ของ account | `<read-only / read-write>` |

## Database อื่นที่ใช้ร่วม (ถ้ามี)

```
Server=<server>;Database=<other-db>;User Id=<user>;Password=%DB_PASSWORD_2%;TrustServerCertificate=True;
```

---

## ข้อควรระวัง

- ห้ามแสดง connection string หรือรหัสผ่านในคำตอบให้ผู้ใช้ ให้ mask เป็น `Password=****`
- ห้าม commit ไฟล์นี้พร้อมรหัสผ่านจริงลง Git
- ถ้า account เป็น read-only แล้วต้องเปลี่ยนแปลงข้อมูล ให้แจ้งผู้ใช้แทนการหาทางอื่นเชื่อมต่อ
