USE [CoreClaim]
GO

/****** Object:  StoredProcedure [finance].[usp_CasePayable_Insert]    Script Date: 9/23/2026 10:28:59 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Sorawit kamlangsub
-- Create date: 2026-09-23
-- Description:	For Insert CasePayable
-- =============================================
ALTER PROCEDURE [finance].[usp_CasePayable_Insert]
	-- Add the parameters for the stored procedure here
	 @CaseId UNIQUEIDENTIFIER 
     ,@CaseAdjudicationId UNIQUEIDENTIFIER
	 ,@TotalPaidAmount DECIMAL(18,2)
     ,@UserId INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    /*Default Declare*/
    DECLARE @D2             DATETIME2(7)    
	    ,@IsResult	        BIT			    
	    ,@Result		    VARCHAR(100)    
	    ,@Msg		        NVARCHAR(500)   
        ,@CountValidate     INT             
        ,@ToBankId          INT             
        ,@ToBankName        VARCHAR(50)     
        ,@ToBankAccountName VARCHAR(200)    
        ,@ToBankAccountNo   VARCHAR(50)  
        ,@PhoneNumber       VARCHAR(50)
        ,@CasePayableId     UNIQUEIDENTIFIER;

    SET @Msg = '';
    SET @Result = '';
    SET @IsResult = 1;
    SET @D2 = GETDATE();
    SET @CasePayableId = NEWID();

    -- DECLARE
    DECLARE @MappingPayeeType TABLE (
        PayeeTypeId INT,
        ClaimSourceId INT
    );
    DECLARE @MappingCategory TABLE (
        PayableCategoryId INT,
        CoverageTypeId INT
    );

    IF @IsResult = 1
    BEGIN
        
    -- Set Data

    INSERT INTO @MappingPayeeType (PayeeTypeId, ClaimSourceId)
    VALUES
        (1, 1), -- N/A -> n/a
        (2, 2), -- ClaimAgent -> Customer
        (3, 3), -- SmileConnect -> Hospital
        (4, 4); -- IClaim -> Beneficiary
    INSERT INTO @MappingCategory (PayableCategoryId, CoverageTypeId)
    VALUES
        (1, 1), -- N/A -> n/a
        (2, 2), -- Medical -> Medical
        (3, 3), -- Compensate -> Compensate
        (4, NULL), -- ExGratia -> 
        (5, 4), -- DisabilityBenefit -> Disability
        (6, 5); -- DeathBenefit -> DeathCase        

        SELECT 
        @ToBankId            = bfc.BankId
        ,@ToBankName         = org.OrganizeName
        ,@ToBankAccountNo    = bfc.BankAccountNo
        ,@ToBankAccountName  = bfc.BankAccountName
        ,@PhoneNumber        = bfc.PhoneNo
        FROM agent.Beneficiary bfc
        LEFT JOIN 
        (
            SELECT
             OrganizeId
             ,OrganizeName
            FROM ext.Organize 
            WHERE IsActive = 1
            AND OrganizeTypeId = 5
        ) org
            ON bfc.BankId = org.OrganizeId
        WHERE bfc.CaseId = @CaseId;
        
        SELECT
         cc.CaseId
         ,adju.CaseAdjudicationId
         ,pct.PayableCategoryId
         ,pyt.PayeeTypeId
        INTO #Tmp
        FROM core.[Case] cc
        INNER JOIN core.Claim cl
            ON cc.ClaimId = cl.ClaimId
        INNER JOIN agent.Beneficiary bfc
            ON cc.CaseId = bfc.CaseId
        INNER JOIN process.CaseAdjudication adju
            ON cc.CaseId = adju.CaseId
        LEFT JOIN @MappingCategory pct
            ON cc.CoverageTypeId = pct.CoverageTypeId
        LEFT JOIN @MappingPayeeType pyt
            ON cl.ClaimSourceId = pyt.ClaimSourceId
        WHERE cc.CaseId = @CaseId
        AND adju.CaseAdjudicationId = @CaseAdjudicationId
        
        SELECT @CountValidate = COUNT(CaseId) FROM #Tmp

        IF @CountValidate IS NULL OR @CountValidate = 0
        BEGIN
            SET @IsResult = 0
            SET @Msg = N'ไม่พบข้อมูล'
            SET @CasePayableId = NULL
        END
        ELSE
        BEGIN
            BEGIN TRY
                BEGIN TRANSACTION
                
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
                 @CasePayableId        [CasePayableId]
                 ,CaseId               CaseId
                 ,CaseAdjudicationId   CaseAdjudicationId
                 ,NULL                 [CaseAdjustmentId]
                 ,PayableCategoryId    PayableCategoryId
                 ,2                    [PayableStatusId]
                 ,@TotalPaidAmount     [PayableAmount]
                 ,@TotalPaidAmount     [TotalPaidAmount]
                 ,@TotalPaidAmount     [OutstandingAmount]
                 ,PayeeTypeId          PayeeTypeId
                 ,@ToBankId            ToBankId
                 ,@ToBankName          ToBankName
                 ,@ToBankAccountNo     ToBankAccountNo
                 ,1                    [IsActive]
                 ,@UserId              [CreatedByUserId]
                 ,@D2                  [CreatedDate]
                 ,@UserId              [UpdatedByUserId]
                 ,@D2                  [UpdatedDate]
                FROM #Tmp

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

    SELECT @IsResult IsResult
    , @Result Result
    , @Msg Msg
    , @CasePayableId CasePayableId
    , @PhoneNumber PhoneNumber            
    , @ToBankId ToBankId                  
    , @ToBankName ToBankName              
    , @ToBankAccountName ToBankAccountName
    , @ToBankAccountNo ToBankAccountNo;   
END
GO

