USE [CoreClaim]
GO

/*
    CreatePaymentHospitalAsync — แยก query ตามส่วน / รูปแบบ Result template
    ใช้ชื่อ schema/table จาก SQL แนบ และใช้ logic จาก C#
    ใช้ DECLARE @... TABLE + INSERT INTO ... SELECT; ไม่มี temp table
    ใช้ @IsResult / @Result / @Msg และ GOTO RESULT สำหรับ validation
    ทุก UPDATE/INSERT ตารางจริงอยู่ใน transaction เดียวตาม template
    SELECT เตรียมข้อมูลอยู่ก่อน transaction; UPDATE จองรายการอยู่ภายใน
    หากล้มเหลว rollback ทั้งการจองและการสร้าง Payment ต่างจาก C# เดิม
    ที่ SaveChanges การจองก่อนเริ่ม transaction หลัก

    ใช้หนึ่งโรงพยาบาลต่อรอบ: เติม @HospitalId หากเลือกหลายโรงพยาบาล
    และให้ application ส่งรายการแยกตามโรงพยาบาลตามคำอธิบายเดิม
    @UserId = 1 ตาม template; เปลี่ยนให้ตรงผู้ใช้จริงก่อนรัน
    กรณีหลายโรงพยาบาลที่ต้อง commit พร้อมกัน ให้ application คุม transaction
    เดียวทุกกลุ่มและรับผิดชอบการ bind บัญชีแยกกลุ่ม

    Always Encrypted: SELECT บัญชีแบบ raw ให้ client ถอดรหัส;
    client ลบ '-' แล้ว bind @ToAccountNo และ @PhoneNo ด้วยชนิด/ขนาดตรง
    คอลัมน์จริง เปิด Column Encryption Setting=Enabled; ใน SSMS เปิด
    Enable Parameterization for Always Encrypted ด้วย
    DECLARE ตัวแปรอย่างเดียวไม่ได้ทำให้ server เข้ารหัสให้
    ชนิด table variable อิงตัวอย่าง SQL แนบ (ไม่ได้รับ DDL จริง)
    ตรวจชนิดข้อมูล/scale/length ในฐานข้อมูลก่อนใช้จริง

    คงสูตรภาษีหัวตาม C#: SUM(อัตราภาษี) * SUM(ยอด) / 100;
    อาจไม่เท่ากับ SUM(ภาษี PaymentItem) เมื่อมีหลายรายการ
    response.TotalNetPaidAmount คงยอดก่อนภาษีตาม C#
    FirstOrDefault ของ C# ไม่มี ORDER BY; แถวตัวแทนใน SQL เรียง TransferId
    SQL เตรียม payload แต่ไม่ publish message หรือทำ logging ให้เอง
    Query รวมยอดใช้ derived table แทน CTE เพื่อตัดจุด WITH ออกจากส่วนนี้
    ตัวแปรที่รอค่าจาก SELECT/EXEC กำหนด = NULL ชัดเจน;
    NEWID() ใช้เฉพาะค่า UNIQUEIDENTIFIER เท่านั้น
    ยังไม่ได้ execute กับฐานข้อมูลจริง
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @D2 DATETIME2 = GETDATE();
DECLARE @UserId INT = 999;

/*Default Declare*/
DECLARE @IsResult BIT = 1;
DECLARE @Result VARCHAR(100) = '';
DECLARE @Msg NVARCHAR(500) = N'';

-- =====================================================================
-- Query 00 : กำหนด input จาก request / login / environment
-- =====================================================================
DECLARE @CurrentUserName NVARCHAR(200) = N'';   -- Firstname + ' ' + Lastname
DECLARE @EnvZone NVARCHAR(20) = N'UAT';
DECLARE @ProductionBankParametersBound BIT = 0; -- client ตั้ง 1 หลัง bind ค่าบัญชี PROD ครบ
DECLARE @HospitalId INT = NULL;                -- เติมจาก Query 06
DECLARE @PaymentCode VARCHAR(50) = NULL;
DECLARE @AutoPayDelayDays INT = NULL;
DECLARE @BillingDate DATE = NULL;
DECLARE @HospitalName NVARCHAR(300) = NULL;
DECLARE @GrossTotal DECIMAL(18,2) = NULL;
DECLARE @RateSum DECIMAL(18,4) = NULL;
DECLARE @TaxTotal DECIMAL(18,4) = NULL;
DECLARE @NetTotal DECIMAL(18,4) = NULL;
DECLARE @EstimatedDate DATETIME2 = NULL;
DECLARE @ToBankId INT = 3;
DECLARE @ToBank NVARCHAR(50) = N'กรุงไทย';
DECLARE @ToAccountName NVARCHAR(255) = N'Account unit test UAT';
DECLARE @ToAccountNo VARCHAR(50) = '1821000001';
DECLARE @PhoneNo VARCHAR(50) = '0899999999';
-- PROD: bind ค่าธนาคารจาก Query 07 แยกต่อ HospitalId ผ่าน client
-- @ToAccountNo = account.Replace("-", "") ?? "" ตาม C#
-- ค่าทดสอบ UAT ด้านบนตรง C#; ห้ามใช้ค่าทดสอบกับ PROD

