USE [CoreClaim]
GO

-- =============================================
-- ทดสอบ SelectBillingMonitor โดยรัน TOP(100)
-- ตรวจสอบว่า OrganizeId และ OrganizeName แสดงผลถูกต้อง
-- =============================================

SELECT TOP(100)
    cpa.CasePayableId
    ,NULL AS HospitalRefNo
    ,cc.CaseNo
    ,cl.CreatedDate
    ,cl.CustomerName
    ,org.OrganizeId          -- Hospital Id (เพิ่มใหม่)
    ,org.OrganizeName        -- Hospital Name
    ,cpa.PayableAmount
    ,cpa.PayableStatusId
    ,cpa.CasePayableId AS DetailId
FROM [process].[CasePayable] cpa
INNER JOIN core.[Case] cc
    ON cpa.CaseId = cc.CaseId
INNER JOIN core.Claim cl
    ON cc.ClaimId = cl.ClaimId
INNER JOIN ext.Organize org
    ON cc.HospitalId = org.OrganizeId
    AND org.OrganizeTypeId = 8  -- 8 = Hospital
WHERE cpa.IsActive = 1
    AND cc.IsActive = 1
    AND cl.IsActive = 1
    AND cpa.PayableStatusId = 2  -- รอสร้างรายการ
ORDER BY cl.CreatedDate DESC

-- =============================================
-- ตรวจสอบเพิ่มเติม: จำนวนแถวทั้งหมด และ จำนวนที่มี OrganizeId ไม่เป็น NULL
-- =============================================
-- SELECT
--     COUNT(*) AS TotalRows
--     ,COUNT(org.OrganizeId) AS RowsWithHospitalId
--     ,COUNT(*) - COUNT(org.OrganizeId) AS RowsWithoutHospitalId
-- FROM [process].[CasePayable] cpa
-- INNER JOIN core.[Case] cc
--     ON cpa.CaseId = cc.CaseId
-- INNER JOIN core.Claim cl
--     ON cc.ClaimId = cl.ClaimId
-- LEFT JOIN ext.Organize org
--     ON cpa.ToBankId = org.OrganizeId
--     AND org.OrganizeTypeId = 5
-- WHERE cpa.IsActive = 1
--     AND cc.IsActive = 1
--     AND cl.IsActive = 1
--     AND cpa.PayableStatusId = 2
