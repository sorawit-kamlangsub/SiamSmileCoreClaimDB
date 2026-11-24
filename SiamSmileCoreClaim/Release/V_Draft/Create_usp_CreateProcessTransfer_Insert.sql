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
-- Description:	Insert Process 
-- =============================================
ALTER PROCEDURE [finance].[usp_CreateProcessTransfer_Insert]
/* Add the parameters for the stored procedure here
 comment if not receive parameter*/
			@AdjustmentReasonId INT
            ,@AdjustmentTypeId INT
            ,@CaseItemId UNIQUEIDENTIFIER
            ,@CaseRefundId UNIQUEIDENTIFIER
            ,@NetPaidAmount DECIMAL(16,2)
            ,@CaseId UNIQUEIDENTIFIER
            ,@UserId INT
            ,@Remark NVARCHAR(500)
            ,@RoundNo INT
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
    DECLARE @CaseAdjustmentId UNIQUEIDENTIFIER; 
    DECLARE @CaseAdjudicationId UNIQUEIDENTIFIER
    DECLARE @StandardMedicalExpenseId INT;

    SET @CaseAdjustmentId = NEWID();
    SET @CaseAdjudicationId = NEWID();

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

    IF @RoundNo = 1
    BEGIN
        SELECT 
          @ClaimId = [case].ClaimId
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
        FROM process.CaseAdjudication adju
        INNER JOIN core.[Case] [case]
            ON adju.CaseId = [case].CaseId
        WHERE adju.CaseId = @CaseId
    END;

    SELECT 
     @StandardMedicalExpenseId = StandardMedicalExpenseId
    FROM [core].[CaseItem]
    WHERE CaseItemId = @CaseItemId

BEGIN TRY
	BEGIN TRANSACTION

    IF @RoundNo = 1
    BEGIN
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
            ,@ApprovedMedicalAmount                         [ApprovedMedicalAmount]
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
            ,NULL                                           [Remark]   
            ,1                                              [IsActive]
            ,@UserId                                        [CreatedByUserId]
            ,@D2                                            [CreatedDate]
            ,@UserId                                        [UpdatedByUserId]
            ,@D2                                            [UpdatedDate]
    END;

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
    
    IF @NetPaidAmount IS NOT NULL OR @NetPaidAmount <> 0
    BEGIN
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
            ,@AdjustmentTypeId      AdjustmentTypeId
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
    END;

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
            ,@ClaimId CalimId
            ,@CaseAdjustmentId CaseAdjustmentId
            ,@CaseAdjudicationId CaseAdjudicationId;

END
GO

