USE [CoreClaim]
GO

/* Param */
	DECLARE @RefundAmount DECIMAL
	,@AdjustmentReasonId INT
	,@RefundReasonId INT
	,@CaseId UNIQUEIDENTIFIER
	,@UserId INT
	,@Remark NVARCHAR(500);

	SET @RefundAmount = 200;
	SET @AdjustmentReasonId = 4;
	SET @RefundReasonId = 2;
	SET @CaseId = '87D1304C-573C-4CCC-BAFD-AD2074B92F2E';
	SET @UserId = 1;
	SET @Remark = N'การข้อคืนเงิน';
	
	DECLARE @D2	DATETIME2(7);

/*Default Declare*/
	DECLARE @IsResult	BIT;
	DECLARE @Result		VARCHAR(100);
	DECLARE @Msg		NVARCHAR(500);

    SET @IsResult = 1;
    SET @Result = '';
    SET @Msg = '';

/* Setup Data*/
    DECLARE @CaseAdjustmentId UNIQUEIDENTIFIER;
    DECLARE @CasePayable UNIQUEIDENTIFIER;
    DECLARE
         @ToBankId             INT 
         ,@ToBankName           VARCHAR(50)
         ,@ToBankAccountNo      VARCHAR(50)
         ,@CountValidate        INT ;

    SET @CaseAdjustmentId = NEWID();
    SET @CasePayable = NEWID();

    SELECT 
    @ToBankId            = payable.ToBankId
    ,@ToBankName         = payable.ToBankName
    ,@ToBankAccountNo    = payable.ToBankAccountNo
    FROM [process].CasePayable payable
    WHERE payable.CaseId = @CaseId;

    SELECT DISTINCT
    payable.PayableCategoryId
    ,payable.PayeeTypeId
    ,[case].CaseAmount
    ,claim.ClaimId
    ,adju.*
    INTO #Tmp
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
         adju.*
         ,ROW_NUMBER() OVER (PARTITION BY adju.CaseId ORDER BY adju.VersionNo DESC) rwId
        FROM process.CaseAdjudication adju
    ) adju
        ON [case].CaseId = adju.CaseId
    WHERE claim.IsActive = 1
    AND [case].IsActive = 1
    AND payable.IsActive = 1
    AND payItem.IsActive = 1
    AND pay.IsActive = 1
    AND pay.PaymentStatusId = 3
    AND adju.rwId = 1
    AND [case].CaseId = @CaseId;	

	SET @D2 = GETDATE();
BEGIN TRY
	BEGIN TRANSACTION

    SELECT
        @CaseAdjustmentId                   CaseAdjustmentId
        ,3                                  AdjustmentTypeId
        ,@CaseId                            CaseId
        ,CaseAdjudicationId                 CaseAdjudicationId
        ,@D2                                AdjustmentDate
        ,@AdjustmentReasonId                AdjustmentReasonId
        ,@RefundAmount - CaseAmount         AdjustmentAmount
        ,1                                  IsActive
        ,@UserId                            CreatedByUserId
        ,@D2                                CreatedDate
        ,@UserId                            UpdatedByUserId
        ,@D2                                UpdatedDate
        ,@Remark                            Remark 
    FROM #Tmp

	COMMIT TRANSACTION
END TRY
BEGIN CATCH

    SET @IsResult = 0
    SET @Msg = ERROR_MESSAGE()
	IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH

-----------------------------

IF OBJECT_ID('tempdb..#Tmp') IS NOT NULL  DROP TABLE #Tmp;