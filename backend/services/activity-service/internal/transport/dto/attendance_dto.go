package dto

type AttendanceQRResponse struct {
	ActivityID string `json:"activityId"`
	Token      string `json:"token"`
	ExpiresAt  string `json:"expiresAt"`
	RefreshAt  string `json:"refreshAt"`
}

type AttendanceSyncRequest struct {
	Items []AttendanceSyncItemRequest `json:"items"`
}

type AttendanceSyncItemRequest struct {
	ScanID          string  `json:"scanId"`
	QRToken         string  `json:"qrToken"`
	InstallationID  string  `json:"installationId"`
	ScannedAtDevice *string `json:"scannedAtDevice,omitempty"`
}

type AttendanceSyncResponse struct {
	Items []AttendanceSyncItemResponse `json:"items"`
}

type AttendanceSyncItemResponse struct {
	ScanID      string  `json:"scanId"`
	ActivityID  *string `json:"activityId,omitempty"`
	Status      string  `json:"status"`
	Code        string  `json:"code"`
	Message     string  `json:"message"`
	CheckedInAt *string `json:"checkedInAt,omitempty"`
	SyncedAt    string  `json:"syncedAt"`
}
