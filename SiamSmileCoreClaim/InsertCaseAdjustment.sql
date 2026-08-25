USE [CoreClaim]
GO

/*Param*/
    DECLARE @AdjustmentReasonId INT
            ,@AdjustmentAmount DECIMAL(16,2)
            ,@ClaimNo VARCHAR(50)
            ,@UserId INT
            ;

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
		--GOTO RESULT;
	END;

/* Setup Data*/
    DECLARE @D2	DATETIME2(7);
    DECLARE @Tmp TABLE 
    (
     CaseId UNIQUEIDENTIFIER
     ,CaseAdjudicationId UNIQUEIDENTIFIER
    );

	SET @D2 = GETDATE();
    SET @AdjustmentReasonId = 2;
    SET @AdjustmentAmount = 1500;
    SET @ClaimNo = 'CL690800000131';

    INSERT INTO @Tmp
    (
     CaseId
     ,CaseAdjudicationId
    )
    SELECT 
     [case].CaseId
     ,payable.CaseAdjudicationId
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
    AND claim.ClaimNo = @ClaimNo

/* Validate Data */

BEGIN TRY
	BEGIN TRANSACTION

    --INSERT INTO [process].[CaseAdjustment]
    --(
    --    [CaseAdjustmentId],
    --    [AdjustmentTypeId],
    --    [CaseId],
    --    [CaseAdjudicationId],
    --    [AdjustmentDate],
    --    [AdjustmentReason],
    --    [AdjustmentAmount],
    --    [IsActive],
    --    [CreatedByUserId],
    --    [CreatedDate],
    --    [UpdatedByUserId],
    --    [UpdatedDate]
    --)
    SELECT
        NEWID()             CaseAdjustmentId
        ,2                  AdjustmentTypeId
        ,CaseId
        ,CaseAdjudicationId CaseAdjudicationId
        ,@D2                AdjustmentDate
        ,N'ผู้ให้บริ '           AdjustmentReason
        ,@AdjustmentAmount  AdjustmentAmount
        ,1                  IsActive
        ,1                  CreatedByUserId
        ,@D2                CreatedDate
        ,1                  UpdatedByUserId
        ,@D2                UpdatedDate
    FROM @Tmp ;

	COMMIT TRANSACTION
END TRY
BEGIN CATCH

	IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH

IF @IsResult = 1 BEGIN	SET @Result = 'Success' END	
ELSE BEGIN				SET @Result = 'Failure' END;	

SELECT @IsResult IsResult
		,@Result Result
		,@Msg	 Msg;