DECLARE @RequestedTransfers TABLE
(
    TransferId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY
);

DECLARE @CaseRows TABLE
(
    BillingPendingTransferId UNIQUEIDENTIFIER NOT NULL,
    CaseId UNIQUEIDENTIFIER NOT NULL,
    HospitalId INT NOT NULL,
    CaseNo NVARCHAR(100) NULL,
    ClaimNo NVARCHAR(100) NULL,
    HospitalName NVARCHAR(300) NULL,
    BillingDate DATE NULL,
    NetBillableAmount DECIMAL(18,2) NULL,
    WithHoldingTaxRate DECIMAL(18,4) NULL,
    CasePayableId UNIQUEIDENTIFIER NOT NULL,
    PaymentItemId UNIQUEIDENTIFIER NOT NULL,
    WithHoldingTaxAmount DECIMAL(18,2) NULL,
    NetPaidAmount DECIMAL(18,2) NULL
);

DECLARE @HospitalTotals TABLE
(
    HospitalId INT NOT NULL PRIMARY KEY,
    GrossTotal DECIMAL(18,2) NULL,
    RateSum DECIMAL(18,4) NULL,
    ItemCount INT NOT NULL,
    HospitalName NVARCHAR(300) NULL,
    BillingDate DATE NULL,
    RepresentativeTransferId UNIQUEIDENTIFIER NOT NULL,
    AutoPayDelayDays INT NULL,
    TaxTotal DECIMAL(18,2) NULL,
    NetTotal DECIMAL(18,2) NULL,
    EstimatedDate DATE NULL,
    BankId INT NULL,
    BankAccountNo VARCHAR(50) NULL,
    BankAccountName NVARCHAR(255) NULL,
    BankName NVARCHAR(255) NULL,
    rwId INT NULL
);

/*Setup OFF/ON Store Procedure*/
IF @IsResult = 0
BEGIN
    SET @Msg = N'ปิดใช้งาน';
    GOTO RESULT;
END;
-----------------------------------

-- เพิ่มได้หลายแถว; PRIMARY KEY ทำให้ต้องส่ง Distinct TransferId เช่น C#
INSERT INTO @RequestedTransfers
           ([TransferId])
     VALUES
           ('4A4DF1FF-6251-497B-8249-0A4692EFF98D');

IF ISNULL(@EnvZone, N'') <> N'UAT' AND @ProductionBankParametersBound = 0
BEGIN
    SET @IsResult = 0;
    SET @Msg = N'กรุณาส่งค่าบัญชี PROD ผ่าน client และตั้ง @ProductionBankParametersBound = 1';
    GOTO RESULT;
END;

IF @UserId IS NULL
BEGIN
    SET @IsResult = 0;
    SET @Msg = N'กรุณากำหนด @UserId ก่อนดำเนินการ';
    GOTO RESULT;
END;

IF NOT EXISTS (SELECT 1 FROM @RequestedTransfers)
BEGIN
    SET @IsResult = 0;
    SET @Msg = N'กรุณาเลือกรายการอย่างน้อย 1 รายการ';
    GOTO RESULT;
END;

/* TODO Select Query Here */
-- =====================================================================
-- Query 01 : ตรวจชนิดคอลัมน์ Payment และชื่อพารามิเตอร์ procedure จริง
-- =====================================================================
--SELECT c.[name] AS ColumnName
--      ,TYPE_NAME(c.user_type_id) AS DataType
--      ,c.max_length AS MaxLengthBytes
--      ,c.[precision]
--      ,c.scale
--      ,c.is_nullable
--      ,c.collation_name
--      ,c.encryption_type_desc
--FROM sys.columns AS c
--WHERE c.object_id = OBJECT_ID(N'finance.Payment')
--ORDER BY c.column_id;

