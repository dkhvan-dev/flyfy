package dto

type BindFileRequest struct {
	OwnerType string `json:"ownerType"`
	OwnerID   string `json:"ownerId"`
	Purpose   string `json:"purpose"`
	IsPrimary bool   `json:"isPrimary"`
}

type FileBindingResponse struct {
	ID              string  `json:"id"`
	FileID          string  `json:"fileId"`
	OwnerType       string  `json:"ownerType"`
	OwnerID         string  `json:"ownerId"`
	Purpose         string  `json:"purpose"`
	IsPrimary       bool    `json:"isPrimary"`
	IsDeleted       bool    `json:"isDeleted"`
	DeletedAt       *string `json:"deletedAt,omitempty"`
	CreatedByUserID *string `json:"createdByUserId,omitempty"`
	CreatedAt       string  `json:"createdAt"`
	UpdatedAt       string  `json:"updatedAt"`
}
