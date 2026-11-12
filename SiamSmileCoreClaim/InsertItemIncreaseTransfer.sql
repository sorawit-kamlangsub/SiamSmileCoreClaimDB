    DECLARE @CaseId UNIQUEIDENTIFIER = 'b964615b-ac31-48ef-9a1d-863d0a87f1ed'

    DECLARE @CaseItemId UNIQUEIDENTIFIER;
    DECLARE @CaseAdjustmentId UNIQUEIDENTIFIER;
    DECLARE @CaseAdjudicationId UNIQUEIDENTIFIER;

    DECLARE @D2		DATETIME2(7);
    
	DECLARE	@AdjustmentReasonId INT
            ,@InputToStandardMappingId INT
            ,@StandardMedicalExpenseId INT
            ,@StandardMedicalExpenseBenefitId INT
            ,@Quantity INT
            ,@PerUnit INT
            ,@MedicalTypeId INT
            ,@TotalNetPaidAmount DECIMAL(16,2)
            ,@UserId INT
            ,@Remark NVARCHAR(500)

    SET @CaseItemId = NEWID();
    SET @CaseAdjustmentId = NEWID();
    SET @CaseAdjudicationId = NEWID();

    --SELECT DISTINCT
    --payable.PayeeTypeId
    --,claim.ClaimId
    --,adju.*
    --INTO #Tmp
    --FROM core.[Case] [case]
    --INNER JOIN core.Claim claim
    --    ON [case].ClaimId = claim.ClaimId
    --INNER JOIN [process].CasePayable payable
    --    ON [case].CaseId = payable.CaseId
    --INNER JOIN finance.PaymentItem payItem
    --    ON payable.CasePayableId = payItem.CasePayableId
    --INNER JOIN finance.Payment pay
    --    ON payItem.PaymentId = pay.PaymentId
    --INNER JOIN 
    --(
    --    SELECT 
    --     adju.*
    --     ,ROW_NUMBER() OVER (PARTITION BY adju.CaseId ORDER BY adju.VersionNo DESC) rwId
    --    FROM process.CaseAdjudication adju
    --) adju
    --    ON [case].CaseId = adju.CaseId
    --WHERE claim.IsActive = 1
    --AND [case].IsActive = 1
    --AND payable.IsActive = 1
    --AND payItem.IsActive = 1
    --AND pay.IsActive = 1
    --AND pay.PaymentStatusId = 3
    --AND adju.rwId = 1
    --AND [case].CaseId = @CaseId;

    --SET @CaseItemId = NEWID();
    
    --SELECT * FROM #Tmp

         SELECT
               @CaseItemId CaseItemId
               ,@CaseId CaseId
               ,@InputToStandardMappingId InputToStandardMappingId
               ,@StandardMedicalExpenseId StandardMedicalExpenseId
               ,@StandardMedicalExpenseBenefitId StandardMedicalExpenseBenefitId
               ,@Quantity Quantity
               ,@PerUnit PerUnit
               ,@TotalNetPaidAmount OriginalAmount
               ,0 DiscountAmount
               ,@TotalNetPaidAmount NetCaseAmount
               ,@MedicalTypeId MedicalTypeId
               ,0 NonCoveredAmount
               ,NULL NonCoveredReasonId
               ,0 ReceiptAmount
               ,NULL BodyPartId
               ,NULL Remark
               ,1 IsActive
               ,@UserId CreatedByUserId
               ,@D2 CreatedDate
               ,@UserId UpdatedByUserId
               ,@D2 UpdatedDate
               ,NEWID() CaseItemReceiveRoundId

         SELECT
               NEWID() CaseItemAdjudicationId
               ,@CaseAdjudicationId CaseAdjudicationId
               ,@StandardMedicalExpenseId StandardMedicalExpenseId
               ,@CaseItemId CaseItemId
               ,@TotalNetPaidAmount NetCaseAmount
               ,0 EligibleAmount
               ,@TotalNetPaidAmount ApprovedAmount
               ,0 NonCoveredAmount
               ,0 ExcessAmount
               ,NULL Remark
               ,1 IsActive
               ,@UserId CreatedByUserId
               ,@D2 CreatedDate
               ,@UserId UpdatedByUserId
               ,@D2 UpdatedDate


IF OBJECT_ID('tempdb..#Tmp') IS NOT NULL  DROP TABLE #Tmp;