--SELECT p.parameter_id
--      ,p.[name] AS ParameterName
--      ,TYPE_NAME(p.user_type_id) AS DataType
--      ,p.max_length AS MaxLengthBytes
--      ,p.is_output
--FROM sys.parameters AS p
--WHERE p.object_id = OBJECT_ID(N'process.usp_GenerateCodeBE')
--ORDER BY p.parameter_id;
-- =====================================================================
-- Query 02 : SELECT รายการ active จาก requests
-- =====================================================================
--SELECT b.BillingPendingTransferId
--      ,b.BillingDetailId
--      ,b.TransactionByUserId
--      ,b.IsGroup
--      ,b.NetBillableAmount
--      ,b.UpdatedDate
--FROM [billing].[BillingPendingTransfers] AS b
--INNER JOIN @RequestedTransfers AS r
--        ON r.TransferId = b.BillingPendingTransferId
--WHERE b.IsActive = 1;
-- =====================================================================
-- Query 03 : SELECT ตรวจผู้ใช้งานอื่นที่จองรายการไว้
-- =====================================================================
--SELECT b.BillingPendingTransferId AS DuplicateTransferId
--      ,b.TransactionByUserId
--FROM [billing].[BillingPendingTransfers] AS b
--INNER JOIN @RequestedTransfers AS r
--        ON r.TransferId = b.BillingPendingTransferId
--WHERE b.IsActive = 1
--  AND b.TransactionByUserId IS NOT NULL
--  AND b.TransactionByUserId <> @UserId;
-- =====================================================================
-- Query 04 : SELECT ยอดค้างจ่าย + เคส + เคลม + อัตราภาษี
-- ไม่ดึงคอลัมน์บัญชีเข้ารหัสลง table variable
-- CasePayableId ถูกสร้างที่แถวต้นทางเพื่อเชื่อม PaymentItem ถูกคู่
-- =====================================================================
INSERT INTO @CaseRows
           (
           [BillingPendingTransferId]
           ,[CaseId]
           ,[HospitalId]
           ,[CaseNo]
           ,[ClaimNo]
           ,[HospitalName]
           ,[BillingDate]
           ,[NetBillableAmount]
           ,[WithHoldingTaxRate]
           ,[CasePayableId]
           ,[PaymentItemId]
           ,[WithHoldingTaxAmount]
           ,[NetPaidAmount]
           )
SELECT b.BillingPendingTransferId
      ,c.CaseId
      ,ISNULL(c.HospitalId, 0) AS HospitalId
      ,c.CaseNo
      ,cl.ClaimNo
      ,b.HospitalName
      ,CONVERT(DATE, b.BillingDate) AS BillingDate
      ,b.NetBillableAmount
      ,o.WithHoldingTax AS WithHoldingTaxRate
      ,NEWID() AS CasePayableId
      ,NEWID() AS PaymentItemId
      ,ISNULL(o.WithHoldingTax, 0) * b.NetBillableAmount / 100 AS WithHoldingTaxAmount
      ,b.NetBillableAmount - ISNULL(o.WithHoldingTax, 0) * b.NetBillableAmount / 100 AS NetPaidAmount
FROM [billing].[BillingPendingTransfers] AS b
INNER JOIN @RequestedTransfers AS r
        ON r.TransferId = b.BillingPendingTransferId
INNER JOIN [billing].[BillingDetail] AS d
        ON d.BillingDetailId = b.BillingDetailId
INNER JOIN [core].[Case] AS c
        ON c.CaseId = d.CaseId
INNER JOIN [core].[Claim] AS cl
        ON cl.ClaimId = c.ClaimId
LEFT JOIN [ext].[OrganizeWithHoldingTax] AS o
       ON o.OrganizeId = c.HospitalId
WHERE b.IsActive = 1
  AND c.IsActive = 1
  AND cl.IsActive = 1
  AND (b.IsGroup = 0 OR b.IsGroup IS NULL);

