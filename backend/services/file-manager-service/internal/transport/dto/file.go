package dto

type CreateUploadRequestRequest struct {
	OriginalName string  `json:"originalName"`
	ContentType  string  `json:"contentType"`
	SizeBytes    int64   `json:"sizeBytes"`
	Purpose      string  `json:"purpose"`
	Visibility   string  `json:"visibility"`
	OwnerType    *string `json:"ownerType,omitempty"`
	OwnerID      *string `json:"ownerId,omitempty"`
}

type CreateUploadRequestResponse struct {
	FileID    string           `json:"fileId"`
	ObjectKey string           `json:"objectKey"`
	Status    string           `json:"status"`
	Upload    UploadDescriptor `json:"upload"`
}

type UploadDescriptor struct {
	Method    string            `json:"method"`
	URL       string            `json:"url"`
	Headers   map[string]string `json:"headers"`
	ExpiresAt string            `json:"expiresAt"`
}

type CompleteUploadResponse struct {
	FileID              string `json:"fileId"`
	Status              string `json:"status"`
	DetectedContentType string `json:"detectedContentType"`
	SizeBytes           int64  `json:"sizeBytes"`
}

type FileResponse struct {
	ID                  string  `json:"id"`
	Provider            string  `json:"provider"`
	Bucket              string  `json:"bucket"`
	ObjectKey           string  `json:"objectKey"`
	OriginalName        string  `json:"originalName"`
	StoredName          string  `json:"storedName"`
	Extension           *string `json:"extension,omitempty"`
	ContentType         string  `json:"contentType"`
	DetectedContentType *string `json:"detectedContentType,omitempty"`
	SizeBytes           int64   `json:"sizeBytes"`
	ChecksumSHA256      *string `json:"checksumSha256,omitempty"`
	Visibility          string  `json:"visibility"`
	Purpose             string  `json:"purpose"`
	Status              string  `json:"status"`
	OwnerType           *string `json:"ownerType,omitempty"`
	OwnerID             *string `json:"ownerId,omitempty"`
	UploadedByUserID    *string `json:"uploadedByUserId,omitempty"`
	UploadExpiresAt     *string `json:"uploadExpiresAt,omitempty"`
	IsDeleted           bool    `json:"isDeleted"`
	DeletedAt           *string `json:"deletedAt,omitempty"`
	CreatedAt           string  `json:"createdAt"`
	UpdatedAt           string  `json:"updatedAt"`
}

type CreateDownloadURLResponse struct {
	URL       string `json:"url"`
	ExpiresAt string `json:"expiresAt"`
}
