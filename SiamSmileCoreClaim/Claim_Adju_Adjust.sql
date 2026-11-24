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

