USE [CoreClaim]
GO

    SELECT 
     [case].CaseId
     ,[case].CaseNo
     ,claim.ClaimNo
     ,claim.CreatedDate
     ,claim.CustomerName
     
     ,payItem.NetPaidAmount
     --,adjust.AdjustmentAmount
    FROM core.[Case] [case]
    INNER JOIN core.Claim claim
        ON [case].ClaimId = claim.ClaimId
    INNER JOIN [process].CasePayable payable
        ON [case].CaseId = payable.CaseId
    INNER JOIN finance.PaymentItem payItem
        ON payable.CasePayableId = payItem.CasePayableId
    INNER JOIN finance.Payment pay
        ON payItem.PaymentId = pay.PaymentId
    WHERE pay.PaymentStatusId = 3