USE [CoreClaim]
GO

-- =============================================
-- Description: สำหรับดึงข้อมูล Payment HCG
-- ตามตาราง HTML mockup: เลือก, เลขอ้างอิงการโอน, วันที่ทำรายการ,
-- วันที่คาดว่าเงินจะออก, สถานพยาบาล, จำนวนราย, จำนวนเงิน,
-- ธนาคาร, เลขที่บัญชี, ชื่อบัญชี, สถานะ, ดำเนินการ
-- =============================================

SELECT
    -- เลือก (Checkbox) - ใช้ PaymentId เป็นค่าสำหรับ checkbox
    p.PaymentId

    -- เลขอ้างอิงการโอน (Transfer Reference Number)
    ,p.PaymentCode

    -- วันที่ทำรายการ (Transaction Date)
    ,p.CreatedDate

    -- วันที่คาดว่าเงินจะออก (Expected Payment Date)
    -- หมายเหตุ: ยังไม่พบคอลัมนี้ใน schema ปัจจุบัน
    -- อาจต้องเพิ่มคอลัมน์ใน finance.Payment หรือ finance.PayTransferTransaction
    ,NULL AS ExpectedPaymentDate

    -- สถานพยาบาล (Hos[pi]tal)
    ,org.OrganizeName AS HospitalName

    -- จำนวนราย (Number of Items)
    ,COUNT([pi].PaymentItemId) AS ItemCount

    -- จำนวนเงิน (Amount)
    ,p.TotalNetPaidAmount

    -- ธนาคาร (Bank)
    ,p.ToBank

    -- เลขที่บัญชี (Account Number)
    ,p.ToAccountNo

    -- ชื่อบัญชี (Account Name)
    ,p.ToAccountName

    -- สถานะ (Status)
    ,ps.PaymentStatusNameTH

    -- ดำเนินการ (Action) - ใช้ PaymentId สำหรับกดปุ่มดำเนินการ
    ,p.PaymentId AS ActionId

FROM finance.Payment p
LEFT JOIN finance.PaymentItem [pi]
    ON p.PaymentId = [pi].PaymentId
    AND [pi].IsActive = 1
LEFT JOIN process.CasePayable cp
    ON [pi].CasePayableId = cp.CasePayableId
    AND cp.IsActive = 1
LEFT JOIN core.[Case] cc
    ON cp.CaseId = cc.CaseId
    AND cc.IsActive = 1
LEFT JOIN ext.Organize org
    ON cc.HospitalId = org.OrganizeId
    AND org.OrganizeTypeId = 8  -- 8 = Hos[pi]tal
LEFT JOIN master.PaymentStatus ps
    ON p.PaymentStatusId = ps.PaymentStatusId
WHERE p.IsActive = 1
    AND p.PaymentCode LIKE 'HCG%'
GROUP BY
    p.PaymentId
    ,p.PaymentCode
    ,p.CreatedDate
    ,org.OrganizeName
    ,p.TotalNetPaidAmount
    ,p.ToBank
    ,p.ToAccountNo
    ,p.ToAccountName
    ,ps.PaymentStatusNameTH
ORDER BY p.CreatedDate DESC
