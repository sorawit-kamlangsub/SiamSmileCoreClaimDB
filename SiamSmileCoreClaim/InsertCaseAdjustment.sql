USE [CoreClaim]
GO

/*Param*/
    DECLARE @AdjustmentReasonId INT
            ,@AdjustmentAmount DECIMAL(16,2)
            ,@ClaimNo VARCHAR(50)
            ;
    
    DECLARE @D2	DATETIME2(7);


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
    SELECT claim.*
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

	SET @D2 = GETDATE();
    SET @AdjustmentReasonId = 2;
    SET @AdjustmentAmount = 1500;
    SET @ClaimNo = 'CL690800000131';

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
    VALUES
    (
        NEWID(),                                -- CaseAdjustmentId
        2,                                      -- AdjustmentTypeId
        'AF8F6121-7BE1-4AE9-B803-6022FAD53F01', -- CaseId
        NEWID(),                                -- CaseAdjudicationId
        @D2,                                    -- AdjustmentDate
        NULL,                                   -- AdjustmentReason
        @AdjustmentAmount,                      -- AdjustmentAmount
        1,                                      -- IsActive
        1,                                      -- CreatedByUserId
        @D2,                                    -- CreatedDate
        1,                                      -- UpdatedByUserId
        @D2                                     -- UpdatedDate
    );

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