package dto

type ParticipantResponse struct {
	ID                    string  `json:"id"`
	ActivityID            string  `json:"activityId"`
	UserID                string  `json:"userId"`
	Status                string  `json:"status"`
	JoinedAt              string  `json:"joinedAt"`
	ApprovedAt            *string `json:"approvedAt,omitempty"`
	WaitlistedAt          *string `json:"waitlistedAt,omitempty"`
	PaymentDueAt          *string `json:"paymentDueAt,omitempty"`
	PaidAt                *string `json:"paidAt,omitempty"`
	AttendanceConfirmedAt *string `json:"attendanceConfirmedAt,omitempty"`
	CheckedInAt           *string `json:"checkedInAt,omitempty"`
	AttendedAt            *string `json:"attendedAt,omitempty"`
	CancelledAt           *string `json:"cancelledAt,omitempty"`
	CancelledByUserID     *string `json:"cancelledByUserId,omitempty"`
	CancelReason          *string `json:"cancelReason,omitempty"`
	CreatedAt             string  `json:"createdAt"`
	UpdatedAt             string  `json:"updatedAt"`
}