--SELECT * FROM @CaseRows ORDER BY HospitalId, BillingPendingTransferId;
-- =====================================================================
-- Query 05 : SELECT TransferId ที่ไม่มีข้อมูล; validate ก่อนสร้าง Payment
-- =====================================================================
--SELECT r.TransferId AS NotFoundTransferId
--FROM @RequestedTransfers AS r
--WHERE NOT EXISTS
--      (SELECT 1 FROM @CaseRows AS h
--       WHERE h.BillingPendingTransferId = r.TransferId);

IF EXISTS
(
    SELECT 1 FROM @RequestedTransfers AS r
    WHERE NOT EXISTS
          (SELECT 1 FROM @CaseRows AS h
           WHERE h.BillingPendingTransferId = r.TransferId)
)
BEGIN
    SET @IsResult = 0;
    SET @Msg = N'ไม่พบรายการค้างจ่ายที่ยังไม่ได้จัดกลุ่มของบาง TransferId';
    GOTO RESULT;
END;

IF NOT EXISTS (SELECT 1 FROM @CaseRows)
BEGIN
    SET @IsResult = 0;
    SET @Msg = N'ไม่พบรายการค้างจ่ายสำหรับเคสที่เลือก';
    GOTO RESULT;
END;


IF EXISTS
(
    SELECT BillingPendingTransferId FROM @CaseRows
    GROUP BY BillingPendingTransferId HAVING COUNT(*) > 1
)
BEGIN
    SET @IsResult = 0;
    SET @Msg = N'พบ TransferId ซ้ำจากการ JOIN กรุณาตรวจ OrganizeWithHoldingTax';
    GOTO RESULT;
END;
-- =====================================================================
-- Query 06 : SELECT รวมยอดต่อโรงพยาบาล พร้อมแถวตัวแทน
-- =====================================================================
INSERT INTO @HospitalTotals
           (
           [HospitalId]
           ,[GrossTotal]
           ,[RateSum]
           ,[ItemCount]
           ,[HospitalName]
           ,[BillingDate]
           ,[RepresentativeTransferId]
           ,[AutoPayDelayDays]
           ,[TaxTotal]
           ,[NetTotal]
           ,[EstimatedDate]
           ,[BankId]
           ,[BankAccountNo]
           ,[BankAccountName]
           ,[BankName]
           ,[rwId]
           )
SELECT t.HospitalId
      ,t.GrossTotal
      ,t.RateSum
      ,t.ItemCount
      ,[firstRow].HospitalName
      ,[firstRow].BillingDate
      ,[firstRow].BillingPendingTransferId                                          [RepresentativeTransferId]
      ,AutoPayDelayDays                                                             [AutoPayDelayDays]
      ,(RateSum * GrossTotal / 100)                                                 [TaxTotal]
      ,(GrossTotal -  RateSum)                                                      [NetTotal]
      ,(DATEADD(DAY, AutoPayDelayDays, CONVERT(DATETIME2, [firstRow].BillingDate))) [EstimatedDate]
      ,o.BankId                                                                     [BankId]
      ,o.BankAccountNo                                                              [BankAccountNo]
      ,o.BankAccountName                                                            [BankAccountName]
      ,o.BankName                                                                   [BankName]
      ,ROW_NUMBER()  OVER(ORDER BY t.HospitalId)                                    rwId
FROM
(
    SELECT HospitalId
          ,SUM(ISNULL(NetBillableAmount, 0)) AS GrossTotal
          ,SUM(ISNULL(WithHoldingTaxRate, 0)) AS RateSum
          ,COUNT(*) AS ItemCount
    FROM @CaseRows
    GROUP BY HospitalId
) AS t
CROSS APPLY
(
    SELECT TOP (1) h.HospitalName, h.BillingDate, h.BillingPendingTransferId
    FROM @CaseRows AS h
    WHERE h.HospitalId = t.HospitalId
    ORDER BY h.BillingPendingTransferId
) AS [firstRow]
LEFT JOIN  
(
    SELECT 
        HospitalId
        ,HospitalName
        ,AutoPayDelayDays
    FROM [finance].[HospitalPaymentSetting]
    WHERE IsActive = 1
) paySetting
    ON t.HospitalId = paySetting.HospitalId
LEFT JOIN (
     SELECT 
      OrganizeId
      ,BankAccountName
      ,BankAccountNo
      ,BankName
      ,BankId
     FROM [ext].[OrganizeWithHoldingTax] 
     WHERE IsActive = 1
    ) o
    ON t.HospitalId = o.OrganizeId


