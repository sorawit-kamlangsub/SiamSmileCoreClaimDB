SELECT
    cc.CaseId,
    cc.CaseAmount,
    cc.CaseNo AS ClaimCase,
    cct.CoverageTypeNameTH AS CoverageType,
    cl.CreatedDate AS CreatedClaimDate,
    cl.CustomerName,
    cl.ClaimNo,
    cc.ClaimId,
    p.PhoneNo
FROM [core].Claim AS cl
INNER JOIN [core].[Case] AS cc
    ON cl.ClaimId = cc.ClaimId
    AND cc.IsActive = 1
INNER JOIN [process].CasePayable AS cp
    ON cc.CaseId = cp.CaseId
    AND cp.IsActive = 1
INNER JOIN [finance].PaymentItem AS pit
    ON cp.CasePayableId = pit.CasePayableId
    AND pit.IsActive = 1
INNER JOIN [finance].Payment AS p
    ON pit.PaymentId = p.PaymentId
LEFT JOIN [master].CoverageType AS cct
    ON cc.CoverageTypeId = cct.CoverageTypeId
WHERE cl.IsActive = 1
and cc.CoverageTypeId = 3
  AND p.PaymentStatusId = 3;