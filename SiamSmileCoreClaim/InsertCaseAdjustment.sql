USE [CoreClaim]
GO

/*Param*/
    DECLARE @AdjustmentReasonId INT
            ,@AdjustmentAmount DECIMAL(16,2)
            ,@ClaimNo VARCHAR(50)
            ,@UserId INT
            ;
    SET @UserId = 1;
    SET @AdjustmentReasonId = 2;
    SET @AdjustmentAmount = 1500;
    SET @ClaimNo = 'CL690800000174';


/*Default Declare*/
	DECLARE @IsResult	BIT;
	DECLARE @Result		VARCHAR(100);
	DECLARE @Msg		NVARCHAR(500);

    SET @IsResult = 1;
    SET @Result = '';
    SET @Msg = '';

/*Setup OFF/ON Store Procedure*/
	IF @IsResult = 0 
	BEGIN
		SET @Msg = N'ปิดใช้งาน'
		GOTO RESULT;
	END;

/* Setup Data*/
    DECLARE @D2	DATETIME2(7);
    DECLARE @CaseAdjustmentId UNIQUEIDENTIFIER;

    DECLARE
         @CaseId                UNIQUEIDENTIFIER
         ,@CaseAdjudicationId   UNIQUEIDENTIFIER
         ,@PayableCategoryId    INT
         ,@PayeeTypeId          INT
         ,@FromBankId           INT 
         ,@FromBankName         VARCHAR(50) 
         ,@FromBankAccountNo    VARCHAR(50) 
         ,@ToBankId             INT 
         ,@ToBankName           VARCHAR(50)
         ,@ToBankAccountNo      VARCHAR(50)
         ,@CountValidate        INT ;

    SET @CaseAdjustmentId = NEWID();
   	SET @D2 = GETDATE();

    SELECT 
    @CaseId              = [case].CaseId
    ,@CaseAdjudicationId = payable.CaseAdjudicationId
    ,@PayableCategoryId  = payable.PayableCategoryId
    ,@PayeeTypeId        = payable.PayeeTypeId
    ,@FromBankId         = payable.FromBankId
    ,@FromBankName       = payable.FromBankName
    ,@FromBankAccountNo  = payable.FromBankAccountNo
    ,@ToBankId           = payable.ToBankId
    ,@ToBankName         = payable.ToBankName
    ,@ToBankAccountNo    = payable.ToBankAccountNo
    ,@CountValidate      = COUNT([case].CaseId) OVER()

    FROM core.[Case] [case]
    INNER JOIN core.Claim claim
        ON [case].ClaimId = claim.ClaimId
    INNER JOIN [process].CasePayable payable
        ON [case].CaseId = payable.CaseId
    INNER JOIN finance.PaymentItem payItem
        ON payable.CasePayableId = payItem.CasePayableId
    INNER JOIN finance.Payment pay
        ON payItem.PaymentId = pay.PaymentId
    WHERE pay.PaymentStatusId = 3
    AND claim.ClaimNo = @ClaimNo;

/* Validate Data */
	IF @CountValidate > 1 
	BEGIN
		SET @Msg = N'มี CC มากกว่า 1 รายการ'
		GOTO RESULT;
	END;

BEGIN TRY
	BEGIN TRANSACTION

    INSERT INTO [process].[CaseAdjustment]
    (
        [CaseAdjustmentId],
        [AdjustmentTypeId],
        [CaseId],
        [CaseAdjudicationId],
        [AdjustmentDate],
        [AdjustmentReason],
        [AdjustmentAmount],
        [IsActive],
        [CreatedByUserId],
        [CreatedDate],
        [UpdatedByUserId],
        [UpdatedDate]
    )
    SELECT
        @CaseAdjustmentId       CaseAdjustmentId
        ,2                      AdjustmentTypeId
        ,@CaseId                CaseId
        ,@CaseAdjudicationId    CaseAdjudicationId
        ,@D2                    AdjustmentDate
        ,N'ผู้ให้บริ '              AdjustmentReason
        ,@AdjustmentAmount      AdjustmentAmount
        ,1                      IsActive
        ,@UserId                CreatedByUserId
        ,@D2                    CreatedDate
        ,@UserId                UpdatedByUserId
        ,@D2                    UpdatedDate

    INSERT INTO [process].[CasePayable]
               ([CasePayableId]
               ,[CaseId]
               ,[CaseAdjudicationId]
               ,[CaseAdjustmentId]
               ,[PayableCategoryId]
               ,[PayableStatusId]
               ,[PayableAmount]
               ,[TotalPaidAmount]
               ,[OutstandingAmount]
               ,[PayeeTypeId]
               ,[FromBankId]
               ,[FromBankName]
               ,[FromBankAccountNo]
               ,[ToBankId]
               ,[ToBankName]
               ,[ToBankAccountNo]
               ,[IsActive]
               ,[CreatedByUserId]
               ,[CreatedDate]
               ,[UpdatedByUserId]
               ,[UpdatedDate])
    SELECT
     NEWID()                [CasePayableId]
     ,@CaseId               CaseId
     ,@CaseAdjudicationId   CaseAdjudicationId
     ,@CaseAdjustmentId     [CaseAdjustmentId]
     ,@PayableCategoryId    PayableCategoryId
     ,2                     [PayableStatusId]
     ,@AdjustmentAmount     [PayableAmount]
     ,@AdjustmentAmount     [TotalPaidAmount]
     ,@AdjustmentAmount     [OutstandingAmount]
     ,@PayeeTypeId          PayeeTypeId
     ,@FromBankId           FromBankId
     ,@FromBankName         FromBankName
     ,@FromBankAccountNo    FromBankAccountNo
     ,@ToBankId             ToBankId
     ,@ToBankName           ToBankName
     ,@ToBankAccountNo      ToBankAccountNo
     ,1                     [IsActive]
     ,@UserId               [CreatedByUserId]
     ,@D2                   [CreatedDate]
     ,@UserId               [UpdatedByUserId]
     ,@D2                   [UpdatedDate]

	COMMIT TRANSACTION
END TRY
BEGIN CATCH
    SET @IsResult = 0
    SET @Msg = ERROR_MESSAGE()
	IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH

IF @IsResult = 1 BEGIN	SET @Result = 'Success' END	
ELSE BEGIN				SET @Result = 'Failure' END;	

RESULT:

SELECT @IsResult IsResult
		,@Result Result
		,@Msg	 Msg;
