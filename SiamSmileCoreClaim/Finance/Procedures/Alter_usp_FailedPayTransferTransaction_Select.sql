USE [CoreClaim]
GO
/****** Object:  StoredProcedure [finance].[usp_FailedPayTransferTransaction_Select]    Script Date: 8/31/2026 1:39:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Sorawit kamlangsub
-- Create date: 2026-08-27 
-- Description:	Moniter ·°È‰¢°“√‚Õπ‡ß‘π
-- =============================================
ALTER PROCEDURE [finance].[usp_FailedPayTransferTransaction_Select] 
--Add the parameters for the stored procedure here
	@IndexStart	INT = NULL
	,@PageSize		INT = NULL
	,@SortField		NVARCHAR(MAX)	= NULL
	,@OrderType		NVARCHAR(MAX)	= NULL
	,@SearchDetail	NVARCHAR(MAX)	= NULL
AS
BEGIN
/*SET NOCOUNT ON added to prevent extra result sets from interfering with SELECT statements.*/
	SET NOCOUNT ON;

	DECLARE @D2		DATETIME2 = GETDATE();
	DECLARE @UserId	INT		= 1;

/*Default Declare for Paging*/
	IF @IndexStart      IS NULL    SET @IndexStart    = 0;
	IF @PageSize        IS NULL    SET @PageSize        = 10;
	IF @SearchDetail    IS NULL    SET @SearchDetail    = ''; 
-----------------------------------

/* TODO Select Query Here*/
	DECLARE @_SearchDetail NVARCHAR(MAX) = @SearchDetail;
	SELECT  
		cl.ClaimNo
		,cc.CaseNo
		,cl.CreatedDate						ClaimCreated
		,pt.ToAccountNo
		,pt.ToBank
		,pt.ToAccountName
		,pt.TotalNetPaidAmount
		,pt.PaymentStatusId 
		,ptt.PayTransferTransactionId
		,ptt.PayListHeaderId
		,pt.PaymentCode
		,pt.PaymentId
		,ps.PaymentStatusNameTH
		,COUNT(ptt.PaymentId) OVER () AS TotalCount
	FROM [finance].Payment pt 
			LEFT JOIN [finance].PaymentItem pit
				ON pt.PaymentId = pit.PaymentId
			LEFT JOIN [process].CasePayable cp 
				ON pit.CasePayableId = cp.CasePayableId
			LEFT JOIN [core].[Case] cc
				ON cp.CaseId = cc.CaseId
			LEFT JOIN [core].[Claim] cl 
				ON cc.ClaimId = cl.ClaimId
			LEFT JOIN [finance].PayTransferTransaction ptt
				ON pt.PaymentId = ptt.PaymentId
			LEFT JOIN [master].PaymentStatus ps 
				ON pt.PaymentStatusId = ps.PaymentStatusId
	WHERE pt.IsActive = 1
		AND ptt.IsActive = 1
		AND pit.IsActive = 1
		AND cp.IsActive = 1
		AND cl.IsActive = 1
		AND pt.PaymentStatusId IN (5)
		AND ptt.TransferStatusId IN (4,6)
		AND ptt.StatusBank NOT IN ('e001','e002','w001')
		AND (
			@_SearchDetail = ''
			OR cl.ClaimNo LIKE CONCAT('%',@_SearchDetail,'%')
		  )


/* Order by and set Paging
comment below part if not return paging or sorting*/
	ORDER BY 
		CASE WHEN @OrderType = 'ASC'    AND @SortField ='CreatedDate'    THEN cl.CreatedDate END ASC
		,CASE WHEN @OrderType = 'DESC'   AND @SortField ='CreatedDate'    THEN cl.CreatedDate END DESC
		,CASE WHEN @OrderType IS NULL    AND @SortField ='CreatedDate'    THEN cl.CreatedDate END DESC

	OFFSET @IndexStart ROWS FETCH NEXT @PageSize ROWS ONLY
END
