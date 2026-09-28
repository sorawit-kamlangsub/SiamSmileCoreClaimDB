USE [CoreClaim]
GO

-- =============================================
-- Description: สำหรับดึงข้อมูลรายการวางบิล (Billing Monitor)
-- ตามตาราง HTML mockup: เลือก, เลขอ้างอิงใบคุม รพ., เลขที่อ้างอิงเคส, 
-- วันที่ส่งวางบิล, ชื่อผู้เอาประกัน, สถานพยาบาล, จำนวนเงิน, สถานะ, รายละเอียด
-- =============================================

SELECT
    -- เลือก (Checkbox) - ใช้ CasePayableId เป็นค่าสำหรับ checkbox
    cpa.CasePayableId
    
    -- เลขอ้างอิงใบคุม รพ. (Hospital Reference Number)
    -- หมายเหตุ: ยังไม่พบคอลัมนี้ใน schema ปัจจุบัน อาจต้องเพิ่มคอลัมน์ใน core.[Case] หรือ core.Claim
    -- หรืออาจเป็นค่าจากตารางอื่น เช่น ext.Organize หรือตารางเฉพาะ
    ,NULL AS HospitalRefNo
    
    -- เลขที่อ้างอิงเคส (Case Reference Number)
    ,cc.CaseNo
    
    -- วันที่ส่งวางบิล (Billing Date)
    ,cl.CreatedDate
    
    -- ชื่อผู้เอาประกัน (Insured Person Name)
    ,cl.CustomerName
    
    -- สถานพยาบาล (Hospital Id, Hospital Name)
    ,org.OrganizeId
    ,org.OrganizeName
    
    -- จำนวนเงิน (Amount)
    ,cpa.PayableAmount
    
    -- สถานะ (Status) - PayableStatusId = 2 คือ "รอสร้างรายการ"
    ,cpa.PayableStatusId
    
    -- รายละเอียด (Details) - ใช้ CasePayableId สำหรับกดปุ่มดูรายละเอียด
    ,cpa.CasePayableId AS DetailId

FROM [process].[CasePayable] cpa
INNER JOIN core.[Case] cc
    ON cpa.CaseId = cc.CaseId
INNER JOIN core.Claim cl
    ON cc.ClaimId = cl.ClaimId
INNER JOIN ext.Organize org
    ON cc.HospitalId = org.OrganizeId
WHERE cpa.IsActive = 1
    AND cc.IsActive = 1
    AND cl.IsActive = 1
    AND cpa.PayableStatusId = 2  -- รอสร้างรายการ
    AND org.OrganizeTypeId = 8  -- 8 = Hospital
ORDER BY cl.CreatedDate DESC