--SELECT HospitalId
--      ,HospitalName
--      ,ItemCount
--      ,GrossTotal
--      ,RateSum
--      ,RateSum * GrossTotal / 100 AS HeaderTaxAccordingToCSharp
--      ,GrossTotal - RateSum * GrossTotal / 100 AS HeaderNetAccordingToCSharp
--      ,BillingDate
--FROM @HospitalTotals
--ORDER BY HospitalId;

-- สำหรับ script แบบรันหนึ่งโรงพยาบาล เลือกให้อัตโนมัติถ้ามีแค่กลุ่มเดียว
--IF @HospitalId IS NULL AND (SELECT COUNT(*) FROM @HospitalTotals) = 1
--    SELECT @HospitalId = HospitalId FROM @HospitalTotals;

--IF @HospitalId IS NULL
--BEGIN
--    SET @IsResult = 0;
--    SET @Msg = N'มีหลายโรงพยาบาล ให้เลือก @HospitalId จาก Query 06 และประมวลผลทีละกลุ่ม';
--    GOTO RESULT;
--END;

--IF NOT EXISTS (SELECT 1 FROM @HospitalTotals WHERE HospitalId = @HospitalId)
--BEGIN
--    SET @IsResult = 0;
--    SET @Msg = N'@HospitalId ไม่อยู่ในรายการที่เลือก';
--    GOTO RESULT;
--END;
-- =====================================================================
-- Query 07 : SELECT บัญชีสำหรับ client + SELECT การตั้งค่าจ่ายโรงพยาบาล
-- บัญชีใช้ raw SELECT เพื่อให้ AE-enabled client ถอดรหัส
-- ให้ client นำค่าไป bind Query 12; SQL ไม่ย้าย ciphertext ไป plaintext
-- =====================================================================
--SELECT o.OrganizeId AS HospitalId
--      ,o.BankId
--      ,o.BankName
--      ,o.BankAccountName
--      ,o.BankAccountNo
--FROM [ext].[OrganizeWithHoldingTax] AS o
--WHERE o.OrganizeId = @HospitalId;

--SELECT TOP (1)
--       s.HospitalId
--      ,s.HospitalName
--      ,s.AutoPayDelayDays
--FROM [finance].[HospitalPaymentSetting] AS s
--WHERE s.IsActive = 1
--  AND s.HospitalId = @HospitalId
--  AND s.HoldStatusId = 1;
-- ไม่มี ORDER BY เพื่อคง FirstOrDefault() ของ config ใน C#
-- =================================================================
-- Query 08 : คำนวณค่าหัว Payment และ EstimatedDate
-- =================================================================
--SET @AutoPayDelayDays = NULL;
--SELECT TOP (1) @AutoPayDelayDays = s.AutoPayDelayDays
--FROM [finance].[HospitalPaymentSetting] AS s
--WHERE s.IsActive = 1
--  AND s.HospitalId = @HospitalId
--  AND s.HoldStatusId = 1;

--IF @AutoPayDelayDays IS NULL
--BEGIN
--    SET @IsResult = 0;
--    SET @Msg = N'ไม่พบ HospitalPaymentSetting ที่ใช้งานได้ หรือ AutoPayDelayDays เป็น NULL';
--    GOTO RESULT;
--END;

--SELECT @GrossTotal = g.GrossTotal
--      ,@RateSum = g.RateSum
--      ,@BillingDate = g.BillingDate
--      ,@HospitalName = g.HospitalName
--FROM @HospitalTotals AS g
--WHERE g.HospitalId = @HospitalId;

--IF @BillingDate IS NULL
--BEGIN
--    SET @IsResult = 0;
--    SET @Msg = N'BillingDate เป็น NULL ไม่สามารถคำนวณ EstimatedDate ได้';
--    GOTO RESULT;
--END;

--SET @TaxTotal = @RateSum * @GrossTotal / 100;
--SET @NetTotal = @GrossTotal - @TaxTotal;
--SET @EstimatedDate = DATEADD(DAY, @AutoPayDelayDays, CONVERT(DATETIME2, @BillingDate));

--SELECT @GrossTotal AS TotalGrossPaidAmount
--      ,@TaxTotal AS TotalTaxAmount
--      ,@NetTotal AS TotalNetPaidAmount
--      ,@EstimatedDate AS EstimatedDate;

SET @D2 = GETDATE();

