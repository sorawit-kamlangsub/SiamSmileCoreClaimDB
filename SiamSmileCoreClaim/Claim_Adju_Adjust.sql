USE [CoreClaim]
GO

DECLARE @CaseId UNIQUEIDENTIFIER;
DECLARE @CaseAdjudicationId UNIQUEIDENTIFIER;

SET @CaseId = '3b71172e-4069-4ec5-8d2c-c48bace39818';


    SELECT 
     'CORE' [Schema]
     ,CaseNo
     ,CaseAmount
     ,LatestApprovedAmount
    FROM [core].[Case]
    WHERE CaseId = @CaseId

    SELECT 
     'CORE' [Schema]
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
     ,ApprovedMedicalAmount
     ,IsActive
    FROM [process].[CaseAdjudication]
    WHERE CaseId = @CaseId

    SELECT 
     'PROCESS' [Schema]
     ,CaseAdjudicationId
     ,ApprovedAmount
    FROM [process].[CaseItemAdjudication]
    WHERE CaseAdjudicationId = @CaseAdjudicationId