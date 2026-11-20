USE [CoreClaim]
GO

DECLARE @CaseId UNIQUEIDENTIFIER;
DECLARE @CaseAdjudicationId UNIQUEIDENTIFIER;

SET @CaseId = '3b71172e-4069-4ec5-8d2c-c48bace39818';


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

