SELECT 
 bd.BillingDetailId
 ,b.BillingHeaderId
 ,bd.CreatedDate						NoticeDate
 ,cc.CaseNo				
 ,cc.CaseId				
 ,bd.ReviewedDate
 ,CONCAT(ps.FirstName,' ',ps.LastName)	ApproveName	
 ,b.BillingAmount				
 ,Org.OrganizeName						InsuredCompanyName
 ,hos.OrganizeName						HospitalName
FROM CoreClaim.billing.BillingDetail bd
	INNER JOIN CoreClaim.billing.BillingHeader b
		ON bd.BillingHeaderId = b.BillingHeaderId
	INNER JOIN CoreClaim.core.[Case] cc
		ON bd.CaseId = cc.CaseId
	INNER JOIN CoreClaim.core.Claim cl
		ON cc.ClaimId = cl.ClaimId
	LEFT JOIN ext.[Policy] po
		ON cl.PolicyCode = po.PolicyCode
	LEFT JOIN ext.Organize org
		ON po.InsuredCompanyId = org.OrganizeId
			AND org.OrganizeTypeId IN (2,6)
	LEFT JOIN ext.Organize hos
		ON cc.HospitalId = hos.OrganizeId
	LEFT JOIN ext.PersonUser [user]
		ON bd.ReviewedByUserId = [user].UserId
	LEFT JOIN ext.Person ps
		ON [user].PersonId = ps.PersonId
WHERE bd.IsActive = 1 
AND b.IsActive = 1
AND cc.IsActive = 1
AND cl.IsActive = 1
AND BillingReviewStatusId = 4
