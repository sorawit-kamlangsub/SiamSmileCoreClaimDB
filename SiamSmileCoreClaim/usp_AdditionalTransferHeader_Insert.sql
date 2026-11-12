USE [CoreClaim]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [finance].[usp_AdditionalTransferHeader_Insert]
	-- Add the parameters for the stored procedure here
	@CaseId UNIQUEIDENTIFIER
	,@CaseAdjudicationId UNIQUEIDENTIFIER
    ,@TotalNetPaidAmount DECIMAL(16,2)
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

    DECLARE @ClaimId UNIQUEIDENTIFIER;

    -- Insert statements for procedure here
    SELECT DISTINCT
     @ClaimId = claim.ClaimId
    FROM core.[Case] [case]
    INNER JOIN core.Claim claim
        ON [case].ClaimId = claim.ClaimId
    INNER JOIN [process].CasePayable payable
        ON [case].CaseId = payable.CaseId
    INNER JOIN finance.PaymentItem payItem
        ON payable.CasePayableId = payItem.CasePayableId
    INNER JOIN finance.Payment pay
        ON payItem.PaymentId = pay.PaymentId
    WHERE claim.IsActive = 1
    AND [case].IsActive = 1
    AND payable.IsActive = 1
    AND payItem.IsActive = 1
    AND pay.IsActive = 1
    AND pay.PaymentStatusId = 3
    AND [case].CaseId = @CaseId;

BEGIN TRY
	BEGIN TRANSACTION

 INSERT INTO [process].[CaseAdjudication]
           ([CaseAdjudicationId]
           ,[CaseId]
           ,[VersionNo]
           ,[DecisionId]
           ,[DecisionDate]
           ,[ApprovedAdmissionDate]
           ,[ApprovedAdmissionTime]
           ,[ApprovedDischargeDate]
           ,[ApprovedDischargeTime]
           ,[CoveredAmount]
           ,[NonCoveredAmount]
           ,[CompensateAmount]
           ,[ApprovedMedicalAmount]
           ,[ApprovedCompensateAmount]
           ,[PatientPayAmount]
           ,[IsExgratia]
           ,[ExgratiaAmount]
           ,[DeductibleAmount]
           ,[CoPayAmount]
           ,[CoInsuranceAmount]
           ,[RejectReasonId]
           ,[RejectDate]
           ,[IsLatest]
           ,[ApprovedIPDDayCount]
           ,[ApprovedICUDayCount]
           ,[DecisionReasonId]
           ,[DecisionRemark]
           ,[Remark]
           ,[IsActive]
           ,[CreatedByUserId]
           ,[CreatedDate]
           ,[UpdatedByUserId]
           ,[UpdatedDate])   

	SET @IsResult	= 1;
	SET @Msg		= N'บันทึก สำเร็จ';

	COMMIT TRANSACTION
END TRY
BEGIN CATCH

	SET @IsResult	= 0;
	SET @Msg		= ERROR_MESSAGE();

	IF @@TRANCOUNT > 0 ROLLBACK;
END CATCH


END
GO
