# Database Context สำหรับ AI Agent

เอกสารนี้กำหนดวิธีที่ Agent ต้องใช้ในการ query และเข้าถึงฐานข้อมูล อ่านให้ครบก่อนรันคำสั่ง SQL ทุกครั้ง

---

## 1. กฎสำคัญ (Safety Rules)

### ทำได้เลย ไม่ต้องถาม
- `SELECT` ทุกรูปแบบ (รวม JOIN, CTE, subquery, window function)
- `SELECT ... INTO #Tmp` (local temp table ที่ขึ้นต้นด้วย `#` เท่านั้น)
- ทำงานกับ temp table ที่ตัวเองสร้าง (`#Tmp...`) เช่น `INSERT INTO #Tmp`, `UPDATE #Tmp`, `DROP TABLE #Tmp`
- ดู metadata: `INFORMATION_SCHEMA.*`, `sys.tables`, `sys.columns`, `sp_help`, `sp_helptext`

### ต้องถามผู้ใช้ก่อนทุกครั้ง (ห้ามรันเอง)
- `INSERT`, `UPDATE`, `DELETE`, `MERGE`, `TRUNCATE` บน table จริง
- `DROP`, `ALTER`, `CREATE` (table, index, view, procedure, function, trigger, schema, database)
- `EXEC` / `EXECUTE` stored procedure ใด ๆ (อาจมี side effect) ยกเว้น `sp_help`, `sp_helptext`
- `SELECT ... INTO` ที่ไม่ใช่ `#Tmp` (เช่น `##GlobalTmp` หรือ table จริง)
- `GRANT`, `REVOKE`, `DENY`, `BACKUP`, `RESTORE`, `KILL`, `SHUTDOWN`
- Dynamic SQL (`sp_executesql`, `EXEC('...')`) ที่มีคำสั่งเปลี่ยนแปลงข้อมูล
- การเปลี่ยนค่า config หรือ `SET` ที่กระทบระดับ server/database

### รูปแบบการขออนุญาต
เมื่อต้องเปลี่ยนแปลงข้อมูล ให้แสดงข้อมูลต่อไปนี้ แล้วรอผู้ใช้ตอบ "ยืนยัน" ก่อน:

1. **จุดประสงค์**: ต้องการทำอะไร
2. **คำสั่ง SQL**: ที่จะรันจริง
3. **ผลกระทบ**: table ไหน ประมาณกี่แถว (ใช้ `SELECT COUNT(*)` ด้วย WHERE เดียวกันตรวจก่อน)
4. **วิธีย้อนกลับ**: เช่น backup ด้วย `SELECT ... INTO #Backup` ก่อน หรือใช้ transaction

> ถ้าไม่แน่ใจว่าคำสั่งเป็นแบบอ่านอย่างเดียวหรือไม่ ให้ถือว่า **ต้องถามก่อน**

---

## 2. แนวปฏิบัติในการ Query

- ระบุชื่อ column ชัดเจน หลีกเลี่ยง `SELECT *` บน table ใหญ่
- ใส่ `TOP (n)` ตอนสำรวจข้อมูล (เริ่มที่ 100) เพื่อไม่ให้ดึงข้อมูลมหาศาล
- ใส่เงื่อนไขวันที่/ช่วงข้อมูลเสมอเมื่อ query table ที่มี transaction จำนวนมาก
- ใช้ schema-qualified name เสมอ เช่น `claim.TableName`, `dbo.TableName`
- Cross-database ให้ใช้ three-part name: `DatabaseName.schema.TableName`
- ข้อมูลที่ต้องใช้ซ้ำหลายรอบ ให้เก็บใน `#Tmp` ก่อน (เหมือนการ copy ค่าไปวางอีก sheet ใน Excel) แล้วค่อย query ต่อ
- ใช้ `WITH (NOLOCK)` เฉพาะกรณี query ดูข้อมูลเพื่อวิเคราะห์เท่านั้น และแจ้งผู้ใช้ว่าข้อมูลอาจไม่ตรง 100%
- ลบ temp table เมื่อใช้เสร็จ: `DROP TABLE IF EXISTS #Tmp;`

### ตัวอย่างที่ทำได้เลย

```sql
-- สำรวจข้อมูล
SELECT TOP (100) *
FROM claim.SomeTable
WHERE CreatedDate >= '2026-01-01'
ORDER BY CreatedDate DESC;

-- เก็บผลลัพธ์ลง temp table
SELECT c.ClaimId, c.Amount, c.Status
INTO #TmpClaim
FROM claim.SomeTable c
WHERE c.CreatedDate >= '2026-01-01';

SELECT Status, COUNT(*) AS Cnt, SUM(Amount) AS TotalAmount
FROM #TmpClaim
GROUP BY Status;

DROP TABLE IF EXISTS #TmpClaim;
```

---

## 3. ข้อมูลฐานข้อมูล (แก้ไขให้ตรงกับระบบจริง)

| หัวข้อ | รายละเอียด |
|---|---|
| DBMS | SQL Server |
| Server | `<server-name>` |
| Database หลัก | `<database-name>` |
| Database อื่นที่ใช้ร่วม | `<other-database>` |
| Schemas ที่ใช้ | `dbo`, `claim` |
| สิทธิ์ของ account | `<read-only / read-write>` |

> Connection string อยู่ในไฟล์ `connection.md` (อ่านเฉพาะตอนต้องเชื่อมต่อ DB)

---

## 4. โครงสร้างตารางสำคัญ (Schema Overview)

> เติมตารางหลักที่ Agent ต้องใช้บ่อย เพื่อไม่ต้องเดา schema

### `<schema>.<TableName>`
- **หน้าที่**: อธิบายสั้น ๆ ว่าเก็บอะไร
- **Primary Key**: `<column>`
- **Columns สำคัญ**:

| Column | Type | คำอธิบาย |
|---|---|---|
| `<ColumnName>` | `<type>` | `<ความหมาย / ค่าที่เป็นไปได้>` |

### ความสัมพันธ์ระหว่างตาราง (Relationships)
```
<TableA>.<FK>  →  <TableB>.<PK>
```

### ค่า Status / Enum ที่ใช้ในระบบ
| Table.Column | ค่า | ความหมาย |
|---|---|---|
| `<Table>.<Status>` | `<0>` | `<ความหมาย>` |

---

## 5. Business Rules ที่ควรรู้

- เพิ่มกฎทางธุรกิจที่ส่งผลต่อการตีความข้อมูล เช่น การนับยอด, เงื่อนไขการโอนเงิน, สถานะที่ถือว่าสำเร็จ
- ระบุ column ที่เป็นข้อมูลอ่อนไหว (เช่น เลขบัญชี, เลขบัตรประชาชน, ข้อมูลที่เข้ารหัส) และห้ามแสดงผลแบบเต็มในคำตอบ ให้ mask เช่น `123-4-xxxxx-9`

---

## 6. รูปแบบการตอบผู้ใช้

- แสดง SQL ที่ใช้ทุกครั้ง เพื่อให้ผู้ใช้ตรวจสอบและ copy ไปรันเองได้
- สรุปผลลัพธ์เป็นตารางสั้น ๆ พร้อมจำนวนแถวที่พบ
- หาก query ผิดพลาด ให้แจ้ง error จริง แล้วเสนอวิธีแก้ ห้ามเดาผลลัพธ์เอง
- หากผลลัพธ์ไม่ตรงความคาดหวัง (เช่น 0 แถว) ให้ตรวจ filter/JOIN ก่อนสรุปว่าไม่มีข้อมูล
