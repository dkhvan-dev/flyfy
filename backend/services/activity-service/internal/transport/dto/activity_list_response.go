package dto

type ActivityListResponse struct {
	Items   []ActivityResponse `json:"items"`
	HasMore bool               `json:"hasMore"`
}
