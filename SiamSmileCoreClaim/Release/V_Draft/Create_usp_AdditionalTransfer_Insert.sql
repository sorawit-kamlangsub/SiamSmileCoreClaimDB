USE [CoreClaim]
GO

/****** Object:  StoredProcedure [finance].[usp_AdditionalTransfer_Insert]    Script Date: 9/3/2026 4:20:41 PM ******/
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
CREATE PROCEDURE [finance].[usp_AdditionalTransfer_Insert]  
/* Add the parameters for the stored procedure here
 comment if not receive parameter*/
			@AdjustmentReasonId INT
            ,@TotalNetPaidAmount DECIMAL(16,2)
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
    DECLARE @CaseAdjustmentId UNIQUEIDENTIFIER;
    DECLARE @CasePayable UNIQUEIDENTIFIER;

    DECLARE
         @ToBankId             INT 
         ,@ToBankName           VARCHAR(50)
         ,@ToBankAccountNo      VARCHAR(50)
         ,@CountValidate        INT ;

    SELECT 
    @ToBankId            = payable.ToBankId
    ,@ToBankName         = payable.ToBankName
    ,@ToBankAccountNo    = payable.ToBankAccountNo
    FROM [process].CasePayable payable
    WHERE payable.CaseId = @CaseId;

    SELECT DISTINCT
    payable.PayableCategoryId
    ,payable.PayeeTypeId
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

    SET @CaseAdjustmentId = NEWID();
    SET @CasePayable = NEWID();
    SELECT @CountValidate = COUNT(CaseId) FROM #Tmp

