USE [CoreClaim]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Sorawit Kamlangsub
-- Create date: 2026-11-12
-- Description:	Increase Core
-- =============================================
ALTER PROCEDURE [finance].[usp_CreateCoreTransfer_Insert]
	-- Add the parameters for the stored procedure here
	@CaseId UNIQUEIDENTIFIER
    ,@CaseItemId UNIQUEIDENTIFIER
    ,@NetPaidAmount DECIMAL(16,2)
    ,@UserId INT
    ,@Remark NVARCHAR(500)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

/*Default Declare*/
    DECLARE @D2 DATETIME2(7);
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

    DECLARE @CountValidate        INT ;

    DECLARE @ClaimId UNIQUEIDENTIFIER;
    DECLARE @InputToStandardMappingId INT;
    DECLARE @StandardMedicalExpenseId INT;
    DECLARE @StandardMedicalExpenseBenefitId INT;
    DECLARE @Quantity INT;
    DECLARE @PerUnit INT;
    DECLARE @OriginalAmount DECIMAL(16, 2);
    DECLARE @DiscountAmount DECIMAL(16, 2);
    DECLARE @NetCaseAmount DECIMAL(16, 2);
    DECLARE @MedicalTypeId INT;
    DECLARE @NonCoveredAmount DECIMAL(16, 2);
    DECLARE @NonCoveredReasonId INT;
    DECLARE @ReceiptAmount DECIMAL(16, 2);
    DECLARE @BodyPartId INT;
    DECLARE @CaseItemReceiveRoundId UNIQUEIDENTIFIER;

    SET @CaseItemReceiveRoundId = NEWID();

    DECLARE @ReceiveRoundNo INT;

    SELECT @ReceiveRoundNo = ISNULL(MAX(ReceiveRoundNo), 0) + 1
    FROM [process].[CaseItemReceiveRound]
    WHERE CaseId = @CaseId;

    SELECT
        @InputToStandardMappingId = [InputToStandardMappingId],
        @StandardMedicalExpenseId = [StandardMedicalExpenseId],
        @StandardMedicalExpenseBenefitId = [StandardMedicalExpenseBenefitId],
        @Quantity = [Quantity],
        @PerUnit = [PerUnit],
        @OriginalAmount = [OriginalAmount] + @NetPaidAmount,
        @DiscountAmount = [DiscountAmount],
        @NetCaseAmount = [NetCaseAmount] + @NetPaidAmount,
        @MedicalTypeId = [MedicalTypeId],
        @NonCoveredAmount = [NonCoveredAmount],
        @NonCoveredReasonId = [NonCoveredReasonId],
        @ReceiptAmount = [ReceiptAmount],
        @BodyPartId = [BodyPartId],
        @CaseItemReceiveRoundId = [CaseItemReceiveRoundId]
    FROM [CoreClaim].[core].[CaseItem]
    WHERE [CaseId] = @CaseId;


/* Validate Data */
	--IF @CountValidate IS NULL OR @CountValidate = 0
	--BEGIN
	--	SET @IsResult = 0
 --       SET @Msg = CONCAT(N'ไม่พบข้อมูล',@CaseId)
	--	GOTO RESULT;
	--END;

BEGIN TRY
	BEGIN TRANSACTION

    UPDATE m
     SET m.CaseAmount = m.CaseAmount + @NetPaidAmount
        ,m.LatestApprovedAmount = m.LatestApprovedAmount + @NetPaidAmount
        ,m.UpdatedByUserId = @UserId
    FROM [core].[case] m
    WHERE m.CaseId = @CaseId

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
               ,@D2   

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
        @CaseItemId,
        @CaseId,
        @InputToStandardMappingId,
        @StandardMedicalExpenseId,
        @StandardMedicalExpenseBenefitId,
        @Quantity,
        @PerUnit,
        @OriginalAmount,
        @DiscountAmount,
        @NetCaseAmount,
        @MedicalTypeId,
        @NonCoveredAmount,
        @NonCoveredReasonId,
        @ReceiptAmount,
        @BodyPartId,
        @Remark,
        1,
        @UserId,
        @D2,
        @UserId,
        @D2,
        @CaseItemReceiveRoundId;

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
            ,@ClaimId CalimId;

END
GO
