USE [CoreClaim]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Sorawit Kamlangsub
-- Create date: 2026-11-12
-- Description:	Increase Transfer Additional Insert CaseAdju
-- =============================================
ALTER PROCEDURE [finance].[usp_AdditionalTransferHeader_Insert]
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
    DECLARE
         @ToBankId             INT 
         ,@ToBankName           VARCHAR(50)
         ,@ToBankAccountNo      VARCHAR(50);

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

    DECLARE @ClaimId UNIQUEIDENTIFIER
           ,@VersionNo INT
           ,@DecisionId                  INT
           ,@DecisionDate                DATETIME2(7)
           ,@ApprovedAdmissionDate       DATE
           ,@ApprovedAdmissionTime       TIME(7)
           ,@ApprovedDischargeDate       DATE
           ,@ApprovedDischargeTime       TIME(7)
           ,@CoveredAmount               DECIMAL(18, 2)
           ,@NonCoveredAmount            DECIMAL(18, 2)
           ,@CompensateAmount            DECIMAL(18, 2)
           ,@ApprovedMedicalAmount       DECIMAL(18, 2)
           ,@ApprovedCompensateAmount    DECIMAL(18, 2)
           ,@PatientPayAmount            DECIMAL(18, 2)
           ,@IsExgratia                  BIT
           ,@ExgratiaAmount              DECIMAL(18, 2)
           ,@DeductibleAmount            DECIMAL(18, 2)
           ,@CoPayAmount                 DECIMAL(18, 2)
           ,@CoInsuranceAmount           DECIMAL(18, 2)
           ,@RejectReasonId              INT
           ,@RejectDate                  DATETIME2(7)
           ,@IsLatest                    BIT
           ,@ApprovedIPDDayCount         INT
           ,@ApprovedICUDayCount         INT
           ,@DecisionReasonId            INT
           ,@DecisionRemark              NVARCHAR(MAX);
    

    -- Insert statements for procedure here
    SELECT DISTINCT
      @ClaimId = claim.ClaimId
      ,@VersionNo = adju.VersionNo + 1
      ,@DecisionId               = adju.DecisionId
      ,@DecisionDate             = adju.DecisionDate
      ,@ApprovedAdmissionDate    = adju.ApprovedAdmissionDate
      ,@ApprovedAdmissionTime    = adju.ApprovedAdmissionTime
      ,@ApprovedDischargeDate    = adju.ApprovedDischargeDate
      ,@ApprovedDischargeTime    = adju.ApprovedDischargeTime
      ,@CoveredAmount            = adju.CoveredAmount
      ,@NonCoveredAmount         = adju.NonCoveredAmount
      ,@CompensateAmount         = adju.CompensateAmount
      ,@ApprovedMedicalAmount    = adju.ApprovedMedicalAmount
      ,@ApprovedCompensateAmount = adju.ApprovedCompensateAmount
      ,@PatientPayAmount         = adju.PatientPayAmount
      ,@IsExgratia               = adju.IsExgratia
      ,@ExgratiaAmount           = adju.ExgratiaAmount
      ,@DeductibleAmount         = adju.DeductibleAmount
      ,@CoPayAmount              = adju.CoPayAmount
      ,@CoInsuranceAmount        = adju.CoInsuranceAmount
      ,@RejectReasonId           = adju.RejectReasonId
      ,@RejectDate               = adju.RejectDate
      ,@IsLatest                 = adju.IsLatest
      ,@ApprovedIPDDayCount      = adju.ApprovedIPDDayCount
      ,@ApprovedICUDayCount      = adju.ApprovedICUDayCount
      ,@DecisionReasonId         = adju.DecisionReasonId
      ,@DecisionRemark           = adju.DecisionRemark
      ,@CountValidate            = COUNT(pay.PaymentId) OVER ()
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
    AND adju.IsActive = 1
    AND adju.rwId = 1
    AND [case].CaseId = @CaseId;

/* Validate Data */
	IF @CountValidate IS NULL OR @CountValidate = 0
	BEGIN
		SET @IsResult = 0
        SET @Msg = CONCAT(N'ไม่พบข้อมูล',@CaseId)
		GOTO RESULT;
	END;

BEGIN TRY
	BEGIN TRANSACTION

     UPDATE [process].[CaseAdjudication]
         SET UpdatedByUserId = @UserId
             ,UpdatedDate = @D2
             ,IsLatest = 0
     FROM [process].[CaseAdjudication]
     WHERE CaseId = @CaseId 
     AND IsLatest = 1

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
     SELECT 
            @CaseAdjudicationId                             [CaseAdjudicationId]
            ,@CaseId                                        [CaseId]
            ,@VersionNo                                     [VersionNo]
            ,@DecisionId                                    [DecisionId]
            ,@DecisionDate                                  [DecisionDate]
            ,@ApprovedAdmissionDate                         [ApprovedAdmissionDate]
            ,@ApprovedAdmissionTime                         [ApprovedAdmissionTime]
            ,@ApprovedDischargeDate                         [ApprovedDischargeDate]
            ,@ApprovedDischargeTime                         [ApprovedDischargeDate]
            ,@CoveredAmount                                 [CoveredAmount]
            ,@NonCoveredAmount                              [NonCoveredAmount]
            ,@CompensateAmount                              [CompensateAmount]
            ,@ApprovedMedicalAmount + @TotalNetPaidAmount   [ApprovedMedicalAmount]
            ,@ApprovedCompensateAmount                      [ApprovedCompensateAmount]
            ,@PatientPayAmount                              [PatientPayAmount]
            ,@IsExgratia                                    [IsExgratia]
            ,@ExgratiaAmount                                [ExgratiaAmount]
            ,@DeductibleAmount                              [DeductibleAmount]
            ,@CoPayAmount                                   [CoPayAmount]
            ,@CoInsuranceAmount                             [CoInsuranceAmount]
            ,@RejectReasonId                                [RejectReasonId]
            ,@RejectDate                                    [RejectDate]
            ,1                                              [IsLatest]
            ,@ApprovedICUDayCount                           [ApprovedIPDDayCount]
            ,@ApprovedICUDayCount                           [ApprovedICUDayCount]
            ,@DecisionReasonId                              [DecisionReasonId]
            ,@DecisionRemark                                [DecisionRemark]
            ,N'โอนเพิ่ม'                                       [Remark]   
            ,1                                              [IsActive]
            ,@UserId                                        [CreatedByUserId]
            ,@D2                                            [CreatedDate]
            ,@UserId                                        [UpdatedByUserId]
            ,@D2                                            [UpdatedDate]

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
