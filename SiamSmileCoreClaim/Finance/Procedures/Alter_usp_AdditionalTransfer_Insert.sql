USE [CoreClaim]
GO

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
-- Description:	การโอนเพิ่ม Wrapper
-- =============================================
ALTER PROCEDURE [finance].[usp_AdditionalTransfer_Insert]  
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


-----------------------------------

/* TODO Select Query Here*/
/* Setup Data*/
DECLARE @Result TABLE
(
    IsResult BIT,
    Result VARCHAR(100),
    Msg NVARCHAR(500),
    CasePayableId UNIQUEIDENTIFIER
);

INSERT INTO @Result
(
    IsResult,
    Result,
    Msg,
    CasePayableId
)
EXEC [finance].[usp_AdditionalTransfer_Core_Insert]
     @AdjustmentReasonId,
     @TotalNetPaidAmount,
     @CaseId,
     @UserId,
     @Remark;

SELECT
    IsResult,
    Result,
    Msg,
    CasePayableId
FROM @Result;

END
