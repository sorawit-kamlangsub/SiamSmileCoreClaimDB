USE [CoreClaim]
GO

-- =============================================
-- ตรวจสอบ OrganizeTypeId ทั้งหมดใน ext.Organize
-- เพื่อหาว่าโรงพยาบาลใช้ OrganizeTypeId เท่าไหร่
-- =============================================

SELECT
    org.OrganizeTypeId
    ,COUNT(*) AS TotalRecords
    ,MIN(org.OrganizeName) AS SampleName1
    ,MAX(org.OrganizeName) AS SampleName2
FROM ext.Organize org
WHERE org.IsActive = 1
GROUP BY org.OrganizeTypeId
ORDER BY org.OrganizeTypeId

-- =============================================
-- ตรวจสอบเพิ่มเติม: ดูข้อมูลตัวอย่างของแต่ละ OrganizeTypeId
-- =============================================
-- SELECT TOP(20)
--     org.OrganizeId
--     ,org.OrganizeTypeId
--     ,org.OrganizeName
-- FROM ext.Organize org
-- WHERE org.IsActive = 1
-- ORDER BY org.OrganizeTypeId, org.OrganizeName
