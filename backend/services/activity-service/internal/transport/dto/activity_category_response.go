package dto

type ActivityCategoryResponse struct {
	Slug   string `json:"slug"`
	Name   string `json:"name"`
	NameRu string `json:"nameRu"`
	NameKk string `json:"nameKk"`
}

type ActivityCategoryListResponse struct {
	Items []ActivityCategoryResponse `json:"items"`
}
