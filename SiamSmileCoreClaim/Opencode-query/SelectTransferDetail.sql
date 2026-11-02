/*
    หน้า: รายละเอียดรายการโอนเงิน (Transfer Detail)
    ส่งกลับ 3 result sets: Header, Details, Summary
    โครงสร้างจริง:
      - Header   = finance.Payment (TransferCode = PaymentCode) + master.PaymentStatus
      - Details  = finance.PaymentItem (1 แถว = 1 CasePayable) ผูก Case/Claim ผ่าน process.CasePayable.CaseId
      - Summary  = SUM จากชุด Details เดียวกัน (เงื่อนไขเดียวกัน)
    หมายเหตุ:
      - finance.Payment.ToAccountNo เป็นคอลัมน์เข้ารหัส (Always Encrypted)
        ต้องรันจาก client ที่มี column master key จึงถอดเป็นข้อความได้
      - PaymentCode ไม่ unique ระดับตาราง (มี row IsActive=0 ซ้ำได้) จึงบังคับ IsActive=1
      - core.Case.CaseNo มีค่าซ้ำในระบบ จึงห้าม join ผ่าน CaseNo โดยตรง ให้ใช้ CasePayableId -> CaseId
*/

SET NOCOUNT ON;
DECLARE @TransferCode varchar(50) = 'PMH691000000103'; -- ตรงกับคอลัมน์ finance.Payment.PaymentCode varchar(50)

--------------------------------------------------------------------------------
-- Result 1: Header (1 แถวต่อรายการโอนเงิน)
--------------------------------------------------------------------------------
SELECT
    p.PaymentCode          AS TransferCode,          -- varchar(50)
    ps.PaymentStatusNameTH AS TransferStatusName,    -- nvarchar(50) master.PaymentStatus
    h.HospitalName,                                  -- nvarchar จาก ext.Organize (หลายโรงพยาบาลด้วย STRING_AGG)
    p.ToBank               AS BankName,              -- nvarchar(50)
    p.ToAccountNo          AS BankAccountNo,         -- varchar(50) — encrypted col
    p.ToAccountName        AS BankAccountName,       -- nvarchar(max)
    p.PaymentDate          AS TransactionDate,       -- datetime2 วันที่ทำรายการ
    p.EstimatedDate        AS ExpectedTransferDate   -- datetime2 วันที่คาดว่าเงินจะออก
    ,p.PaymentId
FROM finance.Payment p
JOIN master.PaymentStatus ps
    ON ps.PaymentStatusId = p.PaymentStatusId
OUTER APPLY (
    SELECT STRING_AGG(o.OrganizeName, N', ')
               WITHIN GROUP (ORDER BY o.OrganizeName) AS HospitalName
    FROM (
        SELECT DISTINCT c.HospitalId
        FROM finance.PaymentItem pi
        JOIN process.CasePayable cp ON cp.CasePayableId = pi.CasePayableId
        JOIN [core].[Case] c        ON c.CaseId = cp.CaseId
        WHERE pi.PaymentId = p.PaymentId
          AND pi.IsActive = 1
    ) d
    JOIN ext.Organize o ON o.OrganizeId = d.HospitalId
) h
WHERE p.PaymentCode = @TransferCode
  AND p.IsActive = 1;

--------------------------------------------------------------------------------
-- Result 2: Details (1 แถว = 1 finance.PaymentItem = 1 รายการจ่าย/CasePayable)
--------------------------------------------------------------------------------
SELECT
    ROW_NUMBER() OVER (
        ORDER BY pi.CaseNo, pi.PaymentItemId         -- คอลัมน์แน่นอน + tie-breaker
    )                     AS RowNo,
    pi.CaseNo             AS ClaimCode,              -- varchar(50)
    cl.CustomerName       AS InsuredName,            -- nvarchar(100) core.Claim.CustomerName
    pi.GrossPaidAmount    AS Amount,                 -- decimal(18,2)
    pi.WithHoldingTaxAmount AS WithholdingTaxAmount, -- decimal(18,2)
    pi.NetPaidAmount      AS NetAmount               -- decimal(18,2) ค่าที่บันทึกจริง ไม่คำนวณเอง
FROM finance.PaymentItem pi
JOIN finance.Payment p
    ON p.PaymentId = pi.PaymentId
   AND p.PaymentCode = @TransferCode
   AND p.IsActive = 1
LEFT JOIN process.CasePayable cp ON cp.CasePayableId = pi.CasePayableId
LEFT JOIN [core].[Case] c        ON c.CaseId = cp.CaseId
LEFT JOIN core.Claim cl          ON cl.ClaimId = c.ClaimId AND cl.IsActive = 1
WHERE pi.IsActive = 1;

--------------------------------------------------------------------------------
-- Result 3: Summary (ชุดรายละเอียดเดียวกัน เงื่อนไขเดียวกัน)
--------------------------------------------------------------------------------
SELECT
    CAST(SUM(pi.GrossPaidAmount)      AS decimal(18,2)) AS TotalAmount,
    CAST(SUM(pi.WithHoldingTaxAmount) AS decimal(18,2)) AS TotalWithholdingTaxAmount,
    CAST(SUM(pi.NetPaidAmount)        AS decimal(18,2)) AS TotalNetAmount
FROM finance.PaymentItem pi
JOIN finance.Payment p
    ON p.PaymentId = pi.PaymentId
   AND p.PaymentCode = @TransferCode
   AND p.IsActive = 1
WHERE pi.IsActive = 1;

--------------------------------------------------------------------------------
-- Query ตรวจสอบ: แถวซ้ำ + ยอดรวมตรงกับหัวรายการหรือไม่
--------------------------------------------------------------------------------
/*
DECLARE @TransferCode varchar(50) = 'PMH691000000103';
WITH d AS (
    SELECT pi.*
    FROM finance.PaymentItem pi
    JOIN finance.Payment p
        ON p.PaymentId = pi.PaymentId
       AND p.PaymentCode = @TransferCode
       AND p.IsActive = 1
    WHERE pi.IsActive = 1
)
SELECT
    (SELECT COUNT(*) FROM finance.Payment p
      WHERE p.PaymentCode = @TransferCode AND p.IsActive = 1)              AS HeaderRows,      -- ต้อง = 1
    (SELECT COUNT(*) FROM d)                                               AS DetailRows,
    (SELECT COUNT(*) - COUNT(DISTINCT PaymentItemId) FROM d)               AS DupItem,         -- ต้อง = 0
    (SELECT COUNT(*) - COUNT(DISTINCT CAST(CaseNo AS varchar(50)) + ':' +
               CAST(CasePayableId AS varchar(50))) FROM d)                 AS DupCasePayable,  -- ต้อง = 0
    (SELECT CASE WHEN ABS(SUM(GrossPaidAmount) - SUM(WithHoldingTaxAmount)
                          - SUM(NetPaidAmount)) < 0.01
                 THEN 1 ELSE 0 END FROM d)                                 AS NetCalcOk,       -- ต้อง = 1
    (SELECT CASE WHEN ABS(SUM(NetPaidAmount) -
                 (SELECT TotalNetPaidAmount FROM finance.Payment p
                   WHERE p.PaymentCode = @TransferCode AND p.IsActive = 1)) < 0.01
                 THEN 1 ELSE 0 END FROM d)                                 AS MatchHeaderTotal -- ต้อง = 1
;
*/
