USE [CoreClaim]
GO

    SELECT 
     claim.ClaimNo
     ,[case].CaseNo
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
    --INNER JOIN [process].CaseAdjustment adjust
    --    ON payable.CaseAdjustmentId = adjust.CaseAdjustmentId
    WHERE pay.PaymentStatusId = 3
    --AND adjust.AdjustmentTypeId = 2