/* Validate Data */
	IF @CountValidate IS NULL OR @CountValidate = 0
	BEGIN
		SET @IsResult = 0
        SET @Msg = N'ไม่พบข้อมูล'
        SET @CasePayable = NULL
		GOTO RESULT;
	END;

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
               ,[DecisionResonId]
               ,[DecisionRemark]
               ,[Remark]
               ,[IsActive]
               ,[CreatedByUserId]
               ,[CreatedDate]
               ,[UpdatedByUserId]
               ,[UpdatedDate])  
    SELECT 
          NEWID()                                           [CaseAdjudicationId]
         ,@CaseId                                           [CaseId]
         ,t.[VersionNo] + 1                                 [VersionNo]
         ,t.[DecisionId]
         ,t.[DecisionDate]
         ,t.[ApprovedAdmissionDate]
         ,t.[ApprovedAdmissionTime]
         ,t.[ApprovedDischargeDate]
         ,t.[ApprovedDischargeTime]

         ,CASE 
              WHEN t.[CoveredAmount] > 0 
                  THEN t.[CoveredAmount] + @TotalNetPaidAmount
              ELSE t.[CoveredAmount]
          END                                                [CoveredAmount]

         ,CASE 
              WHEN t.[NonCoveredAmount] > 0 
                  THEN t.[NonCoveredAmount] + @TotalNetPaidAmount
              ELSE t.[NonCoveredAmount]
          END                                                [NonCoveredAmount]

         ,CASE 
              WHEN t.[CompensateAmount] > 0 
                  THEN t.[CompensateAmount] + @TotalNetPaidAmount
              ELSE t.[CompensateAmount]
          END                                                [CompensateAmount]

         ,CASE 
              WHEN t.[ApprovedMedicalAmount] > 0 
                  THEN t.[ApprovedMedicalAmount] + @TotalNetPaidAmount
              ELSE t.[ApprovedMedicalAmount]
          END                                                [ApprovedMedicalAmount]

         ,CASE 
              WHEN t.[ApprovedCompensateAmount] > 0 
                  THEN t.[ApprovedCompensateAmount] + @TotalNetPaidAmount
              ELSE t.[ApprovedCompensateAmount]
          END                                                [ApprovedCompensateAmount]

         ,CASE 
              WHEN t.[PatientPayAmount] > 0 
                  THEN t.[PatientPayAmount] + @TotalNetPaidAmount
              ELSE t.[PatientPayAmount]
          END                                                [PatientPayAmount]

         ,t.[IsExgratia]

         ,CASE 
              WHEN t.[ExgratiaAmount] > 0 
                  THEN t.[ExgratiaAmount] + @TotalNetPaidAmount
              ELSE t.[ExgratiaAmount]
          END                                                [ExgratiaAmount]

         ,CASE 
              WHEN t.[DeductibleAmount] > 0 
                  THEN t.[DeductibleAmount] + @TotalNetPaidAmount
              ELSE t.[DeductibleAmount]
          END                                                [DeductibleAmount]

         ,CASE 
              WHEN t.[CoPayAmount] > 0 
                  THEN t.[CoPayAmount] + @TotalNetPaidAmount
              ELSE t.[CoPayAmount]
          END                                                [CoPayAmount]

         ,CASE 
              WHEN t.[CoInsuranceAmount] > 0 
                  THEN t.[CoInsuranceAmount] + @TotalNetPaidAmount
              ELSE t.[CoInsuranceAmount]
          END                                                [CoInsuranceAmount]

         ,t.[RejectReasonId]
         ,t.[RejectDate]
         ,t.[IsLatest]
         ,t.[ApprovedIPDDayCount]
         ,t.[ApprovedICUDayCount]
         ,t.[DecisionResonId]
         ,t.[DecisionRemark]
         ,t.[Remark]
         ,1                                                 [IsActive]
         ,@UserId                                           [CreatedByUserId]
         ,@D2                                               [CreatedDate]
         ,@UserId                                           [UpdatedByUserId]
         ,@D2                                               [UpdatedDate]
    FROM #Tmp t;
    
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
        ,CaseAdjudicationId    CaseAdjudicationId
        ,@D2                    AdjustmentDate
        ,N'ผู้ให้บริ '              AdjustmentReason
        ,@TotalNetPaidAmount    AdjustmentAmount
        ,1                      IsActive
        ,@UserId                CreatedByUserId
        ,@D2                    CreatedDate
        ,@UserId                UpdatedByUserId
        ,@D2                    UpdatedDate
    FROM #Tmp

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
               ,[ToBankId]
               ,[ToBankName]
               ,[ToBankAccountNo]
               ,[IsActive]
               ,[CreatedByUserId]
               ,[CreatedDate]
               ,[UpdatedByUserId]
               ,[UpdatedDate])
    SELECT
     @CasePayable           [CasePayableId]
     ,@CaseId               CaseId
     ,CaseAdjudicationId   CaseAdjudicationId
     ,@CaseAdjustmentId     [CaseAdjustmentId]
     ,PayableCategoryId    PayableCategoryId
     ,2                     [PayableStatusId]
     ,@TotalNetPaidAmount   [PayableAmount]
     ,0                     [TotalPaidAmount]
     ,@TotalNetPaidAmount   [OutstandingAmount]
     ,PayeeTypeId          PayeeTypeId
     ,@ToBankId             ToBankId
     ,@ToBankName           ToBankName
     ,@ToBankAccountNo      ToBankAccountNo
     ,1                     [IsActive]
     ,@UserId               [CreatedByUserId]
     ,@D2                   [CreatedDate]
     ,@UserId               [UpdatedByUserId]
     ,@D2                   [UpdatedDate]
    FROM #Tmp

    INSERT INTO [transaction].[TransactionLog]
               ([TransactionLogId]
               ,[ClaimId]
               ,[CaseId]
               ,[TransactionLogTypeId]
               ,[ReferenceId]
               ,[IsActive]
               ,[Remark]
               ,[CreatedByUserId]
               ,[CreatedDate]
               ,[UpdatedByUserId]
               ,[UpdatedDate])
    SELECT
     NEWID()    [TransactionLogId]
     ,ClaimId
     ,@CaseId   [CaseId]
     ,10        [TransactionLogTypeId]
     ,NULL      [ReferenceId]
     ,1         [IsActive]
     ,NULL      [Remark]
     ,@UserId   [CreatedByUserId]
     ,@D2       [CreatedDate]
     ,@UserId   [UpdatedByUserId]
     ,@D2       [UpdatedDate]
    FROM #Tmp

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

/*Drop TempTable
Comment below if not use TempTable*/
	IF OBJECT_ID('tempdb..#Tmp') IS NOT NULL  DROP TABLE #Tmp;


/*Return Result 
comment this part if no return result */
	IF @IsResult = 1 BEGIN	SET @Result = 'Success' END	
	ELSE BEGIN				SET @Result = 'Failure' END;	

    SELECT @IsResult IsResult
		    ,@Result Result
		    ,@Msg	 Msg
            ,@CasePayable CasePayableId;

END
GO


