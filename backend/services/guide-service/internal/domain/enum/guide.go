package enum

type GuideType string

const (
	GuideTypeIndependent   GuideType = "INDEPENDENT"
	GuideTypeOperatorGuide GuideType = "OPERATOR_GUIDE"
	GuideTypeLocalExpert   GuideType = "LOCAL_EXPERT"
)

func (t GuideType) IsValid() bool {
	switch t {
	case GuideTypeIndependent, GuideTypeOperatorGuide, GuideTypeLocalExpert:
		return true
	default:
		return false
	}
}

type GuideStatus string

const (
	GuideStatusDraft         GuideStatus = "DRAFT"
	GuideStatusPendingReview GuideStatus = "PENDING_REVIEW"
	GuideStatusActive        GuideStatus = "ACTIVE"
	GuideStatusSuspended     GuideStatus = "SUSPENDED"
	GuideStatusRejected      GuideStatus = "REJECTED"
)

func (s GuideStatus) IsValid() bool {
	switch s {
	case GuideStatusDraft, GuideStatusPendingReview, GuideStatusActive, GuideStatusSuspended, GuideStatusRejected:
		return true
	default:
		return false
	}
}

type VerificationRequestStatus string

const (
	VerificationRequestStatusDraft       VerificationRequestStatus = "DRAFT"
	VerificationRequestStatusSubmitted   VerificationRequestStatus = "SUBMITTED"
	VerificationRequestStatusUnderReview VerificationRequestStatus = "UNDER_REVIEW"
	VerificationRequestStatusApproved    VerificationRequestStatus = "APPROVED"
	VerificationRequestStatusRejected    VerificationRequestStatus = "REJECTED"
)

func (s VerificationRequestStatus) IsValid() bool {
	switch s {
	case VerificationRequestStatusDraft,
		VerificationRequestStatusSubmitted,
		VerificationRequestStatusUnderReview,
		VerificationRequestStatusApproved,
		VerificationRequestStatusRejected:
		return true
	default:
		return false
	}
}

type EmploymentType string

const (
	EmploymentTypeEmployee   EmploymentType = "EMPLOYEE"
	EmploymentTypeContractor EmploymentType = "CONTRACTOR"
	EmploymentTypePartner    EmploymentType = "PARTNER"
)

func (e EmploymentType) IsValid() bool {
	switch e {
	case EmploymentTypeEmployee, EmploymentTypeContractor, EmploymentTypePartner:
		return true
	default:
		return false
	}
}
