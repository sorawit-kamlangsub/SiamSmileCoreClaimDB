USE [CoreClaim]
GO

DECLARE @CaseId UNIQUEIDENTIFIER;
DECLARE @CaseAdjudicationId UNIQUEIDENTIFIER;

SET @CaseId = '83e281bd-22f2-4272-9487-365dac8f8adc';


    SELECT 
     'CORE' [Schema]
     ,CaseId
     ,CaseNo
     ,CaseAmount
     ,LatestApprovedAmount
    FROM [core].[Case]
    WHERE CaseId = @CaseId

    SELECT 
     'CORE' [Schema]
     ,CaseItemId
     ,CaseId
     ,OriginalAmount
     ,CONCAT('CoverName',' ',ROW_NUMBER() OVER (PARTITION BY CaseId ORDER BY CreatedDate DESC)) [Name]
     ,IsActive
    FROM [core].[CaseItem]
    WHERE CaseId = @CaseId;

    SELECT 
     @CaseAdjudicationId = CaseAdjudicationId
    FROM [process].[CaseAdjudication]
    WHERE CaseId = @CaseId

    SELECT 
     'PROCESS' [Schema]
     ,CaseAdjudicationId
     ,CaseId
     ,VersionNo
     ,ApprovedMedicalAmount
     ,IsActive
    FROM [process].[CaseAdjudication]
    WHERE CaseId = @CaseId

    SELECT 
     'PROCESS' [Schema]
     ,CaseItemAdjudicationId
     ,CaseAdjudicationId
     ,ApprovedAmount
    FROM [process].[CaseItemAdjudication]
    WHERE CaseAdjudicationId = @CaseAdjudicationId

    SELECT 
     'PROCESS' [Schema]
     ,CasePayableId
     ,CaseId
     ,CaseAdjudicationId
     ,PayableAmount
     ,CaseAdjustmentId
    FROM [process].[CasePayable]
    WHERE CaseId = @CaseId

    SELECT 
     'PROCESS' [Schema]
     ,CaseAdjustmentId
     ,CaseId
     ,CaseAdjudicationId
     ,CaseRefundId
     ,AdjustmentReasonId
     ,CaseRefundId
     ,AdjustmentAmount
    FROM [process].[CaseAdjustment]
    WHERE CaseId = @CaseId

    SELECT TOP(100)
    [case].CaseId
    ,claim.ClaimId
    ,caseItem.ItemCount
    ,[case].CaseNo
    ,claim.ClaimNo
    FROM core.[Case] [case]
    INNER JOIN core.Claim claim
        ON [case].ClaimId = claim.ClaimId
    INNER JOIN [process].CasePayable payable
        ON [case].CaseId = payable.CaseId
    INNER JOIN finance.PaymentItem payItem
        ON payable.CasePayableId = payItem.CasePayableId
    INNER JOIN finance.Payment pay
        ON payItem.PaymentId = pay.PaymentId
    INNER JOIN 
    (
        SELECT
            citem.CaseId,
            COUNT(*) AS ItemCount
        FROM core.CaseItem citem
        WHERE citem.IsActive = 1
        GROUP BY citem.CaseId
    ) caseItem
        ON [case].CaseId = caseItem.CaseId
    WHERE claim.IsActive = 1
    AND [case].IsActive = 1
    AND payable.IsActive = 1
    AND payItem.IsActive = 1
    AND pay.IsActive = 1
    AND pay.PaymentStatusId = 3
    AND caseItem.ItemCount > 1
    AND NOT EXISTS
    (
        SELECT 1
        FROM [process].CaseAdjustment adjustment
        WHERE adjustment.CaseId = [case].CaseId
    )    
    ORDER BY [case].CreatedDate DESC