DECLARE @TotalRow INT = (SELECT MAX(rwId) FROM @HospitalTotals);

-- =====================================================================
-- Query 10 : EXEC สร้าง PaymentCode ของกลุ่ม (ภายใน transaction)
-- ลำดับพารามิเตอร์อ้างอิง SQL แนบ; ตรวจ Query 01 ก่อนใช้งาน
-- =====================================================================
--EXEC [process].[usp_GenerateCodeBE_FromTo] 'PMH', 8, @PaymentCode OUTPUT;

BEGIN TRY
    BEGIN TRANSACTION;

/* TODO Insert,Update,Truncate Query Here */
-- =====================================================================
-- Query 09 : UPDATE จองรายการ; หยุดทันทีถ้าพบผู้ใช้คนอื่น
-- ตรวจและจองภายใน transaction เดียวกับ INSERT/UPDATE ด้านล่าง
-- =====================================================================
    IF EXISTS
    (
        SELECT 1
        FROM [billing].[BillingPendingTransfers] AS b WITH (UPDLOCK, HOLDLOCK)
        INNER JOIN @RequestedTransfers AS r
                ON r.TransferId = b.BillingPendingTransferId
        WHERE b.IsActive = 1
          AND b.TransactionByUserId IS NOT NULL
          AND b.TransactionByUserId <> @UserId
    )
        BEGIN
            SET @IsResult = 0;
            SET @Msg = N'มีรายการถูกสร้างโดยผู้ใช้งานอื่นแล้ว';
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            GOTO RESULT;
        END;

    UPDATE b
       SET [TransactionByUserId] = @UserId
          ,[UpdatedDate] = @D2
    FROM [billing].[BillingPendingTransfers] AS b
    INNER JOIN @RequestedTransfers AS r
            ON r.TransferId = b.BillingPendingTransferId
    WHERE b.IsActive = 1;

--SELECT @HospitalId AS HospitalId, @PaymentId AS PaymentId, @PaymentCode AS PaymentCode;
-- =================================================================
    -- Query 11 : INSERT CasePayable หนึ่งแถวต่อรายการ
    -- =================================================================
    --INSERT INTO [process].[CasePayable]
    --           ([CasePayableId]
    --           ,[CaseId]
    --           ,[PayableStatusId]
    --           ,[PayableAmount]
    --           ,[TotalPaidAmount]
    --           ,[OutstandingAmount]
    --           ,[PayeeTypeId]
    --           ,[IsActive]
    --           ,[CreatedByUserId]
    --           ,[CreatedDate]
    --           ,[UpdatedByUserId]
    --           ,[UpdatedDate])
    SELECT h.CasePayableId  [CasePayableId]
          ,h.CaseId         [CaseId]
          ,2                [PayableStatusId]
          ,hos.NetTotal     [PayableAmount]
          ,hos.NetTotal     [TotalPaidAmount]
          ,hos.NetTotal     [OutstandingAmount]
          ,3                [PayeeTypeId]
          ,1                [IsActive]
          ,@UserId          [CreatedByUserId]
          ,@D2              [CreatedDate]
          ,@UserId          [UpdatedByUserId]
          ,@D2              [UpdatedDate]
    FROM @CaseRows AS h
    INNER JOIN @HospitalTotals hos
        ON h.HospitalId = hos.HospitalId;

    DECLARE @Start INT = 1;

    WHILE (@Start <= @TotalRow)
    BEGIN
        
        DECLARE @BankAccountNo VARCHAR(50);
        DECLARE @PaymentId UNIQUEIDENTIFIER = NEWID();
        SELECT @BankAccountNo = (SELECT BankAccountNo FROM @HospitalTotals WHERE rwId = @Start )

        SELECT @PaymentId           PaymentId
              ,NULL                 PaymentCode
              ,2
              ,2
              ,3
              ,2
              ,NULL
              ,p.GrossTotal
              ,p.TaxTotal
              ,p.NetTotal
              ,p.BankName           [ToBank]
              ,@BankAccountNo       [ToAccountNo]
              ,p.BankAccountName    [ToAccountName]
              ,NULL
              ,NULL
              ,NULL
              ,@PhoneNo
              ,1
              ,@UserId
              ,@D2
              ,@UserId
              ,@D2
              ,p.BankId             [ToBankId]
              ,p.EstimatedDate
        FROM @HospitalTotals AS p;   

    -- =================================================================
        -- Query 13 : INSERT PaymentItem อ้าง CasePayableId จากแถวเดียวกัน
        -- =================================================================
        --INSERT INTO [finance].[PaymentItem]
        --           ([PaymentItemId]
        --           ,[PaymentId]
        --           ,[CasePayableId]
        --           ,[GrossPaidAmount]
        --           ,[WithHoldingTaxAmount]
        --           ,[NetPaidAmount]
        --           ,[IsActive]
        --           ,[CreatedByUserId]
        --           ,[CreatedDate]
        --           ,[UpdatedByUserId]
        --           ,[UpdatedDate]
        --           ,[CaseNo]
        --           ,[ClaimNo])
        SELECT h.PaymentItemId           [PaymentItemId]          
              ,@PaymentId                [PaymentId]
              ,h.CasePayableId           [CasePayableId]
              ,h.NetBillableAmount       [GrossPaidAmount]
              ,h.WithHoldingTaxAmount    [WithHoldingTaxAmount]
              ,h.NetPaidAmount           [NetPaidAmount]
              ,1                         [IsActive]
              ,@UserId                   [CreatedByUserId]
              ,@D2                       [CreatedDate]
              ,@UserId                   [UpdatedByUserId]
              ,@D2                       [UpdatedDate]
              ,h.CaseNo                  [CaseNo]
              ,h.ClaimNo                 [ClaimNo]    
        FROM @CaseRows AS h
        INNER JOIN @HospitalTotals hos
            ON h.HospitalId = hos.HospitalId;
        
        SET @Start += 1;
    END

