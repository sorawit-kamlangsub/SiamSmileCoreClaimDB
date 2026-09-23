-- ================================================
-- Template generated from Template Explorer using:
-- Create Procedure (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the procedure.
-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Sorawit kamlangsub
-- Create date: 2026-09-23
-- Description:	For Insert CasePayable
-- =============================================
CREATE PROCEDURE finance.usp_CasePayable_Insert
	-- Add the parameters for the stored procedure here
	 @CaseId UNIQUEIDENTIFIER, 
	@TotalPaidAmount DECIMAL(16,2)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    /*Default Declare*/
    DECLARE @D2             DATETIME2(7)    ;
	DECLARE @IsResult	    BIT			    ;
	DECLARE @Result		    VARCHAR(100)    ;
	DECLARE @Msg		    NVARCHAR(500)   ;
    DECLARE @CasePayable    UNIQUEIDENTIFIER;
    DECLARE @CountValidate  INT             ;

    SET @Msg = '';
    SET @Result = '';
    SET @IsResult = 1;
    SET @D2 = GETDATE();
    SET @CasePayable = NEWID();

    IF @IsResult = 1
    BEGIN
        IF @CountValidate IS NULL OR @CountValidate = 0
        BEGIN
            SET @IsResult = 0
            SET @Msg = N'ไม่พบข้อมูล'
            SET @CasePayable = NULL
        END
        ELSE
        BEGIN
            BEGIN TRY
                BEGIN TRANSACTION
                


                SET @IsResult = 1;
                SET @Msg = N'บันทึก สำเร็จ';
                COMMIT TRANSACTION
            END TRY
            BEGIN CATCH
                SET @IsResult = 0;
                SET @Msg = ERROR_MESSAGE();
                IF @@TRANCOUNT > 0 ROLLBACK;
            END CATCH
        END
    END
    ELSE
    BEGIN
        SET @Msg = N'ปิดใช้งาน'
    END

    IF OBJECT_ID('tempdb..#Tmp') IS NOT NULL DROP TABLE #Tmp;

    IF @IsResult = 1 SET @Result = 'Success'
    ELSE SET @Result = 'Failure';

    SELECT @IsResult IsResult, @Result Result, @Msg Msg, @CasePayable CasePayableId;
END
GO
