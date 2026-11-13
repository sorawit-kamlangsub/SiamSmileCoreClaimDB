USE [CoreClaim]
GO

/****** Object:  StoredProcedure [finance].[usp_AdditionalTransfer_Core_Insert]    Script Date: 10/6/2026 10:14:28 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Sorawit kamlangsub
-- Create date: 2026-09-02
/* 
   Update date: 
*/
-- Description:	Process การโอนเพิ่ม
-- =============================================
ALTER PROCEDURE [finance].[usp_AdditionalTransfer_Insert]
/* Add the parameters for the stored procedure here
 comment if not receive parameter*/
			@AdjustmentReasonId INT
            ,@CaseAdjudicationId UNIQUEIDENTIFIER
            ,@InputToStandardMappingId INT
            ,@StandardMedicalExpenseId INT
            ,@StandardMedicalExpenseBenefitId INT
            ,@Quantity INT
            ,@PerUnit INT
            ,@MedicalTypeId INT
            ,@NetPaidAmount DECIMAL(16,2)
            ,@CaseId UNIQUEIDENTIFIER
            ,@UserId INT
            ,@Remark NVARCHAR(500)

AS
BEGIN
/*SET NOCOUNT ON added to prevent extra result sets from interfering with SELECT statements.*/
	SET NOCOUNT ON;

/*Test Zone
    DECLARE @AdjustmentReasonId INT
            ,@TotalNetPaidAmount DECIMAL(16,2)
            ,@CaseId UNIQUEIDENTIFIER
            ,@UserId INT
            ,@Remark NVARCHAR(500);
            ;
    SET @UserId = 1;
    SET @AdjustmentReasonId = 2;
    SET @TotalNetPaidAmount = 203;
    SET @CaseId = 'D0987F5A-C10D-4590-9C37-7348F13CB4DE';
*/

	DECLARE @D2		DATETIME2(7);

/*Default Declare*/
	DECLARE @IsResult	BIT			 ;
	DECLARE @Result		VARCHAR(100) ;
	DECLARE @Msg		NVARCHAR(500);

    SET @Msg = '';
    SET @Result = '';
    SET @IsResult = 1;
    SET @D2 = GETDATE();

/*Setup OFF/ON Store Procedure*/
	IF @IsResult = 0 
	BEGIN
		SET @Msg = N'ปิดใช้งาน'
		GOTO RESULT;
	END;
-----------------------------------

/* TODO Select Query Here*/
/* Setup Data*/
    DECLARE @CaseItemId UNIQUEIDENTIFIER;
    DECLARE @CaseAdjustmentId UNIQUEIDENTIFIER;
    DECLARE @CaseItemReceiveRoundId UNIQUEIDENTIFIER;

    SET @CaseItemId = NEWID();
    SET @CaseAdjustmentId = NEWID();
    SET @CaseItemReceiveRoundId = NEWID();

    DECLARE @ReceiveRoundNo INT;
    DECLARE @OriginalAmount DECIMAL(16,2);

    SELECT @ReceiveRoundNo = ISNULL(MAX(ReceiveRoundNo), 0) + 1
    FROM [process].[CaseItemReceiveRound]
    WHERE CaseId = @CaseId;

