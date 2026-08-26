USE [CoreClaim]
GO
/****** Object:  StoredProcedure [finance].[usp_InquiryMonitor_Select]    Script Date: 8/24/2026 2:54:05 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Sorawit kamlangsub
-- Create date: 2026-08-21
-- Description:	สำหรับการสอบถามธนาคาร
---- =============================================
CREATE PROCEDURE [finance].[usp_InquiryMonitor_Select]
	-- Add the parameters for the stored procedure here
	@IndexStart		INT = NULL 
	,@PageSize	    INT = NULL 
	,@SortField		NVARCHAR(MAX) = NULL
	,@OrderType		NVARCHAR(MAX) = NULL
	,@SearchDetail  NVARCHAR(MAX) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	----------------------------------------------------------
	IF @IndexStart		IS NULL    SET @IndexStart		= 0;
	IF @PageSize        IS NULL    SET @PageSize        = 10;
	IF @SearchDetail    IS NULL    SET @SearchDetail    = '';
	----------------------------------------------------------

    --DECLARE @SearchDetail NVARCHAR(MAX) = 'CPG690800000037';

    -- Insert statements for procedure here
    DECLARE @_SearchDetail NVARCHAR(MAX) = @SearchDetail;
    SELECT
        p.PaymentId
        ,p.ToAccountNo
        ,p.ToAccountName
        ,p.ToBank
        ,p.TotalNetPaidAmount
        ,p.PaymentCode
        ,cl.CreatedDate
        ,cl.ClaimNo
        ,pt.PayTransferTransactionId
        ,pt.TransferStatusId
        ,ts.TransferStatusName
        ,pt.PayListHeaderId
        ,COUNT(p.PaymentId) OVER()     TotalCount
    FROM finance.Payment p
    LEFT JOIN finance.PaymentItem [pi]
        ON p.PaymentId = [pi].PaymentId
    LEFT JOIN process.CasePayable cp
        ON [pi].CasePayableId = cp.CasePayableId
    LEFT JOIN core.[Case] cc
        ON cp.CaseId = cc.CaseId
    LEFT JOIN core.Claim cl
        ON cc.ClaimId = cl.ClaimId
    LEFT JOIN finance.PayTransferTransaction pt
        ON p.PaymentId = pt.PaymentId
    LEFT JOIN [master].[TransferStatus] ts
        ON pt.TransferStatusId = ts.TransferStatusId
    WHERE p.IsActive = 1
      AND [pi].IsActive = 1
      AND pt.IsActive = 1
      AND pt.StatusBank IN ('e001','e002','w001')
      AND (
        @_SearchDetail = ''
        OR p.PaymentCode LIKE CONCAT('%',@_SearchDetail,'%')
        OR cl.ClaimNo LIKE CONCAT('%',@_SearchDetail,'%')
      )
    ORDER BY p.CreatedDate DESC
    OFFSET @IndexStart ROWS FETCH NEXT @PageSize ROWS ONLY
END
