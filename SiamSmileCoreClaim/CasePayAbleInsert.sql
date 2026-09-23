USE [CoreClaim]
GO

DECLARE @CaseId UNIQUEIDENTIFIER
        ,@TotalPaidAmount DECIMAL(16,2)
        ,@CaseAdjudicationId UNIQUEIDENTIFIER
        ,@UserId INT

    /*Default Declare*/
    DECLARE @D2             DATETIME2(7)    
	    ,@IsResult	        BIT			    
	    ,@Result		    VARCHAR(100)    
	    ,@Msg		        NVARCHAR(500)   
        ,@CasePayable       UNIQUEIDENTIFIER
        ,@CountValidate     INT             
        ,@ToBankId          INT             
        ,@ToBankName        VARCHAR(50)     
        ,@ToBankAccountName VARCHAR(200)    
        ,@ToBankAccountNo   VARCHAR(50)     
        ,@PhoneNumber       VARCHAR(20);

DECLARE @MappingCategory TABLE (
    PayableCategoryId INT,
    CoverageTypeId INT
);

DECLARE @MappingPayeeType TABLE (
    PayeeTypeId INT,
    ClaimSourceId INT
);

-- Set data
DECLARE @CasePayableId UNIQUEIDENTIFIER = NEWID();

    SELECT 
    @ToBankId            = bfc.BankId
    ,@ToBankName         = org.OrganizeName
    ,@ToBankAccountNo    = bfc.BankAccountNo
    ,@ToBankAccountName  = bfc.BankAccountName
    FROM agent.Beneficiary bfc
    LEFT JOIN 
    (
        SELECT
         OrganizeId
         ,OrganizeName
        FROM ext.Organize 
        WHERE IsActive = 1
        AND OrganizeTypeId = 5
    ) org
        ON bfc.BankId = org.OrganizeId
    WHERE bfc.CaseId = @CaseId;

INSERT INTO @MappingPayeeType (PayeeTypeId, ClaimSourceId)
VALUES
    (1, 1), -- N/A -> n/a
    (2, 2), -- ClaimAgent -> Customer
    (3, 3), -- SmileConnect -> Hospital
    (4, 4); -- IClaim -> Beneficiary

INSERT INTO @MappingCategory (PayableCategoryId, CoverageTypeId)
VALUES
    (1, 1), -- N/A -> n/a
    (2, 2), -- Medical -> Medical
    (3, 3), -- Compensate -> Compensate
    (4, NULL), -- ExGratia -> 
    (5, 4), -- DisabilityBenefit -> Disability
    (6, 5); -- DeathBenefit -> DeathCase

SELECT
 cc.CaseId
 ,adju.CaseAdjudicationId
 ,pct.PayableCategoryId
 ,pyt.PayeeTypeId
INTO #Tmp
FROM core.[Case] cc
INNER JOIN core.Claim cl
    ON cc.ClaimId = cl.ClaimId
INNER JOIN agent.Beneficiary bfc
    ON cc.CaseId = bfc.CaseId
INNER JOIN process.CaseAdjudication adju
    ON cc.CaseId = adju.CaseId
LEFT JOIN @MappingCategory pct
    ON cc.CoverageTypeId = pct.CoverageTypeId
LEFT JOIN @MappingPayeeType pyt
    ON cl.ClaimSourceId = pyt.ClaimSourceId
WHERE cc.CaseId = '39B0A09E-00CB-42E9-9499-763A6755AE4C'
AND adju.CaseAdjudicationId = '8492D497-D563-4628-90F3-3EEE6E951FD3'

SELECT * FROM #Tmp
    
    --INSERT INTO [process].[CasePayable]
    --           ([CasePayableId]
    --           ,[CaseId]
    --           ,[CaseAdjudicationId]
    --           ,[CaseAdjustmentId]
    --           ,[PayableCategoryId]
    --           ,[PayableStatusId]
    --           ,[PayableAmount]
    --           ,[TotalPaidAmount]
    --           ,[OutstandingAmount]
    --           ,[PayeeTypeId]
    --           ,[ToBankId]
    --           ,[ToBankName]
    --           ,[ToBankAccountNo]
    --           ,[IsActive]
    --           ,[CreatedByUserId]
    --           ,[CreatedDate]
    --           ,[UpdatedByUserId]
    --           ,[UpdatedDate])
    SELECT
     @CasePayableId        [CasePayableId]
     ,CaseId               CaseId
     ,CaseAdjudicationId   CaseAdjudicationId
     ,NULL                 [CaseAdjustmentId]
     ,PayableCategoryId    PayableCategoryId
     ,2                    [PayableStatusId]
     ,@TotalPaidAmount     [PayableAmount]
     ,@TotalPaidAmount     [TotalPaidAmount]
     ,@TotalPaidAmount     [OutstandingAmount]
     ,PayeeTypeId          PayeeTypeId
     ,@ToBankId            ToBankId
     ,@ToBankName          ToBankName
     ,@ToBankAccountNo     ToBankAccountNo
     ,1                    [IsActive]
     ,@UserId              [CreatedByUserId]
     ,@D2                  [CreatedDate]
     ,@UserId              [UpdatedByUserId]
     ,@D2                  [UpdatedDate]
    FROM #Tmp

IF OBJECT_ID('tempdb..#Tmp') IS NOT NULL  DROP TABLE #Tmp;