-- =================================================================
    -- Query 14 : UPDATE รายการที่สร้าง Payment สำเร็จในกลุ่มนี้
    -- =================================================================
    SELECT b.IsGroup
    --UPDATE b
    --   SET [IsGroup] = 1
    --      ,[IsSendSmileConnect] = 1
    --      ,[UpdatedByUserId] = @UserId
    --      ,[UpdatedDate] = @D2
    FROM [billing].[BillingPendingTransfers] AS b
    INNER JOIN @CaseRows AS h
            ON h.BillingPendingTransferId = b.BillingPendingTransferId
    WHERE b.IsActive = 1
    -- =================================================================
    -- จบ transaction และตั้งผลลัพธ์ตาม template
    -- =================================================================
    SET @IsResult = 1;
    SET @Msg = N'บันทึก สำเร็จ';
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    SET @IsResult = 0;
    SET @Msg = ERROR_MESSAGE();
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
END CATCH;

-----------------------------------
RESULT:

/*Return Result*/
IF @IsResult = 1
BEGIN
    SET @Result = 'Success';
END
ELSE
BEGIN
    SET @Result = 'Failure';
END;

IF @IsResult = 1
BEGIN
-- =====================================================================
-- Query 15 : SELECT ผลลัพธ์ response สำหรับโรงพยาบาลที่ประมวลผล
-- คืนรายละเอียดเฉพาะเมื่อ COMMIT สำเร็จ; Result หลักอยู่ที่ RESULT ด้านบน
-- =====================================================================
SELECT @IsResult AS IsSuccess
      ,1 AS ItemCount
      ,N'ทำรายการสำเร็จ' AS [Message]
      ,CAST(NULL AS UNIQUEIDENTIFIER) AS PayListHeaderId
      ,CAST(NULL AS UNIQUEIDENTIFIER) AS RefTransactionId
      ,@GrossTotal AS TotalNetPaidAmount
      ,@PaymentCode AS PaymentCode
      ,g.HospitalName
      ,g.ItemCount AS TotalCount
      ,g.GrossTotal AS NetPaidAmount
      ,@IsResult AS IsResult
      ,@Result AS Result
      ,@Msg AS Msg
      ,@PaymentCode AS PaymentCode
      ,CAST(NULL AS DATETIME2) AS PaymentDate
      ,h.CaseId
      ,2 AS PaymentStatusId
      ,N'แจ้งการโอนเงิน' AS PaymentStatusNameTH
      ,@UserId AS UserId
      ,@CurrentUserName AS UserName
      ,@EstimatedDate AS EstimateDate
      ,@PaymentId AS Refcode
FROM @HospitalTotals AS g
CROSS JOIN @CaseRows AS h
WHERE g.HospitalId = @HospitalId;

END;
