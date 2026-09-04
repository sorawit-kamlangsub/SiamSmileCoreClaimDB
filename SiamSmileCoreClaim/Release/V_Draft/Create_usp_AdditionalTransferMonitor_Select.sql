USE [CoreClaim]
GO

/****** Object:  StoredProcedure [finance].[usp_AdditionalTransferMonitor_Select]    Script Date: 9/4/2026 3:53:11 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Sorawit kamlangsub
-- Create date: 2026-09-03
/* 
   Update date: 
*/
-- Description:	Monitor รายการโอนเพิ่ม
-- =============================================
CREATE PROCEDURE [finance].[usp_AdditionalTransferMonitor_Select] 
/* Add the parameters for the stored procedure here
 comment if not receive parameter*/
	@BranchId INT = NULL
	,@PaymentStatusId INT = NULL
	,@IndexStart	INT = NULL
	,@PageSize		INT = NULL
	,@SortField		NVARCHAR(MAX)	= NULL
	,@OrderType		NVARCHAR(MAX)	= NULL
	,@SearchDetail	NVARCHAR(MAX)	= NULL
AS
BEGIN
/*SET NOCOUNT ON added to prevent extra result sets from interfering with SELECT statements.*/
	SET NOCOUNT ON;

/*Default Declare for Paging*/
	IF @IndexStart      IS NULL    SET @IndexStart    = 0;
	IF @PageSize        IS NULL    SET @PageSize        = 10;
	IF @SearchDetail    IS NULL    SET @SearchDetail    = ''; 
-----------------------------------

	SELECT
	 cc.CaseId 
	 ,cl.ClaimId
	 ,cl.ClaimNo
	 ,cc.CaseNo 
	 ,cl.CreatedDate
	 ,cl.CustomerName
	 ,NULL						[BranchName]
	 ,pms.PaymentStatusNameTH
	 ,NULL						Remark
	 ,rs.TotalNetPaidAmount
	 ,pm.TotalNetPaidAmount		AddPayAmount
	 ,COUNT(cc.CaseId) OVER()   TotalCount
	 ,pm.PaymentStatusId
	FROM finance.Payment pm
	INNER JOIN finance.PaymentItem pmi
		ON pm.PaymentId = pmi.PaymentId
	INNER JOIN [process].[CasePayable] cpa
		ON pmi.CasePayableId = cpa.CasePayableId
	INNER JOIN core.[Case] cc
		ON cpa.CaseId = cc.CaseId
	INNER JOIN core.Claim cl 
		ON cc.ClaimId = cl.ClaimId
	INNER JOIN [process].CaseAdjustment ajs
		ON cpa.CaseAdjustmentId = ajs.CaseAdjustmentId
	LEFT JOIN 
	(
		SELECT 
			PaymentStatusId
			,PaymentStatusNameTH
			,IsActive
		FROM [master].PaymentStatus 
		WHERE IsActive = 1
	) pms
		ON pm.PaymentStatusId = pms.PaymentStatusId
	LEFT JOIN 
	(
		SELECT 
		 SUM(pmi.NetPaidAmount) TotalNetPaidAmount
		 ,cpa.CaseId
		FROM finance.PaymentItem pmi
		INNER JOIN finance.Payment pm
			ON pmi.PaymentId = pm.PaymentId
		INNER JOIN [process].CasePayable cpa
			ON pmi.CasePayableId = cpa.CasePayableId
		WHERE pmi.IsActive = 1
		AND cpa.IsActive = 1
		AND pm.PaymentStatusId = 3
		GROUP BY cpa.CaseId
	) rs
		ON cc.CaseId = rs.CaseId
	WHERE pm.IsActive = 1
	AND pmi.IsActive = 1
	AND cpa.IsActive = 1
	AND cc.IsActive = 1
	AND cl.IsActive = 1
	AND pm.PaymentTypeId = 4
	AND pm.PaymentStatusId IN (2,5)
	AND (
	  @BranchId IS NULL 
	  OR @PaymentStatusId IS NULL
	  OR pm.PaymentStatusId = @PaymentStatusId
	)

	ORDER BY 
		CASE WHEN @OrderType IS NULL    AND @SortField IS NULL        THEN cl.CreatedDate END DESC
		--,CASE WHEN @OrderType = 'ASC'    AND @SortField ='CreatedDate'    THEN <ColumnName> END ASC
		--,CASE WHEN @OrderType = 'DESC'    AND @SortField ='CreatedDate'    THEN <ColumnName> END DESC

OFFSET @IndexStart ROWS FETCH NEXT @PageSize ROWS ONLY

END
GO