BEGIN TRY
	BEGIN TRANSACTION

    INSERT INTO [process].[CaseItemReceiveRound]
               ([CaseItemReceiveRoundId]
               ,[CaseId]
               ,[ReceiveRoundNo]
               ,[ReceiveStep]
               ,[HasCaseItems]
               ,[CreatedByUserId]
               ,[CreatedDate])
         SELECT
               @CaseItemReceiveRoundId  [CaseItemReceiveRoundId]
               ,@CaseId                 [CaseId]
               ,@ReceiveRoundNo         [ReceiveRoundNo]
               ,'ApproveClaimDecision'  [ReceiveRoundNo]
               ,1                       [HasCaseItems]
               ,@UserId                 [CreatedByUserId]
               ,@D2                     [CreatedDate] 

    INSERT INTO [core].[CaseItem]
               ([CaseItemId]
               ,[CaseId]
               ,[InputToStandardMappingId]
               ,[StandardMedicalExpenseId]
               ,[StandardMedicalExpenseBenefitId]
               ,[Quantity]
               ,[PerUnit]
               ,[OriginalAmount]
               ,[DiscountAmount]
               ,[NetCaseAmount]
               ,[MedicalTypeId]
               ,[NonCoveredAmount]
               ,[NonCoveredReasonId]
               ,[ReceiptAmount]
               ,[BodyPartId]
               ,[Remark]
               ,[IsActive]
               ,[CreatedByUserId]
               ,[CreatedDate]
               ,[UpdatedByUserId]
               ,[UpdatedDate]
               ,[CaseItemReceiveRoundId])
         SELECT
               @CaseItemId CaseItemId
               ,@CaseId CaseId
               ,@InputToStandardMappingId InputToStandardMappingId
               ,@StandardMedicalExpenseId StandardMedicalExpenseId
               ,@StandardMedicalExpenseBenefitId StandardMedicalExpenseBenefitId
               ,@Quantity Quantity
               ,@PerUnit PerUnit
               ,@NetPaidAmount OriginalAmount
               ,0 DiscountAmount
               ,@NetPaidAmount NetCaseAmount
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
               ,@CaseItemReceiveRoundId CaseItemReceiveRoundId

    INSERT INTO [process].[CaseItemAdjudication]
               ([CaseItemAdjudicationId]
               ,[CaseAdjudicationId]
               ,[StandardMedicalExpenseId]
               ,[CaseItemId]
               ,[NetCaseAmount]
               ,[EligibleAmount]
               ,[ApprovedAmount]
               ,[NonCoveredAmount]
               ,[ExcessAmount]
               ,[Remark]
               ,[IsActive]
               ,[CreatedByUserId]
               ,[CreatedDate]
               ,[UpdatedByUserId]
               ,[UpdatedDate])
         SELECT
               NEWID() CaseItemAdjudicationId
               ,@CaseAdjudicationId CaseAdjudicationId
               ,@StandardMedicalExpenseId StandardMedicalExpenseId
               ,@CaseItemId CaseItemId
               ,@NetPaidAmount NetCaseAmount
               ,@NetPaidAmount EligibleAmount
               ,@NetPaidAmount ApprovedAmount
               ,0 NonCoveredAmount
               ,0 ExcessAmount
               ,NULL Remark
               ,1 IsActive
               ,@UserId CreatedByUserId
               ,@D2 CreatedDate
               ,@UserId UpdatedByUserId
               ,@D2 UpdatedDate


    
    INSERT INTO [process].[CaseAdjustment]
    (
        [CaseAdjustmentId],
        [AdjustmentTypeId],
        [CaseId],
        [CaseAdjudicationId],
        [AdjustmentDate],
        [AdjustmentReasonId],
        [AdjustmentAmount],
        [IsActive],
        [CreatedByUserId],
        [CreatedDate],
        [UpdatedByUserId],
        [UpdatedDate],
        [Remark]
    )
    SELECT
        @CaseAdjustmentId       CaseAdjustmentId
        ,2                      AdjustmentTypeId
        ,@CaseId                CaseId
        ,@CaseAdjudicationId    CaseAdjudicationId
        ,@D2                    AdjustmentDate
        ,@AdjustmentReasonId    AdjustmentReasonId
        ,@NetPaidAmount         AdjustmentAmount
        ,1                      IsActive
        ,@UserId                CreatedByUserId
        ,@D2                    CreatedDate
        ,@UserId                UpdatedByUserId
        ,@D2                    UpdatedDate
        ,@Remark                Remark

    UPDATE m
    SET m.CaseAmount = m.CaseAmount + @NetPaidAmount
        ,m.LatestApprovedAmount = m.LatestApprovedAmount + @NetPaidAmount
        ,m.UpdatedByUserId = @UserId
        ,m.UpdatedDate = @D2
    FROM [core].[Case] m
    WHERE m.IsActive = 1
    AND m.CaseId = @CaseId

	SET @IsResult	= 1;
	SET @Msg		= N'บันทึก สำเร็จ';

	COMMIT TRANSACTION
END TRY
BEGIN CATCH

	SET @IsResult	= 0;
	SET @Msg		= ERROR_MESSAGE();

	IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH

-----------------------------------

RESULT:


/*Return Result 
comment this part if no return result */
	IF @IsResult = 1 BEGIN	SET @Result = 'Success' END	
	ELSE BEGIN				SET @Result = 'Failure' END;	

    SELECT @IsResult IsResult
		    ,@Result Result
		    ,@Msg	 Msg
            ,NEWID() CalimId
            ,@CaseAdjustmentId CaseAdjustmentId;

END
GO

