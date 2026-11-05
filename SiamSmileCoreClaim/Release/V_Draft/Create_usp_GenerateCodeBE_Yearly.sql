USE [CoreClaim]
GO

/****** Object:  StoredProcedure [process].[usp_GenerateCodeBE_Yearly]    Script Date: 11/5/2026 9:58:28 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Nattavut Jaikaew
-- Create date: 20260107 1133
-- Description:	
-- =============================================
CREATE PROCEDURE [process].[usp_GenerateCodeBE_Yearly]
			@TransactionCode	VARCHAR(10)
			,@RunningLenght		INT
			,@Result			VARCHAR(30) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

--DECLARE @TransactionCode	VARCHAR(10)
--DECLARE @RunningLenght		INT
--DECLARE @Result				VARCHAR(30)

DECLARE @TrccId		INT;
DECLARE @Running	INT;

/**/
DECLARE @D			DATE = GETDATE();
DECLARE @MonthText	VARCHAR(2);
SET @MonthText = '00';
DECLARE @YearText	VARCHAR(2) = RIGHT(YEAR(@D) +543 ,2);

/*set default*/
IF ISNULL(@TransactionCode,'') = '' SET @TransactionCode = 'xxx';
IF @RunningLenght IS NULL SET @RunningLenght = 6;


--/*temp table*/
DECLARE @Tmp TABLE(nextId INT);

SELECT @TrccId = Id
FROM dbo.TransactionCodeControl
WHERE TransactionCode = @TransactionCode
AND [Year] = @YearText
AND [Month] = @MonthText;

IF @TrccId IS NULL
	BEGIN
        INSERT INTO dbo.TransactionCodeControl WITH (TABLOCKX)
			(
				TransactionCode
			   ,[Year]
			   ,[Month]
			   ,Running
			)
		OUTPUT Inserted.Running INTO @Tmp (nextId)
		SELECT	@TransactionCode
				,@YearText
				,@MonthText
				,1;
	END
ELSE
	BEGIN

        UPDATE m WITH (TABLOCKX)
		SET    m.Running = m.Running + 1
        OUTPUT Inserted.Running INTO @Tmp (nextId)
        FROM   dbo.TransactionCodeControl m
        WHERE  m.Id = @TrccId;   
	END

	SELECT @Running = nextId
	FROM @Tmp;

	SET @Result = CONCAT(@TransactionCode,@YearText,@MonthText, dbo.func_ConvertIntToString(@Running, @RunningLenght));

-- SELECT @Result Result

END
GO

